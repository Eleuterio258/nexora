package handlers

import (
	"net/http"
	"strconv"
	"time"

	mw "nexora/internal/middleware"
)

// periodoRelatorio lê "from"/"to" (YYYY-MM-DD) da query string, com omissão
// = últimos 30 dias. "to" é sempre tratado como fim do dia (23:59:59) para
// incluir vendas feitas nesse próprio dia.
func periodoRelatorio(r *http.Request) (de, ate time.Time) {
	q := r.URL.Query()
	ate = time.Now()
	de = ate.AddDate(0, 0, -30)
	if v := q.Get("from"); v != "" {
		if t, err := time.Parse("2006-01-02", v); err == nil {
			de = t
		}
	}
	if v := q.Get("to"); v != "" {
		if t, err := time.Parse("2006-01-02", v); err == nil {
			ate = t.Add(24*time.Hour - time.Second)
		}
	}
	return
}

// RelatorioVendas agrega vendas concluídas no período por dia, operador,
// terminal ou método de pagamento — cobre os 4 primeiros itens de
// relatórios POS pedidos (vendas por período/operador/terminal/método) num
// único endpoint parametrizado, em vez de 4 rotas quase idênticas.
func (h *Handler) RelatorioVendas(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	de, ate := periodoRelatorio(r)
	agruparPor := r.URL.Query().Get("agrupar_por")
	if agruparPor == "" {
		agruparPor = "dia"
	}

	type Row struct {
		Chave       string  `json:"chave"`
		Rotulo      string  `json:"rotulo"`
		TotalVendas int64   `json:"total_vendas"`
		TotalValor  float64 `json:"total_valor"`
	}

	var query string
	switch agruparPor {
	case "operador":
		query = `
			SELECT COALESCE(s.created_by::text,''), COALESCE(u.nome,'Sem operador'), COUNT(*), COALESCE(SUM(s.total),0)
			  FROM pos_sales s LEFT JOIN auth.users u ON u.id = s.created_by
			 WHERE s.tenant_id=$1 AND s.status='concluida' AND s.sold_at BETWEEN $2 AND $3
			 GROUP BY s.created_by, u.nome
			 ORDER BY SUM(s.total) DESC`
	case "terminal":
		query = `
			SELECT COALESCE(s.terminal_id::text,''), COALESCE(t.nome,'Terminal removido'), COUNT(*), COALESCE(SUM(s.total),0)
			  FROM pos_sales s LEFT JOIN pos_terminals t ON t.id = s.terminal_id
			 WHERE s.tenant_id=$1 AND s.status='concluida' AND s.sold_at BETWEEN $2 AND $3
			 GROUP BY s.terminal_id, t.nome
			 ORDER BY SUM(s.total) DESC`
	case "metodo":
		query = `
			SELECT sp.tipo, sp.tipo, COUNT(*), COALESCE(SUM(sp.valor),0)
			  FROM pos_sale_payments sp JOIN pos_sales s ON s.id = sp.pos_sale_id
			 WHERE s.tenant_id=$1 AND s.status='concluida' AND s.sold_at BETWEEN $2 AND $3
			 GROUP BY sp.tipo
			 ORDER BY SUM(sp.valor) DESC`
	default: // "dia"
		agruparPor = "dia"
		query = `
			SELECT to_char(s.sold_at,'YYYY-MM-DD'), to_char(s.sold_at,'YYYY-MM-DD'), COUNT(*), COALESCE(SUM(s.total),0)
			  FROM pos_sales s
			 WHERE s.tenant_id=$1 AND s.status='concluida' AND s.sold_at BETWEEN $2 AND $3
			 GROUP BY to_char(s.sold_at,'YYYY-MM-DD')
			 ORDER BY 1`
	}

	rows, err := h.db.Query(r.Context(), query, user.TenantID, de, ate)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data := []Row{}
	for rows.Next() {
		var row Row
		if rows.Scan(&row.Chave, &row.Rotulo, &row.TotalVendas, &row.TotalValor) == nil {
			data = append(data, row)
		}
	}
	jsonOK(w, map[string]any{
		"agrupar_por": agruparPor, "from": de.Format("2006-01-02"), "to": ate.Format("2006-01-02"),
		"data": data,
	}, http.StatusOK)
}

// RelatorioTopProdutos lista os produtos mais vendidos (por quantidade) no
// período, entre vendas concluídas.
func (h *Handler) RelatorioTopProdutos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	de, ate := periodoRelatorio(r)
	limit, err := strconv.Atoi(r.URL.Query().Get("limit"))
	if err != nil || limit < 1 || limit > 100 {
		limit = 10
	}

	rows, dbErr := h.db.Query(r.Context(), `
		SELECT i.product_id, p.nome, SUM(i.quantidade), SUM(i.total)
		  FROM pos_sale_items i
		  JOIN pos_sales s ON s.id = i.pos_sale_id
		  JOIN produtos.products p ON p.id = i.product_id
		 WHERE s.tenant_id=$1 AND s.status='concluida' AND s.sold_at BETWEEN $2 AND $3
		 GROUP BY i.product_id, p.nome
		 ORDER BY SUM(i.quantidade) DESC
		 LIMIT $4`,
		user.TenantID, de, ate, limit)
	if dbErr != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ProductID       int64   `json:"product_id"`
		Nome            string  `json:"nome"`
		QuantidadeTotal float64 `json:"quantidade_total"`
		ValorTotal      float64 `json:"valor_total"`
	}
	data := []Row{}
	for rows.Next() {
		var row Row
		if rows.Scan(&row.ProductID, &row.Nome, &row.QuantidadeTotal, &row.ValorTotal) == nil {
			data = append(data, row)
		}
	}
	jsonOK(w, map[string]any{"from": de.Format("2006-01-02"), "to": ate.Format("2006-01-02"), "data": data}, http.StatusOK)
}

