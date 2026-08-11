package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// ── PayCore-compatible transactions API (/api/v1/transactions) ───────────────
//
// O frontend PayCore apresenta vendas POS como "Documentos de Venda". Estes
// handlers expõem as transações POS no formato esperado pelo frontend.

type paycoreTransaction struct {
	ID            int64                  `json:"id"`
	Reference     string                 `json:"reference"`
	Timestamp     int64                  `json:"timestamp"`
	Status        string                 `json:"status"`
	PaymentMethod string                 `json:"payment_method"`
	Subtotal      float64                `json:"subtotal"`
	Discount      float64                `json:"discount"`
	Tax           float64                `json:"tax"`
	Total         float64                `json:"total"`
	Items         []paycoreTransactionItem `json:"items"`
}

type paycoreTransactionItem struct {
	Name     string  `json:"name"`
	Quantity float64 `json:"quantity"`
	Price    float64 `json:"price"`
	Discount float64 `json:"discount"`
	Tax      float64 `json:"tax"`
	Total    float64 `json:"total"`
}

func (h *Handler) PayCoreListarTransacoes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	statusFilter := r.URL.Query().Get("status")
	dateFilter := r.URL.Query().Get("date")

	where := "s.tenant_id = $1"
	args := []any{user.TenantID}

	if dateFilter != "" {
		args = append(args, dateFilter)
		where += " AND DATE(COALESCE(s.sold_at, s.created_at)) = $" + strconv.Itoa(len(args))
	}

	// Ordenar por data descendente
	query := `
		SELECT s.id, s.numero, COALESCE(s.sold_at, s.created_at), s.subtotal, s.desconto_total, s.imposto_total, s.total, s.status,
		       (SELECT EXISTS(SELECT 1 FROM pos_sale_returns ret WHERE ret.pos_sale_id = s.id))
		FROM pos.pos_sales s
		WHERE ` + where + `
		ORDER BY COALESCE(s.sold_at, s.created_at) DESC`

	rows, err := h.db.Query(r.Context(), query, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var result []paycoreTransaction
	for rows.Next() {
		var t paycoreTransaction
		var ts time.Time
		var dbStatus string
		var hasReturns bool
		if err := rows.Scan(&t.ID, &t.Reference, &ts, &t.Subtotal, &t.Discount, &t.Tax, &t.Total, &dbStatus, &hasReturns); err != nil {
			continue
		}
		t.Timestamp = ts.UnixMilli()
		t.Status = paycoreStatusFromSale(dbStatus, hasReturns)
		if statusFilter != "" && !strings.EqualFold(t.Status, statusFilter) {
			continue
		}
		result = append(result, t)
	}

	jsonOK(w, result, http.StatusOK)
}

func (h *Handler) PayCoreObterTransacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var t paycoreTransaction
	var ts time.Time
	var dbStatus string
	var hasReturns bool
	err := h.db.QueryRow(r.Context(), `
		SELECT s.id, s.numero, COALESCE(s.sold_at, s.created_at), s.subtotal, s.desconto_total, s.imposto_total, s.total, s.status,
		       (SELECT EXISTS(SELECT 1 FROM pos_sale_returns ret WHERE ret.pos_sale_id = s.id))
		FROM pos.pos_sales s
		WHERE s.id = $1 AND s.tenant_id = $2`,
		id, user.TenantID,
	).Scan(&t.ID, &t.Reference, &ts, &t.Subtotal, &t.Discount, &t.Tax, &t.Total, &dbStatus, &hasReturns)
	if err != nil {
		jsonErr(w, "Transacção não encontrada", http.StatusNotFound)
		return
	}
	t.Timestamp = ts.UnixMilli()
	t.Status = paycoreStatusFromSale(dbStatus, hasReturns)

	// itens
	itemRows, err := h.db.Query(r.Context(), `
		SELECT descricao, quantidade, preco_unitario, desconto_valor, imposto_valor, total
		FROM pos.pos_sale_items WHERE pos_sale_id = $1 ORDER BY id`, t.ID)
	if err == nil {
		defer itemRows.Close()
		for itemRows.Next() {
			var it paycoreTransactionItem
			if itemRows.Scan(&it.Name, &it.Quantity, &it.Price, &it.Discount, &it.Tax, &it.Total) == nil {
				t.Items = append(t.Items, it)
			}
		}
	}

	// método de pagamento (primeiro)
	var paymentMethod string
	h.db.QueryRow(r.Context(), `SELECT tipo FROM pos.pos_sale_payments WHERE pos_sale_id = $1 LIMIT 1`, t.ID).Scan(&paymentMethod)
	t.PaymentMethod = paymentMethod

	jsonOK(w, t, http.StatusOK)
}

func (h *Handler) PayCoreCancelarTransacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Reason string `json:"reason"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	var status string
	err := h.db.QueryRow(r.Context(), `SELECT status FROM pos.pos_sales WHERE id = $1 AND tenant_id = $2`, id, user.TenantID).Scan(&status)
	if err != nil {
		jsonErr(w, "Transacção não encontrada", http.StatusNotFound)
		return
	}
	if status == "cancelada" {
		jsonErr(w, "Transacção já cancelada", http.StatusUnprocessableEntity)
		return
	}

	_, err = h.db.Exec(r.Context(), `UPDATE pos.pos_sales SET status = 'cancelada', updated_at = NOW() WHERE id = $1`, id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]string{"status": "CANCELLED"}, http.StatusOK)
}

func (h *Handler) PayCoreEstornarTransacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Reason string `json:"reason"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "payload inválido", http.StatusBadRequest)
		return
	}
	if strings.TrimSpace(body.Reason) == "" {
		jsonErr(w, "motivo é obrigatório", http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	var terminalID int64
	var status string
	var invoiceID, customerID *int64
	if err := tx.QueryRow(ctx, `
		SELECT terminal_id, status, invoice_id, customer_id
		FROM pos.pos_sales WHERE id = $1 AND tenant_id = $2 FOR UPDATE`,
		id, user.TenantID,
	).Scan(&terminalID, &status, &invoiceID, &customerID); err != nil {
		jsonErr(w, "Transacção não encontrada", http.StatusNotFound)
		return
	}
	if status != "concluida" {
		jsonErr(w, "Só é possível estornar transacções concluídas", http.StatusUnprocessableEntity)
		return
	}

	var warehouseID *int64
	if err := tx.QueryRow(ctx, `SELECT warehouse_id FROM pos.pos_terminals WHERE id = $1`, terminalID).Scan(&warehouseID); err != nil || warehouseID == nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	// Devolver todos os itens ainda não devolvidos
	itemRows, err := tx.Query(ctx, `
		SELECT id, product_id, product_variant_id, descricao, quantidade, quantidade_devolvida, total
		FROM pos.pos_sale_items WHERE pos_sale_id = $1 FOR UPDATE`, id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	type itemPendente struct {
		itemID    int64
		productID int64
		variantID *int64
		descricao *string
		quantidade float64
		valorUnitario float64
	}
	var pendentes []itemPendente
	var valorTotalDevolvido float64

	for itemRows.Next() {
		var it itemPendente
		var totalItem, quantidade, devolvida float64
		if err := itemRows.Scan(&it.itemID, &it.productID, &it.variantID, &it.descricao, &quantidade, &devolvida, &totalItem); err != nil {
			itemRows.Close()
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		restante := quantidade - devolvida
		if restante <= 0.0005 {
			continue
		}
		it.quantidade = restante
		it.valorUnitario = totalItem / quantidade
		valorDevolvido := it.valorUnitario * restante
		valorTotalDevolvido += valorDevolvido
		pendentes = append(pendentes, it)
	}
	itemRows.Close()

	if len(pendentes) == 0 {
		jsonErr(w, "Transacção já totalmente devolvida", http.StatusUnprocessableEntity)
		return
	}

	metodo := "numerario"
	var itensDevolvidos []itemDevolvido
	for _, it := range pendentes {
		valorDevolvido := it.valorUnitario * it.quantidade
		if _, err := tx.Exec(ctx, `
			UPDATE pos.pos_sale_items SET quantidade_devolvida = quantidade_devolvida + $1 WHERE id = $2`,
			it.quantidade, it.itemID); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}

		var stockItemID int64
		if err := tx.QueryRow(ctx, `
			SELECT id FROM stock_items
			 WHERE tenant_id = $1 AND product_id = $2 AND warehouse_id = $3
			   AND product_variant_id IS NOT DISTINCT FROM $4
			 FOR UPDATE`,
			user.TenantID, it.productID, *warehouseID, it.variantID,
		).Scan(&stockItemID); err == nil {
			if _, err := tx.Exec(ctx, `UPDATE stock_items SET quantity = quantity + $1, updated_at = NOW() WHERE id = $2`,
				it.quantidade, stockItemID); err != nil {
				jsonErr(w, "Erro interno", http.StatusInternalServerError)
				return
			}
			if _, err := tx.Exec(ctx, `
				INSERT INTO stock_movements (tenant_id, stock_item_id, tipo, quantity, reference_type, reference_id)
				VALUES ($1, $2, 'entrada', $3, 'pos_sale_estorno_paycore', $4)`,
				user.TenantID, stockItemID, it.quantidade, id); err != nil {
				jsonErr(w, "Erro interno", http.StatusInternalServerError)
				return
			}
		}

		itensDevolvidos = append(itensDevolvidos, itemDevolvido{
			itemID: it.itemID, productID: it.productID, descricao: it.descricao,
			quantidade: it.quantidade, valor: valorDevolvido,
		})
	}

	var returnID int64
	if err := tx.QueryRow(ctx, `
		INSERT INTO pos_sale_returns (tenant_id, pos_sale_id, motivo, metodo, valor_total, created_by)
		VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
		user.TenantID, id, body.Reason, metodo, valorTotalDevolvido, user.ID,
	).Scan(&returnID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	for _, item := range itensDevolvidos {
		if _, err := tx.Exec(ctx, `
			INSERT INTO pos_sale_return_items (pos_sale_return_id, pos_sale_item_id, quantidade, valor)
			VALUES ($1, $2, $3, $4)`,
			returnID, item.itemID, item.quantidade, item.valor); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
	}

	// Se restam itens por devolver, mantém concluida; senão cancela
	var restam float64
	tx.QueryRow(ctx, `SELECT COALESCE(SUM(quantidade - quantidade_devolvida), 0) FROM pos.pos_sale_items WHERE pos_sale_id = $1`, id).Scan(&restam)
	if restam <= 0.0005 {
		if _, err := tx.Exec(ctx, `UPDATE pos.pos_sales SET status = 'cancelada' WHERE id = $1`, id); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
	}

	// Nota de crédito fiscal quando há fatura associada
	if invoiceID != nil && customerID != nil {
		itensNC := make([]itemNotaCreditoPOS, len(itensDevolvidos))
		for i, it := range itensDevolvidos {
			itensNC[i] = itemNotaCreditoPOS{
				ProductID: it.productID, Descricao: it.descricao,
				Quantidade: it.quantidade, Valor: it.valor,
			}
		}
		creditNoteID, _, err := h.criarNotaCreditoParaEstorno(ctx, tx, notaCreditoParams{
			tenantID: user.TenantID, customerID: *customerID, invoiceID: *invoiceID,
			userID: user.ID, motivo: body.Reason, itens: itensNC, total: valorTotalDevolvido,
		})
		if err == nil {
			tx.Exec(ctx, `UPDATE pos_sale_returns SET credit_note_id = $1 WHERE id = $2`, creditNoteID, returnID)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]string{"status": "REVERSED"}, http.StatusOK)
}

func paycoreStatusFromSale(dbStatus string, hasReturns bool) string {
	switch dbStatus {
	case "concluida":
		return "APPROVED"
	case "rascunho":
		return "PENDING"
	case "cancelada":
		if hasReturns {
			return "REVERSED"
		}
		return "CANCELLED"
	default:
		return "UNKNOWN"
	}
}
