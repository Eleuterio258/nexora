package handlers

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// ObterRecibo devolve os dados completos para impressão/reimpressão de um
// recibo — cabeçalho fiscal da empresa, itens, pagamentos e o número da
// fatura/nota de crédito associada, se existir. Ao contrário de ObterVenda
// (pensado para o detalhe da venda no ecrã), este endpoint existe para que
// um recibo possa ser reimpresso a partir de QUALQUER terminal — antes só
// era possível reimprimir a partir dos dados locais do Room do aparelho que
// criou a venda, o que falhava noutro dispositivo ou depois de reinstalar a
// app.
func (h *Handler) ObterRecibo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var venda struct {
		ID            int64      `json:"id"`
		Numero        string     `json:"numero"`
		Status        string     `json:"status"`
		Moeda         string     `json:"moeda"`
		Subtotal      float64    `json:"subtotal"`
		DescontoTotal float64    `json:"desconto_total"`
		ImpostoTotal  float64    `json:"imposto_total"`
		Total         float64    `json:"total"`
		ValorRecebido float64    `json:"valor_recebido"`
		Troco         float64    `json:"troco"`
		SoldAt        *time.Time `json:"sold_at"`
		InvoiceID     *int64     `json:"invoice_id"`
		InvoiceNumero *string    `json:"invoice_numero"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT s.id, s.numero, s.status, s.moeda, s.subtotal, s.desconto_total, s.imposto_total, s.total, s.valor_recebido, s.troco, s.sold_at, s.invoice_id, i.numero
		  FROM pos_sales s LEFT JOIN faturacao.invoices i ON i.id = s.invoice_id
		 WHERE s.id=$1 AND s.tenant_id=$2`, id, user.TenantID).
		Scan(&venda.ID, &venda.Numero, &venda.Status, &venda.Moeda, &venda.Subtotal, &venda.DescontoTotal, &venda.ImpostoTotal, &venda.Total, &venda.ValorRecebido, &venda.Troco, &venda.SoldAt, &venda.InvoiceID, &venda.InvoiceNumero)
	if err != nil {
		jsonErr(w, "Venda não encontrada", http.StatusNotFound)
		return
	}

	rows, _ := h.db.Query(r.Context(), `
		SELECT descricao, quantidade, preco_unitario, desconto_valor, imposto_valor, total, quantidade_devolvida
		  FROM pos_sale_items WHERE pos_sale_id=$1 ORDER BY id`, id)
	defer rows.Close()
	type itemRecibo struct {
		Descricao           *string `json:"descricao"`
		Quantidade          float64 `json:"quantidade"`
		PrecoUnitario       float64 `json:"preco_unitario"`
		DescontoValor       float64 `json:"desconto_valor"`
		ImpostoValor        float64 `json:"imposto_valor"`
		Total               float64 `json:"total"`
		QuantidadeDevolvida float64 `json:"quantidade_devolvida"`
	}
	itens := []itemRecibo{}
	for rows.Next() {
		var i itemRecibo
		if rows.Scan(&i.Descricao, &i.Quantidade, &i.PrecoUnitario, &i.DescontoValor, &i.ImpostoValor, &i.Total, &i.QuantidadeDevolvida) == nil {
			itens = append(itens, i)
		}
	}

	payRows, _ := h.db.Query(r.Context(), `SELECT tipo, valor, referencia FROM pos_sale_payments WHERE pos_sale_id=$1 ORDER BY id`, id)
	defer payRows.Close()
	type pagamentoRecibo struct {
		Tipo       string  `json:"tipo"`
		Valor      float64 `json:"valor"`
		Referencia *string `json:"referencia"`
	}
	pagamentos := []pagamentoRecibo{}
	for payRows.Next() {
		var p pagamentoRecibo
		if payRows.Scan(&p.Tipo, &p.Valor, &p.Referencia) == nil {
			pagamentos = append(pagamentos, p)
		}
	}

	// Cabeçalho fiscal — best-effort: um tenant sem empresa/NUIT configurado
	// continua a receber o recibo, só sem esses campos preenchidos.
	var empresa struct {
		Nome     string  `json:"nome"`
		Nuit     *string `json:"nuit"`
		Endereco *string `json:"endereco"`
	}
	h.db.QueryRow(r.Context(), `
		SELECT COALESCE(c.nome_comercial, c.nome, t.nome), ti.nuit, a.endereco
		  FROM saas.tenants t
		  LEFT JOIN empresas.companies c ON c.id = t.company_id
		  LEFT JOIN empresas.company_tax_info ti ON ti.company_id = c.id
		  LEFT JOIN empresas.company_addresses a ON a.company_id = c.id AND a.tipo = 'principal'
		 WHERE t.id=$1
		 LIMIT 1`, user.TenantID).Scan(&empresa.Nome, &empresa.Nuit, &empresa.Endereco)

	jsonOK(w, map[string]any{
		"venda":      venda,
		"itens":      itens,
		"pagamentos": pagamentos,
		"empresa":    empresa,
	}, http.StatusOK)
}
