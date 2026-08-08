package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// itemDevolvido é uma linha já processada (stock reposto, quantidade
// actualizada) dentro de EstornoParcialVenda — usada quer para gravar
// pos_sale_return_items quer, se a venda tiver fatura, para alimentar
// criarNotaCreditoParaEstorno (ver itemNotaCreditoPOS em faturacao.go).
type itemDevolvido struct {
	itemID     int64
	productID  int64
	descricao  *string
	quantidade float64
	valor      float64
}

// EstornoParcialVenda devolve uma ou mais linhas de uma venda concluída —
// diferente de CancelarVenda (pos.go), que só cancela a venda inteira. Cada
// item só pode ser devolvido até à quantidade ainda não devolvida
// (pos_sale_items.quantidade_devolvida acumula entre chamadas, por isso uma
// venda pode ter várias devoluções parciais ao longo do tempo). Repõe stock
// proporcionalmente e, se a venda tiver fatura fiscal associada (ver §2.5),
// emite também uma nota de crédito — tudo na mesma transacção: se a nota de
// crédito falhar (ex.: sem série NC configurada), o estorno inteiro reverte.
func (h *Handler) EstornoParcialVenda(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	vendaID := chi.URLParam(r, "id")

	var body struct {
		Itens []struct {
			ItemID     int64   `json:"item_id"`
			Quantidade float64 `json:"quantidade"`
		} `json:"itens"`
		Motivo string `json:"motivo"`
		Metodo string `json:"metodo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || len(body.Itens) == 0 || strings.TrimSpace(body.Motivo) == "" {
		jsonErr(w, "itens e motivo são obrigatórios", http.StatusBadRequest)
		return
	}
	if !metodosPagamentoValidos[body.Metodo] {
		jsonErr(w, "metodo (de reembolso) inválido", http.StatusBadRequest)
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
	var invoiceID *int64
	var customerID *int64
	if err := tx.QueryRow(ctx, `
		SELECT terminal_id, status, invoice_id, customer_id
		  FROM pos_sales WHERE id=$1 AND tenant_id=$2 FOR UPDATE`,
		vendaID, user.TenantID,
	).Scan(&terminalID, &status, &invoiceID, &customerID); err != nil {
		jsonErr(w, "Venda não encontrada", http.StatusNotFound)
		return
	}
	if status != "concluida" {
		jsonErr(w, "Só é possível devolver itens de uma venda concluída", http.StatusUnprocessableEntity)
		return
	}
	var warehouseID *int64
	if err := tx.QueryRow(ctx, `SELECT warehouse_id FROM pos_terminals WHERE id=$1`, terminalID).Scan(&warehouseID); err != nil || warehouseID == nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	var valorTotalDevolvido float64
	var itensDevolvidos []itemDevolvido

	for _, it := range body.Itens {
		if it.Quantidade <= 0 {
			jsonErr(w, "quantidade deve ser positiva em todos os itens", http.StatusBadRequest)
			return
		}

		var productID int64
		var variantID *int64
		var descricao *string
		var quantidadeOriginal, quantidadeDevolvida, totalItem float64
		if err := tx.QueryRow(ctx, `
			SELECT product_id, product_variant_id, descricao, quantidade, quantidade_devolvida, total
			  FROM pos_sale_items WHERE id=$1 AND pos_sale_id=$2 FOR UPDATE`,
			it.ItemID, vendaID,
		).Scan(&productID, &variantID, &descricao, &quantidadeOriginal, &quantidadeDevolvida, &totalItem); err != nil {
			jsonErr(w, fmt.Sprintf("Item #%d não encontrado nesta venda", it.ItemID), http.StatusNotFound)
			return
		}

		disponivel := quantidadeOriginal - quantidadeDevolvida
		if it.Quantidade > disponivel+0.0005 {
			jsonErr(w, fmt.Sprintf("Item #%d: só %.2f unidade(s) disponíveis para devolução", it.ItemID, disponivel), http.StatusUnprocessableEntity)
			return
		}

		// Valor proporcional sobre o total já líquido de desconto/imposto do
		// item — nunca recalculado a partir do preço de tabela, para o
		// reembolso corresponder exactamente ao que foi cobrado.
		valorUnitarioEfetivo := totalItem / quantidadeOriginal
		valorDevolvidoItem := valorUnitarioEfetivo * it.Quantidade

		if _, err := tx.Exec(ctx, `
			UPDATE pos_sale_items SET quantidade_devolvida = quantidade_devolvida + $1 WHERE id=$2`,
			it.Quantidade, it.ItemID); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}

		var stockItemID int64
		if err := tx.QueryRow(ctx, `
			SELECT id FROM stock_items
			 WHERE tenant_id=$1 AND product_id=$2 AND warehouse_id=$3
			   AND product_variant_id IS NOT DISTINCT FROM $4
			 FOR UPDATE`,
			user.TenantID, productID, *warehouseID, variantID,
		).Scan(&stockItemID); err == nil {
			if _, err := tx.Exec(ctx, `UPDATE stock_items SET quantity=quantity+$1, updated_at=NOW() WHERE id=$2`,
				it.Quantidade, stockItemID); err != nil {
				jsonErr(w, "Erro interno", http.StatusInternalServerError)
				return
			}
			if _, err := tx.Exec(ctx, `
				INSERT INTO stock_movements (tenant_id, stock_item_id, tipo, quantity, reference_type, reference_id)
				VALUES ($1,$2,'entrada',$3,'pos_sale_estorno_parcial',$4)`,
				user.TenantID, stockItemID, it.Quantidade, vendaID); err != nil {
				jsonErr(w, "Erro interno", http.StatusInternalServerError)
				return
			}
		}
		// Sem stock_item correspondente: não bloqueia o estorno (o produto
		// pode ter sido descontinuado entretanto) — só não há onde repor.

		valorTotalDevolvido += valorDevolvidoItem
		itensDevolvidos = append(itensDevolvidos, itemDevolvido{
			itemID: it.ItemID, productID: productID, descricao: descricao,
			quantidade: it.Quantidade, valor: valorDevolvidoItem,
		})
	}

	var returnID int64
	if err := tx.QueryRow(ctx, `
		INSERT INTO pos_sale_returns (tenant_id, pos_sale_id, motivo, metodo, valor_total, created_by)
		VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		user.TenantID, vendaID, body.Motivo, body.Metodo, valorTotalDevolvido, user.ID,
	).Scan(&returnID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	for _, item := range itensDevolvidos {
		if _, err := tx.Exec(ctx, `
			INSERT INTO pos_sale_return_items (pos_sale_return_id, pos_sale_item_id, quantidade, valor)
			VALUES ($1,$2,$3,$4)`,
			returnID, item.itemID, item.quantidade, item.valor); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
	}

	// Se, somando esta e devoluções anteriores, já não resta nada por
	// devolver, a venda equivale a totalmente cancelada.
	var restam float64
	tx.QueryRow(ctx, `SELECT COALESCE(SUM(quantidade - quantidade_devolvida),0) FROM pos_sale_items WHERE pos_sale_id=$1`, vendaID).Scan(&restam)
	statusVenda := "concluida"
	if restam <= 0.0005 {
		statusVenda = "cancelada"
		if _, err := tx.Exec(ctx, `UPDATE pos_sales SET status='cancelada' WHERE id=$1`, vendaID); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
	}

	resp := map[string]any{
		"id": returnID, "valor_devolvido": valorTotalDevolvido, "status_venda": statusVenda,
	}

	// Nota de crédito fiscal — só se a venda tiver fatura associada (ver §2.5
	// de docs/backend-go-gaps-paycore.md). Vendas sem fatura (ex.: anteriores
	// a esta funcionalidade) só ficam com o registo em pos_sale_returns.
	if invoiceID != nil && customerID != nil {
		itensNC := make([]itemNotaCreditoPOS, len(itensDevolvidos))
		for i, it := range itensDevolvidos {
			itensNC[i] = itemNotaCreditoPOS{
				ProductID: it.productID, Descricao: it.descricao,
				Quantidade: it.quantidade, Valor: it.valor,
			}
		}
		creditNoteID, creditNoteNumero, err := h.criarNotaCreditoParaEstorno(ctx, tx, notaCreditoParams{
			tenantID: user.TenantID, customerID: *customerID, invoiceID: *invoiceID,
			userID: user.ID, motivo: body.Motivo, itens: itensNC, total: valorTotalDevolvido,
		})
		if err != nil {
			jsonErr(w, "Não existe nenhuma série activa configurada para Notas de Crédito (NC). Configure em Faturação > Séries Documentais.", http.StatusUnprocessableEntity)
			return
		}
		if _, err := tx.Exec(ctx, `UPDATE pos_sale_returns SET credit_note_id=$1 WHERE id=$2`, creditNoteID, returnID); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		resp["credit_note_id"] = creditNoteID
		resp["credit_note_numero"] = creditNoteNumero
	}

	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, resp, http.StatusCreated)
}

