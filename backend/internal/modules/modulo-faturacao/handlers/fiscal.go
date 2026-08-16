package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/shared/contracts"
)

func (h *Handler) AdicionarItemFaturaFiscal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		ProductID       *int64  `json:"product_id"`
		Descricao       *string `json:"descricao"`
		Quantidade      float64 `json:"quantidade"`
		PrecoUnitario   float64 `json:"preco_unitario"`
		DescontoPercent float64 `json:"desconto_percent"`
		TaxID           *int64  `json:"tax_id"`
		ImpostoPercent  float64 `json:"imposto_percent"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Quantidade <= 0 ||
		body.PrecoUnitario <= 0 || body.DescontoPercent < 0 || body.ImpostoPercent < 0 {
		jsonErr(w, "quantidade, preco e imposto validos sao obrigatorios", http.StatusBadRequest)
		return
	}
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	var invoiceID int64
	err := tx.QueryRow(r.Context(), `
		SELECT id FROM faturacao.invoices
		 WHERE id=$1 AND tenant_id=$2 AND status='rascunho' FOR UPDATE`,
		chi.URLParam(r, "id"), user.TenantID).Scan(&invoiceID)
	if err != nil {
		jsonErr(w, "Fatura em rascunho nao encontrada", http.StatusNotFound)
		return
	}
	if body.TaxID != nil {
		var taxRate float64
		err = tx.QueryRow(r.Context(), `
			SELECT taxa FROM impostos.taxes WHERE id=$1 AND tenant_id=$2 AND ativo`,
			body.TaxID, user.TenantID).Scan(&taxRate)
		if err != nil {
			jsonErr(w, "Imposto nao encontrado", http.StatusUnprocessableEntity)
			return
		}
		body.ImpostoPercent = taxRate
	}
	subtotalBruto := body.Quantidade * body.PrecoUnitario
	desconto := subtotalBruto * body.DescontoPercent / 100
	subtotal := subtotalBruto - desconto
	imposto := subtotal * body.ImpostoPercent / 100
	total := subtotal + imposto
	var id int64
	err = tx.QueryRow(r.Context(), `
		INSERT INTO faturacao.invoice_items(
		  invoice_id,product_id,descricao,quantidade,preco_unitario,
		  desconto_percent,desconto_valor,tax_id,imposto_percent,imposto_valor,subtotal,total)
		VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING id`,
		invoiceID, body.ProductID, body.Descricao, body.Quantidade, body.PrecoUnitario,
		body.DescontoPercent, desconto, body.TaxID, body.ImpostoPercent, imposto, subtotal, total).Scan(&id)
	if err == nil {
		_, err = tx.Exec(r.Context(), `
			UPDATE faturacao.invoices SET subtotal=subtotal+$1,imposto_total=imposto_total+$2,total=total+$3
			 WHERE id=$4`, subtotal, imposto, total, invoiceID)
	}
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Nao foi possivel adicionar o item", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id, "total": total, "imposto_valor": imposto}, http.StatusCreated)
}

func (h *Handler) EmitirFaturaFiscal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	invoiceIDStr := chi.URLParam(r, "id")
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	var count int
	err := tx.QueryRow(r.Context(), `
		SELECT COUNT(*) FROM faturacao.invoice_items i
		JOIN faturacao.invoices f ON f.id=i.invoice_id
		WHERE f.id=$1 AND f.tenant_id=$2 AND f.status='rascunho'`,
		invoiceIDStr, user.TenantID).Scan(&count)
	if err != nil || count == 0 {
		jsonErr(w, "Fatura em rascunho sem itens nao pode ser emitida", http.StatusConflict)
		return
	}
	var exemptions int
	err = tx.QueryRow(r.Context(), `
		SELECT impostos.fn_aplicar_isencoes_fatura($1,$2)`,
		user.TenantID, invoiceIDStr).Scan(&exemptions)

	// FR (fatura-recibo) e VD (venda a dinheiro) ficam pagas no momento da
	// emissão, em vez de "emitida" à espera de um recibo separado — gera-se
	// logo o recibo correspondente, mantendo o mesmo rasto de auditoria que
	// um recibo criado manualmente. O total é lido depois de aplicar
	// isenções, para o recibo bater certo com o valor final da fatura.
	var tipo string
	var total float64
	if err == nil {
		err = tx.QueryRow(r.Context(), `
			SELECT tipo, total FROM faturacao.invoices
			 WHERE id=$1 AND tenant_id=$2 AND status='rascunho' FOR UPDATE`,
			invoiceIDStr, user.TenantID).Scan(&tipo, &total)
	}
	if err != nil {
		jsonErr(w, "Fatura em rascunho nao encontrada", http.StatusNotFound)
		return
	}

	novoStatus := "emitida"
	pagaNaEmissao := tipo == "FR" || tipo == "VD"
	if pagaNaEmissao {
		novoStatus = "paga"
	}
	tag, err := tx.Exec(r.Context(), `
		UPDATE faturacao.invoices
		   SET status=$1, valor_pago=CASE WHEN $1='paga' THEN $2 ELSE valor_pago END, emitida_em=NOW()
		 WHERE id=$3 AND tenant_id=$4 AND status='rascunho'`,
		novoStatus, total, invoiceIDStr, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Fatura em rascunho nao encontrada", http.StatusNotFound)
		return
	}

	if pagaNaEmissao {
		numeroRecibo, serieID, serieErr := proximoNumeroSerie(r.Context(), tx, user.TenantID, "RB")
		if serieErr != nil {
			jsonErr(w, "Não existe nenhuma série activa configurada para Recibos. Configure em Faturação > Séries Documentais.", http.StatusUnprocessableEntity)
			return
		}
		invoiceID, _ := strconv.ParseInt(invoiceIDStr, 10, 64)
		observacoes := fmt.Sprintf("Recibo automático — fatura %s emitida com pagamento imediato.", tipo)
		if _, err = tx.Exec(r.Context(), `
			INSERT INTO faturacao.invoice_receipts
			  (tenant_id, invoice_id, numero, serie_id, valor, payment_method_id, referencia, observacoes)
			VALUES ($1,$2,$3,$4,$5,NULL,NULL,$6)`,
			user.TenantID, invoiceID, numeroRecibo, serieID, total, observacoes); err != nil {
			jsonErr(w, "Nao foi possivel gerar o recibo automatico", http.StatusInternalServerError)
			return
		}
	}

	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Nao foi possivel emitir a fatura", http.StatusInternalServerError)
		return
	}

	if invoiceID, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64); err == nil {
		h.gerarLancamentoContabilisticoFatura(r.Context(), user.TenantID, user.ID, invoiceID)
		if h.legalAudit != nil {
			actorID := user.ID
			h.legalAudit.RecordEvent(r.Context(), contracts.LegalAuditEvent{
				TenantID: user.TenantID, ActorUserID: &actorID, IPAddress: r.RemoteAddr,
				ServiceName: "nexora-erp", ModuleName: "faturacao", Action: "emitir_fatura",
				EntityType: "invoice", EntityID: fmt.Sprint(invoiceID),
			})
		}
	}

	jsonOK(w, map[string]any{"estado": "emitida", "itens_isentos": exemptions}, http.StatusOK)
}
