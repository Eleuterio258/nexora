package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// ── POST /api/escolar/student-invoices/{id}/parcelas ─────────────────────────
// 6.3 Divide uma cobrança em N parcelas com datas de vencimento mensais.

func (h *Handler) CriarParcelasCobranca(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	feeID := chi.URLParam(r, "id")

	var body struct {
		NParcelas    int    `json:"n_parcelas"`
		PrimeiraData string `json:"primeira_data"` // YYYY-MM-DD
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.NParcelas < 2 || body.NParcelas > 24 || body.PrimeiraData == "" {
		jsonErr(w, "n_parcelas (2-24) e primeira_data (YYYY-MM-DD) são obrigatórios", http.StatusBadRequest)
		return
	}

	primeiraData, err := time.Parse("2006-01-02", body.PrimeiraData)
	if err != nil {
		jsonErr(w, "primeira_data inválida (YYYY-MM-DD)", http.StatusBadRequest)
		return
	}

	// Obter saldo da cobrança
	var saldo float64
	var descricao, moeda string
	err = h.db.QueryRow(r.Context(), `
		SELECT GREATEST(valor_total-COALESCE(desconto,0)-COALESCE(valor_pago,0), 0),
		       descricao, moeda
		  FROM gestao_escolar.school_fees
		 WHERE id=$1 AND tenant_id=$2 AND status IN ('pendente','emitida')`,
		feeID, u.TenantID,
	).Scan(&saldo, &descricao, &moeda)
	if err != nil || saldo <= 0 {
		jsonErr(w, "Cobrança não encontrada, já paga ou sem saldo", http.StatusUnprocessableEntity)
		return
	}

	// Apagar parcelas existentes (re-parcelamento)
	_, _ = h.db.Exec(r.Context(), `
		DELETE FROM gestao_escolar.school_fee_installments
		 WHERE fee_id=$1 AND tenant_id=$2`, feeID, u.TenantID)

	valorParcela := saldo / float64(body.NParcelas)
	ids := make([]int64, 0, body.NParcelas)

	for i := 0; i < body.NParcelas; i++ {
		venc := primeiraData.AddDate(0, i, 0)
		var id int64
		err = h.db.QueryRow(r.Context(), `
			INSERT INTO gestao_escolar.school_fee_installments
				(tenant_id, fee_id, numero, valor, data_vencimento)
			VALUES ($1, $2, $3, $4, $5)
			RETURNING id`,
			u.TenantID, feeID, i+1, valorParcela, venc,
		).Scan(&id)
		if err == nil {
			ids = append(ids, id)
		}
	}

	jsonOK(w, map[string]any{
		"parcelas":  len(ids),
		"valor_parcela": fmt.Sprintf("%.2f", valorParcela),
		"moeda":     moeda,
		"descricao": descricao,
	}, http.StatusCreated)
}

// ── GET /api/escolar/student-invoices/{id}/parcelas ───────────────────────────

func (h *Handler) ListarParcelasCobranca(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	feeID := chi.URLParam(r, "id")
	h.schoolList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(p) ORDER BY p.numero), '[]')
		  FROM gestao_escolar.school_fee_installments p
		 WHERE p.fee_id=$1 AND p.tenant_id=$2`, feeID, u.TenantID)
}

// ── 6.2 Referência bancária automática na emissão ─────────────────────────────
// Chamada internamente quando uma cobrança é emitida.
// Formato: entidade = código do tenant (5 dígitos), referência = tenant+fee_id (13 dígitos).

func gerarReferenciaBancaria(tenantID, feeID int64) (entidade, referencia string) {
	entidade = fmt.Sprintf("%05d", tenantID%100000)
	referencia = fmt.Sprintf("%05d%08d", tenantID%100000, feeID%100000000)
	return
}

// ── POST /api/escolar/student-invoices/{id}/emit (override com referência) ───
// Emite uma cobrança e gera referência bancária automática (6.2).

func (h *Handler) EmitirCobrancaComReferencia(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	feeID := chi.URLParam(r, "id")

	var id int64
	_ = h.db.QueryRow(r.Context(), `
		SELECT id FROM gestao_escolar.school_fees
		 WHERE id=$1 AND tenant_id=$2 AND status='pendente'`, feeID, u.TenantID,
	).Scan(&id)
	if id == 0 {
		jsonErr(w, "Cobrança não encontrada ou já emitida", http.StatusUnprocessableEntity)
		return
	}

	entidade, ref := gerarReferenciaBancaria(u.TenantID, id)
	tag, err := h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_fees
		   SET status='emitida', emitida_em=NOW(), updated_at=NOW(),
		       banco_entidade=$1, banco_referencia=$2
		 WHERE id=$3 AND tenant_id=$4 AND status='pendente'`,
		entidade, ref, id, u.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Erro ao emitir cobrança", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{
		"ok":              true,
		"banco_entidade":  entidade,
		"banco_referencia": ref,
		"mensagem":        "Cobrança emitida com referência bancária.",
	}, http.StatusOK)
}

// ── GET /api/escolar/bolsas ───────────────────────────────────────────────────
// 6.4 Listar bolsas/isenções de um aluno.

func (h *Handler) ListarBolsas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "tenant_id=$1"
	args := []any{u.TenantID}
	if v := r.URL.Query().Get("student_id"); v != "" {
		args = append(args, v)
		where += " AND student_id=$2"
	}
	h.schoolList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(d) ORDER BY d.data_inicio DESC), '[]')
		  FROM gestao_escolar.school_student_fee_discounts d
		 WHERE `+where, args...)
}

// ── POST /api/escolar/bolsas ──────────────────────────────────────────────────

func (h *Handler) CriarBolsa(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	h.schoolCreate(w, r, `
		INSERT INTO gestao_escolar.school_student_fee_discounts
		(tenant_id, student_id, fee_plan_id, tipo, valor, data_inicio, data_fim, motivo, activo, estado, criado_por)
		SELECT $1, j.student_id, j.fee_plan_id,
		       COALESCE(j.tipo,'valor_fixo'), COALESCE(j.valor,0),
		       COALESCE(j.data_inicio, CURRENT_DATE), j.data_fim,
		       j.motivo, true,
		       CASE WHEN $3 THEN 'aprovado' ELSE 'pendente' END,
		       $2
		  FROM jsonb_to_record($4::jsonb) AS j(student_id bigint, fee_plan_id bigint,
		       tipo text, valor numeric, data_inicio date, data_fim date, motivo text)
		 WHERE j.student_id IS NOT NULL
		 RETURNING id`,
		u.TenantID, u.ID, (h.approval == nil), body)
}

// ── DELETE /api/escolar/bolsas/{id} ──────────────────────────────────────────

func (h *Handler) RemoverBolsa(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolUpdate(w, r, `
		UPDATE gestao_escolar.school_student_fee_discounts
		   SET activo = false, updated_at = NOW()
		 WHERE id=$1 AND tenant_id=$2 AND activo=true`,
		chi.URLParam(r, "id"), u.TenantID)
}