// RelatorioCancelamentos lista vendas canceladas/estornadas no período.
func (h *Handler) RelatorioCancelamentos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	de, ate := periodoRelatorio(r)
	limit, offset := pageParams(r)

	rows, err := h.db.Query(r.Context(), `
		SELECT s.id, s.numero, s.terminal_id, s.total, s.motivo_cancelamento, s.sold_at, s.created_by, COALESCE(u.nome,'')
		  FROM pos_sales s LEFT JOIN auth.users u ON u.id = s.created_by
		 WHERE s.tenant_id=$1 AND s.status='cancelada' AND s.sold_at BETWEEN $2 AND $3
		 ORDER BY s.sold_at DESC
		 LIMIT $4 OFFSET $5`,
		user.TenantID, de, ate, limit, offset)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID                 int64      `json:"id"`
		Numero             string     `json:"numero"`
		TerminalID         int64      `json:"terminal_id"`
		Total              float64    `json:"total"`
		MotivoCancelamento *string    `json:"motivo_cancelamento"`
		SoldAt             *time.Time `json:"sold_at"`
		CreatedBy          *int64     `json:"created_by"`
		OperadorNome       string     `json:"operador_nome"`
	}
	data := []Row{}
	for rows.Next() {
		var row Row
		if rows.Scan(&row.ID, &row.Numero, &row.TerminalID, &row.Total, &row.MotivoCancelamento,
			&row.SoldAt, &row.CreatedBy, &row.OperadorNome) == nil {
			data = append(data, row)
		}
	}
	jsonOK(w, map[string]any{"from": de.Format("2006-01-02"), "to": ate.Format("2006-01-02"), "data": data}, http.StatusOK)
}

// RelatorioFechoCaixa lista sessões de caixa fechadas no período, com o
// resumo já gravado por FecharSessao (opening/closing_amount).
func (h *Handler) RelatorioFechoCaixa(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	de, ate := periodoRelatorio(r)

	rows, err := h.db.Query(r.Context(), `
		SELECT ps.id, ps.terminal_id, COALESCE(t.nome,''), ps.user_id, COALESCE(u.nome,''),
		       ps.opened_at, ps.closed_at, ps.opening_amount, ps.closing_amount
		  FROM pos_sessions ps
		  LEFT JOIN pos_terminals t ON t.id = ps.terminal_id
		  LEFT JOIN auth.users u ON u.id = ps.user_id
		 WHERE ps.tenant_id=$1 AND ps.status='fechada' AND ps.closed_at BETWEEN $2 AND $3
		 ORDER BY ps.closed_at DESC`,
		user.TenantID, de, ate)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID            int64      `json:"id"`
		TerminalID    int64      `json:"terminal_id"`
		TerminalNome  string     `json:"terminal_nome"`
		UserID        int64      `json:"user_id"`
		OperadorNome  string     `json:"operador_nome"`
		OpenedAt      time.Time  `json:"opened_at"`
		ClosedAt      *time.Time `json:"closed_at"`
		OpeningAmount float64    `json:"opening_amount"`
		ClosingAmount *float64   `json:"closing_amount"`
		Diferenca     *float64   `json:"diferenca"`
	}
	data := []Row{}
	for rows.Next() {
		var row Row
		if rows.Scan(&row.ID, &row.TerminalID, &row.TerminalNome, &row.UserID, &row.OperadorNome,
			&row.OpenedAt, &row.ClosedAt, &row.OpeningAmount, &row.ClosingAmount) == nil {
			if row.ClosingAmount != nil {
				d := *row.ClosingAmount - row.OpeningAmount
				row.Diferenca = &d
			}
			data = append(data, row)
		}
	}
	jsonOK(w, map[string]any{"from": de.Format("2006-01-02"), "to": ate.Format("2006-01-02"), "data": data}, http.StatusOK)
}

// RelatorioTerminais devolve a disponibilidade de cada terminal do tenant —
// activo/inactivo e a sua última sessão de caixa (se alguma vez abriu uma).
func (h *Handler) RelatorioTerminais(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, err := h.db.Query(r.Context(), `
		SELECT t.id, t.codigo, t.nome, t.activo,
		       (SELECT status FROM pos_sessions WHERE terminal_id = t.id ORDER BY opened_at DESC LIMIT 1),
		       (SELECT opened_at FROM pos_sessions WHERE terminal_id = t.id ORDER BY opened_at DESC LIMIT 1)
		  FROM pos_terminals t
		 WHERE t.tenant_id = $1
		 ORDER BY t.nome`,
		user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID                 int64      `json:"id"`
		Codigo             string     `json:"codigo"`
		Nome               string     `json:"nome"`
		Activo             bool       `json:"activo"`
		UltimaSessaoStatus *string    `json:"ultima_sessao_status"`
		UltimaSessaoEm     *time.Time `json:"ultima_sessao_em"`
	}
	data := []Row{}
	for rows.Next() {
		var row Row
		if rows.Scan(&row.ID, &row.Codigo, &row.Nome, &row.Activo, &row.UltimaSessaoStatus, &row.UltimaSessaoEm) == nil {
			data = append(data, row)
		}
	}
	jsonOK(w, data, http.StatusOK)
}
