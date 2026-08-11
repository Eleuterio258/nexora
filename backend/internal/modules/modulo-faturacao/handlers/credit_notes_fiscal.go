package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/shared/contracts"
)

// AdicionarItemNotaCredito adiciona um item a uma nota de crédito em
// rascunho. Mesmo padrão de cálculo de AdicionarItemFaturaFiscal, mas sem
// desconto — faturacao.credit_note_items não tem colunas
// desconto_percent/desconto_valor (ao contrário de invoice_items).
// POST /api/faturacao/credit-notes/{id}/items.
func (h *Handler) AdicionarItemNotaCredito(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		ProductID      *int64  `json:"product_id"`
		Descricao      *string `json:"descricao"`
		Quantidade     float64 `json:"quantidade"`
		PrecoUnitario  float64 `json:"preco_unitario"`
		TaxID          *int64  `json:"tax_id"`
		ImpostoPercent float64 `json:"imposto_percent"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Quantidade <= 0 ||
		body.PrecoUnitario <= 0 || body.ImpostoPercent < 0 {
		jsonErr(w, "quantidade, preco e imposto validos sao obrigatorios", http.StatusBadRequest)
		return
	}
	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var creditNoteID int64
	if err := tx.QueryRow(r.Context(), `
		SELECT id FROM faturacao.credit_notes
		 WHERE id=$1 AND tenant_id=$2 AND status='rascunho' FOR UPDATE`,
		chi.URLParam(r, "id"), user.TenantID).Scan(&creditNoteID); err != nil {
		jsonErr(w, "Nota de crédito em rascunho nao encontrada", http.StatusNotFound)
		return
	}
	if body.TaxID != nil {
		var taxRate float64
		if err := tx.QueryRow(r.Context(), `
			SELECT taxa FROM impostos.taxes WHERE id=$1 AND tenant_id=$2 AND ativo`,
			body.TaxID, user.TenantID).Scan(&taxRate); err != nil {
			jsonErr(w, "Imposto nao encontrado", http.StatusUnprocessableEntity)
			return
		}
		body.ImpostoPercent = taxRate
	}

	subtotal := body.Quantidade * body.PrecoUnitario
	imposto := subtotal * body.ImpostoPercent / 100
	total := subtotal + imposto

	var id int64
	err = tx.QueryRow(r.Context(), `
		INSERT INTO faturacao.credit_note_items(
		  credit_note_id,product_id,descricao,quantidade,preco_unitario,tax_id,imposto_percent,imposto_valor,subtotal,total)
		VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING id`,
		creditNoteID, body.ProductID, body.Descricao, body.Quantidade, body.PrecoUnitario,
		body.TaxID, body.ImpostoPercent, imposto, subtotal, total).Scan(&id)
	if err == nil {
		_, err = tx.Exec(r.Context(), `
			UPDATE faturacao.credit_notes SET subtotal=subtotal+$1,imposto_total=imposto_total+$2,total=total+$3
			 WHERE id=$4`, subtotal, imposto, total, creditNoteID)
	}
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Nao foi possivel adicionar o item", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id, "total": total, "imposto_valor": imposto}, http.StatusCreated)
}

// EmitirNotaCredito emite uma nota de crédito em rascunho com itens — mesmo
// padrão de EmitirFaturaFiscal: exige pelo menos 1 item, gera lançamento de
// estorno em Contabilidade e evento de auditoria legal.
// POST /api/faturacao/credit-notes/{id}/emitir.
func (h *Handler) EmitirNotaCredito(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	idStr := chi.URLParam(r, "id")

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var count int
	if err := tx.QueryRow(r.Context(), `
		SELECT COUNT(*) FROM faturacao.credit_note_items i
		JOIN faturacao.credit_notes n ON n.id=i.credit_note_id
		WHERE n.id=$1 AND n.tenant_id=$2 AND n.status='rascunho'`,
		idStr, user.TenantID).Scan(&count); err != nil || count == 0 {
		jsonErr(w, "Nota de crédito em rascunho sem itens nao pode ser emitida", http.StatusConflict)
		return
	}

	tag, err := tx.Exec(r.Context(), `
		UPDATE faturacao.credit_notes SET status='emitida', emitida_em=NOW()
		 WHERE id=$1 AND tenant_id=$2 AND status='rascunho'`,
		idStr, user.TenantID)
	if err != nil {
		jsonErr(w, "Nao foi possivel emitir a nota de credito", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Nota de crédito em rascunho nao encontrada", http.StatusNotFound)
		return
	}
	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Nao foi possivel emitir a nota de credito", http.StatusInternalServerError)
		return
	}

	if id, err := strconv.ParseInt(idStr, 10, 64); err == nil {
		h.gerarLancamentoEstornoNotaCredito(r.Context(), user.TenantID, user.ID, id)
		if h.legalAudit != nil {
			actorID := user.ID
			h.legalAudit.RecordEvent(r.Context(), contracts.LegalAuditEvent{
				TenantID: user.TenantID, ActorUserID: &actorID, IPAddress: r.RemoteAddr,
				ServiceName: "nexora-erp", ModuleName: "faturacao", Action: "emitir_nota_credito",
				EntityType: "credit_note", EntityID: fmt.Sprint(id),
			})
		}
	}

	jsonOK(w, map[string]any{"estado": "emitida"}, http.StatusOK)
}

// ObterNotaCredito devolve o cabeçalho + itens de uma nota de crédito.
// GET /api/faturacao/credit-notes/{id}.
func (h *Handler) ObterNotaCredito(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var n struct {
		ID           int64      `json:"id"`
		Numero       string     `json:"numero"`
		InvoiceID    *int64     `json:"invoice_id"`
		CustomerID   int64      `json:"customer_id"`
		Motivo       string     `json:"motivo"`
		Status       string     `json:"status"`
		Moeda        string     `json:"moeda"`
		Subtotal     float64    `json:"subtotal"`
		ImpostoTotal float64    `json:"imposto_total"`
		Total        float64    `json:"total"`
		CreditDate   time.Time  `json:"credit_date"`
		EmitidaEm    *time.Time `json:"emitida_em"`
		Observacoes  *string    `json:"observacoes"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, numero, invoice_id, customer_id, motivo, status, moeda, subtotal, imposto_total, total,
		       credit_date, emitida_em, observacoes
		  FROM faturacao.credit_notes WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).
		Scan(&n.ID, &n.Numero, &n.InvoiceID, &n.CustomerID, &n.Motivo, &n.Status, &n.Moeda,
			&n.Subtotal, &n.ImpostoTotal, &n.Total, &n.CreditDate, &n.EmitidaEm, &n.Observacoes)
	if err != nil {
		jsonErr(w, "Nota de crédito não encontrada", http.StatusNotFound)
		return
	}

	rows, _ := h.db.Query(r.Context(), `
		SELECT id, product_id, descricao, quantidade, preco_unitario, imposto_percent, imposto_valor, total
		  FROM faturacao.credit_note_items WHERE credit_note_id=$1 ORDER BY id`, id)
	defer rows.Close()
	type Item struct {
		ID             int64   `json:"id"`
		ProductID      *int64  `json:"product_id"`
		Descricao      *string `json:"descricao"`
		Quantidade     float64 `json:"quantidade"`
		PrecoUnitario  float64 `json:"preco_unitario"`
		ImpostoPercent float64 `json:"imposto_percent"`
		ImpostoValor   float64 `json:"imposto_valor"`
		Total          float64 `json:"total"`
	}
	items := []Item{}
	for rows.Next() {
		var i Item
		if rows.Scan(&i.ID, &i.ProductID, &i.Descricao, &i.Quantidade, &i.PrecoUnitario, &i.ImpostoPercent, &i.ImpostoValor, &i.Total) == nil {
			items = append(items, i)
		}
	}
	jsonOK(w, map[string]any{"nota_credito": n, "itens": items}, http.StatusOK)
}

// CancelarNotaCredito cancela uma nota de crédito. POST /api/faturacao/credit-notes/{id}/cancelar.
func (h *Handler) CancelarNotaCredito(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(), `UPDATE faturacao.credit_notes SET status='cancelada' WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil || tag.RowsAffected() != 1 {
		jsonErr(w, "Nota de crédito não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
