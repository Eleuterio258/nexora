package handlers

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/services"
	"nexora/internal/shared/contracts"
)

func (h *Handler) feeService() *services.FeeService {
	return services.NewFeeService(h.feeRepo, h.treasury, h.financial, h.accounting, h.invoicing)
}

// GerarCobrancasPlano gera cobranças recorrentes a partir de um plano.
func (h *Handler) GerarCobrancasPlano(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	var body struct {
		PeriodoReferencia string `json:"periodo_referencia"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	if body.PeriodoReferencia == "" {
		jsonErr(w, "Periodo de referencia obrigatorio", http.StatusBadRequest)
		return
	}

	count, total, err := h.feeService().GenerateFromPlan(r.Context(), id, u.TenantID, body.PeriodoReferencia, &u.ID)
	if err != nil {
		switch {
		case errors.Is(err, services.ErrFeeNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		case errors.Is(err, services.ErrFeeInvalidData):
			jsonErr(w, err.Error(), http.StatusBadRequest)
		case errors.Is(err, services.ErrFeeAlreadyGenerated):
			jsonErr(w, err.Error(), http.StatusConflict)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}

	jsonOK(w, map[string]any{"cobrancas_geradas": count, "valor_total": total}, http.StatusCreated)
}

// AplicarDescontoCobrancaV2 aplica desconto com verificação de aprovação.
// Se existir um fluxo de aprovação configurado para "gestao-escolar.descontos",
// o desconto é submetido para aprovação em vez de aplicado imediatamente.
func (h *Handler) AplicarDescontoCobrancaV2(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	var body struct {
		Desconto float64 `json:"desconto"`
		Motivo   string  `json:"motivo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}

	// Verificar se desconto requer aprovação (reutiliza módulo Aprovações do ERP)
	if h.approval != nil {
		flow, err := h.approval.NeedsApproval(r.Context(), u.TenantID, "gestao-escolar.descontos", body.Desconto)
		if err == nil && flow != nil {
			// Guardar desconto pendente na cobrança antes de submeter para aprovação
			_, _ = h.db.Exec(r.Context(), `
				UPDATE gestao_escolar.school_fees
				   SET desconto_pendente = $1, desconto_pendente_motivo = $2
				 WHERE id = $3 AND tenant_id = $4`,
				body.Desconto, body.Motivo, id, u.TenantID)

			if reqErr := h.approval.CreateRequest(r.Context(), u.TenantID, flow.ID, id, u.ID, "gestao_escolar.school_fees"); reqErr != nil {
				jsonErr(w, "Erro ao criar pedido de aprovacao", http.StatusInternalServerError)
				return
			}
			jsonOK(w, map[string]any{
				"status":   "pendente_aprovacao",
				"flow":     flow.Nome,
				"niveis":   flow.Niveis,
				"mensagem": "Desconto submetido para aprovacao. Sera aplicado apos aprovacao.",
			}, http.StatusAccepted)
			return
		}
	}

	// Sem fluxo de aprovação — aplicar directamente
	if err := h.feeService().ApplyDiscount(r.Context(), id, u.TenantID, body.Desconto, body.Motivo); err != nil {
		if errors.Is(err, services.ErrFeeInvalidData) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// CancelarCobrancaAluno cancela uma cobrança pendente ou emitida, com motivo obrigatório.
func (h *Handler) CancelarCobrancaAluno(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	var body struct {
		Motivo string `json:"motivo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || strings.TrimSpace(body.Motivo) == "" {
		jsonErr(w, "Motivo de cancelamento é obrigatório", http.StatusBadRequest)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_fees
		   SET status               = 'cancelada',
		       cancelamento_motivo  = $1,
		       cancelado_em         = NOW(),
		       cancelado_por        = $2,
		       updated_at           = NOW()
		 WHERE id = $3 AND tenant_id = $4
		   AND status IN ('pendente', 'emitida')`,
		strings.TrimSpace(body.Motivo), u.ID, id, u.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Cobrança não encontrada ou já paga/cancelada", http.StatusUnprocessableEntity)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// RegistarPagamentoEscolarV2 regista pagamento com integração financeira.
func (h *Handler) RegistarPagamentoEscolarV2(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.SchoolPayment
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	input.CreatedBy = &u.ID
	if input.PagoEm.IsZero() {
		input.PagoEm = time.Now()
	}

	if err := h.feeService().RegisterPayment(r.Context(), &input); err != nil {
		switch {
		case errors.Is(err, services.ErrFeeInvalidData):
			jsonErr(w, err.Error(), http.StatusBadRequest)
		case errors.Is(err, services.ErrFeeNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}

	// Notificação de confirmação de pagamento ao aluno (assíncrona)
	if h.notification != nil && input.StudentID != 0 {
		tenantID, studentID, valor, moeda, feeID := input.TenantID, input.StudentID, input.Valor, input.Moeda, input.SchoolFeeID
		go func() {
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			var email, descricao string
			_ = h.db.QueryRow(ctx, `
				SELECT COALESCE(NULLIF(s.portal_email,''), COALESCE(u.email,'')),
				       COALESCE(f.descricao,'')
				  FROM gestao_escolar.school_students s
				  LEFT JOIN auth.users u ON u.id = s.user_id
				  LEFT JOIN gestao_escolar.school_fees f ON f.id = $3
				 WHERE s.id = $1 AND s.tenant_id = $2`,
				studentID, tenantID, feeID,
			).Scan(&email, &descricao)
			if email == "" {
				return
			}
			sid := studentID
			h.notification.Send(ctx, contracts.Notification{
				TenantID:       tenantID,
				CanalTipo:      "email",
				Destinatario:   email,
				Assunto:        "Pagamento recebido com sucesso",
				Corpo:          fmt.Sprintf("O seu pagamento de %.2f %s referente a \"%s\" foi registado com sucesso. Obrigado!", valor, moeda, descricao),
				ReferenciaTipo: "escolar.pagamento",
				ReferenciaID:   &sid,
			})
		}()
	}

	jsonOK(w, input, http.StatusCreated)
}