// ListarEstornosVenda lista as devoluções parciais já feitas a uma venda —
// útil para o app não deixar o operador tentar devolver mais do que resta.
func (h *Handler) ListarEstornosVenda(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	vendaID := chi.URLParam(r, "id")

	rows, err := h.db.Query(r.Context(), `
		SELECT ret.id, ret.motivo, ret.metodo, ret.valor_total, ret.credit_note_id,
		       ret.created_by, COALESCE(u.nome,''), ret.created_at
		  FROM pos_sale_returns ret
		  JOIN pos_sales s ON s.id = ret.pos_sale_id
		  LEFT JOIN auth.users u ON u.id = ret.created_by
		 WHERE ret.pos_sale_id=$1 AND s.tenant_id=$2
		 ORDER BY ret.created_at DESC`,
		vendaID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID           int64     `json:"id"`
		Motivo       string    `json:"motivo"`
		Metodo       string    `json:"metodo"`
		ValorTotal   float64   `json:"valor_total"`
		CreditNoteID *int64    `json:"credit_note_id"`
		CreatedBy    *int64    `json:"created_by"`
		OperadorNome string    `json:"operador_nome"`
		CreatedAt    time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var row Row
		if rows.Scan(&row.ID, &row.Motivo, &row.Metodo, &row.ValorTotal, &row.CreditNoteID,
			&row.CreatedBy, &row.OperadorNome, &row.CreatedAt) == nil {
			data = append(data, row)
		}
	}
	jsonOK(w, data, http.StatusOK)
}
