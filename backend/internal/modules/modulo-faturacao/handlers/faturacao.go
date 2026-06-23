package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

// ── Séries ────────────────────────────────────────────────────────────────────

func (h *Handler) ListarSeries(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, tipo, prefixo, ano, sequencia, ativo
		  FROM invoice_series WHERE tenant_id=$1 ORDER BY tipo, ano DESC`, user.TenantID)
	defer rows.Close()
	type Row struct {
		ID        int64  `json:"id"`
		Tipo      string `json:"tipo"`
		Prefixo   string `json:"prefixo"`
		Ano       int    `json:"ano"`
		Sequencia int    `json:"sequencia"`
		Ativo     bool   `json:"ativo"`
	}
	data := []Row{}
	for rows.Next() {
		var s Row
		if rows.Scan(&s.ID, &s.Tipo, &s.Prefixo, &s.Ano, &s.Sequencia, &s.Ativo) == nil {
			data = append(data, s)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarSerie(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Tipo    string `json:"tipo"`
		Prefixo string `json:"prefixo"`
		Ano     *int   `json:"ano"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Tipo == "" || body.Prefixo == "" {
		jsonErr(w, "tipo e prefixo são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO invoice_series (tenant_id, tipo, prefixo, ano)
		VALUES ($1,$2,$3,COALESCE($4,EXTRACT(YEAR FROM NOW())::int)) RETURNING id`,
		user.TenantID, body.Tipo, body.Prefixo, body.Ano).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Série já existe para este tipo e ano", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) mudarAtivoSerie(ativo bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user := mw.GetUser(r)
		id := chi.URLParam(r, "id")
		h.db.Exec(r.Context(), `UPDATE invoice_series SET ativo=$1 WHERE id=$2 AND tenant_id=$3`, ativo, id, user.TenantID)
		w.WriteHeader(http.StatusNoContent)
	}
}
func (h *Handler) ActivarSerie(w http.ResponseWriter, r *http.Request)    { h.mudarAtivoSerie(true)(w, r) }
func (h *Handler) DesactivarSerie(w http.ResponseWriter, r *http.Request) { h.mudarAtivoSerie(false)(w, r) }

// proximoNumeroSerie obtem (com lock) a serie ativa do tipo indicado,
// incrementa a sua sequencia e devolve o numero de documento gerado e o
// id da serie, para serem gravados no documento dentro da mesma transacao.
func proximoNumeroSerie(ctx context.Context, tx pgx.Tx, tenantID int64, tipo string) (string, int64, error) {
	var serieID int64
	var prefixo string
	var sequencia int
	err := tx.QueryRow(ctx, `
		SELECT id, prefixo, sequencia
		  FROM invoice_series
		 WHERE tenant_id=$1 AND tipo=$2 AND ativo=true
		 ORDER BY ano DESC
		 LIMIT 1
		 FOR UPDATE`, tenantID, tipo).Scan(&serieID, &prefixo, &sequencia)
	if err != nil {
		return "", 0, err
	}
	sequencia++
	if _, err := tx.Exec(ctx, `UPDATE invoice_series SET sequencia=$1 WHERE id=$2`, sequencia, serieID); err != nil {
		return "", 0, err
	}
	return fmt.Sprintf("%s%04d", prefixo, sequencia), serieID, nil
}

// ── Orçamentos ────────────────────────────────────────────────────────────────

func (h *Handler) ListarOrcamentos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	for _, f := range []string{"status", "customer_id"} {
		if v := q.Get(f); v != "" {
			args = append(args, v)
			where += " AND " + f + "=$" + strconv.Itoa(len(args))
		}
	}
	args = append(args, limit, offset)
	n := len(args)
	rows, _ := h.db.Query(r.Context(),
		"SELECT id, numero, customer_id, status, total, moeda, validade, created_at FROM sales_quotes WHERE "+
			where+" ORDER BY created_at DESC LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n), args...)
	defer rows.Close()
	type Row struct {
		ID         int64      `json:"id"`
		Numero     string     `json:"numero"`
		CustomerID int64      `json:"customer_id"`
		Status     string     `json:"status"`
		Total      float64    `json:"total"`
		Moeda      string     `json:"moeda"`
		Validade   *time.Time `json:"validade"`
		CreatedAt  time.Time  `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var o Row
		if rows.Scan(&o.ID, &o.Numero, &o.CustomerID, &o.Status, &o.Total, &o.Moeda, &o.Validade, &o.CreatedAt) == nil {
			data = append(data, o)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarOrcamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		CustomerID  int64   `json:"customer_id"`
		Moeda       *string `json:"moeda"`
		Validade    *string `json:"validade"`
		Observacoes *string `json:"observacoes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.CustomerID == 0 {
		jsonErr(w, "customer_id é obrigatório", http.StatusBadRequest)
		return
	}
	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	numero, serieID, err := proximoNumeroSerie(ctx, tx, user.TenantID, "ORC")
	if err != nil {
		jsonErr(w, "Não existe nenhuma série activa configurada para Orçamentos. Configure em Faturação > Séries Documentais.", http.StatusUnprocessableEntity)
		return
	}

	var id int64
	err = tx.QueryRow(ctx, `
		INSERT INTO sales_quotes (tenant_id, customer_id, numero, serie_id, moeda, validade, observacoes)
		VALUES ($1,$2,$3,$4,COALESCE($5,'MZN'),$6::date,$7) RETURNING id`,
		user.TenantID, body.CustomerID, numero, serieID, body.Moeda, body.Validade, body.Observacoes).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id, "numero": numero}, http.StatusCreated)
}

func (h *Handler) ObterOrcamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var o struct {
		ID           int64      `json:"id"`
		Numero       string     `json:"numero"`
		CustomerID   int64      `json:"customer_id"`
		Status       string     `json:"status"`
		Total        float64    `json:"total"`
		ImpostoTotal float64    `json:"imposto_total"`
		Moeda        string     `json:"moeda"`
		Validade     *time.Time `json:"validade"`
		Observacoes  *string    `json:"observacoes"`
		CreatedAt    time.Time  `json:"created_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, numero, customer_id, status, total, imposto_total, moeda, validade, observacoes, created_at
		  FROM sales_quotes WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).
		Scan(&o.ID, &o.Numero, &o.CustomerID, &o.Status, &o.Total, &o.ImpostoTotal, &o.Moeda, &o.Validade, &o.Observacoes, &o.CreatedAt)
	if err != nil {
		jsonErr(w, "Orçamento não encontrado", http.StatusNotFound)
		return
	}
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, product_id, descricao, quantidade, preco_unitario, desconto_percent, imposto_percent, imposto_valor, total
		  FROM sales_quote_items WHERE sales_quote_id=$1 ORDER BY id`, id)
	defer rows.Close()
	type Item struct {
		ID              int64   `json:"id"`
		ProductID       *int64  `json:"product_id"`
		Descricao       *string `json:"descricao"`
		Quantidade      float64 `json:"quantidade"`
		PrecoUnitario   float64 `json:"preco_unitario"`
		DescontoPercent float64 `json:"desconto_percent"`
		ImpostoPercent  float64 `json:"imposto_percent"`
		ImpostoValor    float64 `json:"imposto_valor"`
		Total           float64 `json:"total"`
	}
	items := []Item{}
	for rows.Next() {
		var i Item
		if rows.Scan(&i.ID, &i.ProductID, &i.Descricao, &i.Quantidade, &i.PrecoUnitario, &i.DescontoPercent, &i.ImpostoPercent, &i.ImpostoValor, &i.Total) == nil {
			items = append(items, i)
		}
	}
	jsonOK(w, map[string]any{"orcamento": o, "itens": items}, http.StatusOK)
}

func (h *Handler) AdicionarItemOrcamento(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		ProductID       *int64  `json:"product_id"`
		Descricao       *string `json:"descricao"`
		Quantidade      float64 `json:"quantidade"`
		PrecoUnitario   float64 `json:"preco_unitario"`
		DescontoPercent float64 `json:"desconto_percent"`
		ImpostoPercent  float64 `json:"imposto_percent"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Quantidade <= 0 || body.PrecoUnitario <= 0 {
		jsonErr(w, "quantidade e preco_unitario são obrigatórios", http.StatusBadRequest)
		return
	}
	subtotal := body.Quantidade * body.PrecoUnitario
	descontoValor := subtotal * body.DescontoPercent / 100
	impostoValor := (subtotal - descontoValor) * body.ImpostoPercent / 100
	total := subtotal - descontoValor + impostoValor
	var iid int64
	h.db.QueryRow(r.Context(), `
		INSERT INTO sales_quote_items (sales_quote_id, product_id, descricao, quantidade, preco_unitario,
		  desconto_percent, desconto_valor, imposto_percent, imposto_valor, subtotal, total)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING id`,
		id, body.ProductID, body.Descricao, body.Quantidade, body.PrecoUnitario,
		body.DescontoPercent, descontoValor, body.ImpostoPercent, impostoValor, subtotal-descontoValor, total).Scan(&iid)
	h.db.Exec(r.Context(), `UPDATE sales_quotes SET total=total+$1, imposto_total=imposto_total+$2 WHERE id=$3`, total, impostoValor, id)
	jsonOK(w, map[string]any{"id": iid, "total": total}, http.StatusCreated)
}

func (h *Handler) RemoverItemOrcamento(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	itemID := chi.URLParam(r, "itemId")
	var total, impostoValor float64
	h.db.QueryRow(r.Context(), `DELETE FROM sales_quote_items WHERE id=$1 AND sales_quote_id=$2 RETURNING total, imposto_valor`, itemID, id).Scan(&total, &impostoValor)
	h.db.Exec(r.Context(), `UPDATE sales_quotes SET total=total-$1, imposto_total=imposto_total-$2 WHERE id=$3`, total, impostoValor, id)
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) mudarStatusOrcamento(status string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user := mw.GetUser(r)
		id := chi.URLParam(r, "id")
		h.db.Exec(r.Context(), `UPDATE sales_quotes SET status=$1 WHERE id=$2 AND tenant_id=$3`, status, id, user.TenantID)
		w.WriteHeader(http.StatusNoContent)
	}
}
func (h *Handler) EnviarOrcamento(w http.ResponseWriter, r *http.Request)   { h.mudarStatusOrcamento("enviado")(w, r) }
func (h *Handler) AprovarOrcamento(w http.ResponseWriter, r *http.Request)  { h.mudarStatusOrcamento("aprovado")(w, r) }
func (h *Handler) RejeitarOrcamento(w http.ResponseWriter, r *http.Request) { h.mudarStatusOrcamento("rejeitado")(w, r) }

// ── Encomendas ────────────────────────────────────────────────────────────────

func (h *Handler) ListarEncomendas(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	for _, f := range []string{"status", "customer_id"} {
		if v := q.Get(f); v != "" {
			args = append(args, v)
			where += " AND " + f + "=$" + strconv.Itoa(len(args))
		}
	}
	args = append(args, limit, offset)
	n := len(args)
	rows, _ := h.db.Query(r.Context(),
		"SELECT id, numero, customer_id, status, total, moeda, created_at FROM sales_orders WHERE "+
			where+" ORDER BY created_at DESC LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n), args...)
	defer rows.Close()
	type Row struct {
		ID         int64     `json:"id"`
		Numero     string    `json:"numero"`
		CustomerID int64     `json:"customer_id"`
		Status     string    `json:"status"`
		Total      float64   `json:"total"`
		Moeda      string    `json:"moeda"`
		CreatedAt  time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var o Row
		if rows.Scan(&o.ID, &o.Numero, &o.CustomerID, &o.Status, &o.Total, &o.Moeda, &o.CreatedAt) == nil {
			data = append(data, o)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarEncomenda(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		CustomerID  int64   `json:"customer_id"`
		Moeda       *string `json:"moeda"`
		Observacoes *string `json:"observacoes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.CustomerID == 0 {
		jsonErr(w, "customer_id é obrigatório", http.StatusBadRequest)
		return
	}
	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	numero, serieID, err := proximoNumeroSerie(ctx, tx, user.TenantID, "ENC")
	if err != nil {
		jsonErr(w, "Não existe nenhuma série activa configurada para Encomendas. Configure em Faturação > Séries Documentais.", http.StatusUnprocessableEntity)
		return
	}

	var id int64
	err = tx.QueryRow(ctx, `
		INSERT INTO sales_orders (tenant_id, customer_id, numero, serie_id, moeda, observacoes)
		VALUES ($1,$2,$3,$4,COALESCE($5,'MZN'),$6) RETURNING id`,
		user.TenantID, body.CustomerID, numero, serieID, body.Moeda, body.Observacoes).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id, "numero": numero}, http.StatusCreated)
}

func (h *Handler) ConfirmarEncomenda(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	h.db.Exec(r.Context(), `UPDATE sales_orders SET status='confirmada' WHERE id=$1 AND tenant_id=$2 AND status='rascunho'`, id, user.TenantID)
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) CancelarEncomenda(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	h.db.Exec(r.Context(), `UPDATE sales_orders SET status='cancelada' WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	w.WriteHeader(http.StatusNoContent)
}

// ── Faturas ───────────────────────────────────────────────────────────────────

func (h *Handler) ListarFaturas(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	for _, f := range []string{"status", "customer_id"} {
		if v := q.Get(f); v != "" {
			args = append(args, v)
			where += " AND " + f + "=$" + strconv.Itoa(len(args))
		}
	}
	countArgs := make([]any, len(args))
	copy(countArgs, args)
	args = append(args, limit, offset)
	n := len(args)
	rows, _ := h.db.Query(r.Context(),
		"SELECT id, numero, customer_id, status, tipo, total, imposto_total, moeda, invoice_date, due_date FROM invoices WHERE "+
			where+" ORDER BY invoice_date DESC LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n), args...)
	defer rows.Close()
	type Row struct {
		ID           int64      `json:"id"`
		Numero       string     `json:"numero"`
		CustomerID   int64      `json:"customer_id"`
		Status       string     `json:"status"`
		Tipo         string     `json:"tipo"`
		Total        float64    `json:"total"`
		ImpostoTotal float64    `json:"imposto_total"`
		Moeda        string     `json:"moeda"`
		InvoiceDate  time.Time  `json:"invoice_date"`
		DueDate      *time.Time `json:"due_date"`
	}
	data := []Row{}
	for rows.Next() {
		var f Row
		if rows.Scan(&f.ID, &f.Numero, &f.CustomerID, &f.Status, &f.Tipo, &f.Total, &f.ImpostoTotal, &f.Moeda, &f.InvoiceDate, &f.DueDate) == nil {
			data = append(data, f)
		}
	}
	var total int
	h.db.QueryRow(r.Context(), "SELECT COUNT(*) FROM invoices WHERE "+where, countArgs...).Scan(&total)
	page, _ := strconv.Atoi(q.Get("page"))
	if page < 1 {
		page = 1
	}
	jsonOK(w, map[string]any{"data": data, "meta": map[string]int{"total": total, "page": page, "limit": limit}}, http.StatusOK)
}

func (h *Handler) CriarFatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		CustomerID  int64   `json:"customer_id"`
		Tipo        *string `json:"tipo"`
		Moeda       *string `json:"moeda"`
		DueDate     *string `json:"due_date"`
		Observacoes *string `json:"observacoes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.CustomerID == 0 {
		jsonErr(w, "customer_id é obrigatório", http.StatusBadRequest)
		return
	}
	tipo := "normal"
	if body.Tipo != nil && *body.Tipo != "" {
		tipo = *body.Tipo
	}
	if tipo != "normal" && tipo != "proforma" {
		jsonErr(w, "tipo é inválido", http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	var id int64
	var numero string

	if tipo == "normal" {
		var serieID int64
		numero, serieID, err = proximoNumeroSerie(ctx, tx, user.TenantID, "FT")
		if err != nil {
			jsonErr(w, "Não existe nenhuma série activa configurada para Faturas. Configure em Faturação > Séries Documentais.", http.StatusUnprocessableEntity)
			return
		}
		err = tx.QueryRow(ctx, `
			INSERT INTO invoices (tenant_id, customer_id, numero, serie_id, tipo, moeda, due_date, observacoes)
			VALUES ($1,$2,$3,$4,$5,COALESCE($6,'MZN'),$7::date,$8) RETURNING id`,
			user.TenantID, body.CustomerID, numero, serieID, tipo, body.Moeda, body.DueDate, body.Observacoes).Scan(&id)
	} else {
		err = tx.QueryRow(ctx, `
			INSERT INTO invoices (tenant_id, customer_id, numero, tipo, moeda, due_date, observacoes)
			VALUES ($1,$2,'',$3,COALESCE($4,'MZN'),$5::date,$6) RETURNING id`,
			user.TenantID, body.CustomerID, tipo, body.Moeda, body.DueDate, body.Observacoes).Scan(&id)
		if err == nil {
			numero = fmt.Sprintf("PRO-%d", id)
			_, err = tx.Exec(ctx, `UPDATE invoices SET numero=$1 WHERE id=$2`, numero, id)
		}
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id, "numero": numero}, http.StatusCreated)
}

func (h *Handler) ObterFatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var f struct {
		ID           int64      `json:"id"`
		Numero       string     `json:"numero"`
		CustomerID   int64      `json:"customer_id"`
		Status       string     `json:"status"`
		Tipo         string     `json:"tipo"`
		Total        float64    `json:"total"`
		ImpostoTotal float64    `json:"imposto_total"`
		Moeda        string     `json:"moeda"`
		InvoiceDate  time.Time  `json:"invoice_date"`
		DueDate      *time.Time `json:"due_date"`
		Observacoes  *string    `json:"observacoes"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, numero, customer_id, status, tipo, total, imposto_total, moeda, invoice_date, due_date, observacoes
		  FROM invoices WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).
		Scan(&f.ID, &f.Numero, &f.CustomerID, &f.Status, &f.Tipo, &f.Total, &f.ImpostoTotal,
			&f.Moeda, &f.InvoiceDate, &f.DueDate, &f.Observacoes)
	if err != nil {
		jsonErr(w, "Fatura não encontrada", http.StatusNotFound)
		return
	}
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, product_id, descricao, quantidade, preco_unitario, desconto_percent, imposto_percent, imposto_valor, total
		  FROM invoice_items WHERE invoice_id=$1 ORDER BY id`, id)
	defer rows.Close()
	type Item struct {
		ID              int64   `json:"id"`
		ProductID       *int64  `json:"product_id"`
		Descricao       *string `json:"descricao"`
		Quantidade      float64 `json:"quantidade"`
		PrecoUnitario   float64 `json:"preco_unitario"`
		DescontoPercent float64 `json:"desconto_percent"`
		ImpostoPercent  float64 `json:"imposto_percent"`
		ImpostoValor    float64 `json:"imposto_valor"`
		Total           float64 `json:"total"`
	}
	items := []Item{}
	for rows.Next() {
		var i Item
		if rows.Scan(&i.ID, &i.ProductID, &i.Descricao, &i.Quantidade, &i.PrecoUnitario, &i.DescontoPercent, &i.ImpostoPercent, &i.ImpostoValor, &i.Total) == nil {
			items = append(items, i)
		}
	}
	jsonOK(w, map[string]any{"fatura": f, "itens": items}, http.StatusOK)
}

func (h *Handler) AdicionarItemFatura(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		ProductID       *int64  `json:"product_id"`
		Descricao       *string `json:"descricao"`
		Quantidade      float64 `json:"quantidade"`
		PrecoUnitario   float64 `json:"preco_unitario"`
		DescontoPercent float64 `json:"desconto_percent"`
		ImpostoPercent  float64 `json:"imposto_percent"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Quantidade <= 0 || body.PrecoUnitario <= 0 {
		jsonErr(w, "quantidade e preco_unitario são obrigatórios", http.StatusBadRequest)
		return
	}
	subtotal := body.Quantidade * body.PrecoUnitario
	descontoValor := subtotal * body.DescontoPercent / 100
	impostoValor := (subtotal - descontoValor) * body.ImpostoPercent / 100
	total := subtotal - descontoValor + impostoValor
	var iid int64
	h.db.QueryRow(r.Context(), `
		INSERT INTO invoice_items (invoice_id, product_id, descricao, quantidade, preco_unitario,
		  desconto_percent, desconto_valor, imposto_percent, imposto_valor, subtotal, total)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING id`,
		id, body.ProductID, body.Descricao, body.Quantidade, body.PrecoUnitario,
		body.DescontoPercent, descontoValor, body.ImpostoPercent, impostoValor, subtotal-descontoValor, total).Scan(&iid)
	h.db.Exec(r.Context(), `UPDATE invoices SET total=total+$1, imposto_total=imposto_total+$2 WHERE id=$3`, total, impostoValor, id)
	jsonOK(w, map[string]any{"id": iid, "total": total, "imposto_valor": impostoValor}, http.StatusCreated)
}

func (h *Handler) EmitirFatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	h.db.Exec(r.Context(), `UPDATE invoices SET status='emitida', emitida_em=NOW() WHERE id=$1 AND tenant_id=$2 AND status='rascunho'`, id, user.TenantID)
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) CancelarFatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	h.db.Exec(r.Context(), `UPDATE invoices SET status='cancelada' WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	w.WriteHeader(http.StatusNoContent)
}

// ── Recibos ───────────────────────────────────────────────────────────────────

func (h *Handler) ListarRecibos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	limit, offset := pageParams(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, numero, invoice_id, valor, payment_date, status
		  FROM invoice_receipts WHERE tenant_id=$1 ORDER BY payment_date DESC LIMIT $2 OFFSET $3`,
		user.TenantID, limit, offset)
	defer rows.Close()
	type Row struct {
		ID          int64     `json:"id"`
		Numero      string    `json:"numero"`
		InvoiceID   int64     `json:"invoice_id"`
		Valor       float64   `json:"valor"`
		PaymentDate time.Time `json:"payment_date"`
		Status      string    `json:"status"`
	}
	data := []Row{}
	for rows.Next() {
		var rec Row
		if rows.Scan(&rec.ID, &rec.Numero, &rec.InvoiceID, &rec.Valor, &rec.PaymentDate, &rec.Status) == nil {
			data = append(data, rec)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarRecibo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		InvoiceID       int64   `json:"invoice_id"`
		Valor           float64 `json:"valor"`
		PaymentMethodID *int64  `json:"payment_method_id"`
		Referencia      *string `json:"referencia"`
		Observacoes     *string `json:"observacoes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.InvoiceID == 0 || body.Valor <= 0 {
		jsonErr(w, "invoice_id e valor são obrigatórios", http.StatusBadRequest)
		return
	}
	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	numero, serieID, err := proximoNumeroSerie(ctx, tx, user.TenantID, "RB")
	if err != nil {
		jsonErr(w, "Não existe nenhuma série activa configurada para Recibos. Configure em Faturação > Séries Documentais.", http.StatusUnprocessableEntity)
		return
	}

	var id int64
	err = tx.QueryRow(ctx, `
		INSERT INTO invoice_receipts (tenant_id, invoice_id, numero, serie_id, valor, payment_method_id, referencia, observacoes)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
		user.TenantID, body.InvoiceID, numero, serieID, body.Valor, body.PaymentMethodID, body.Referencia, body.Observacoes).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if _, err := tx.Exec(ctx, `UPDATE invoices SET valor_pago=valor_pago+$1 WHERE id=$2`, body.Valor, body.InvoiceID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id, "numero": numero}, http.StatusCreated)
}

// ── Notas de Crédito ──────────────────────────────────────────────────────────

func (h *Handler) ListarNotasCredito(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	limit, offset := pageParams(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, numero, invoice_id, customer_id, total, moeda, status, created_at
		  FROM credit_notes WHERE tenant_id=$1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`,
		user.TenantID, limit, offset)
	defer rows.Close()
	type Row struct {
		ID         int64     `json:"id"`
		Numero     string    `json:"numero"`
		InvoiceID  *int64    `json:"invoice_id"`
		CustomerID int64     `json:"customer_id"`
		Total      float64   `json:"total"`
		Moeda      string    `json:"moeda"`
		Status     string    `json:"status"`
		CreatedAt  time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var n Row
		if rows.Scan(&n.ID, &n.Numero, &n.InvoiceID, &n.CustomerID, &n.Total, &n.Moeda, &n.Status, &n.CreatedAt) == nil {
			data = append(data, n)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarNotaCredito(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		InvoiceID   *int64  `json:"invoice_id"`
		CustomerID  int64   `json:"customer_id"`
		Motivo      string  `json:"motivo"`
		Moeda       *string `json:"moeda"`
		Observacoes *string `json:"observacoes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.CustomerID == 0 || body.Motivo == "" {
		jsonErr(w, "customer_id e motivo são obrigatórios", http.StatusBadRequest)
		return
	}
	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	numero, serieID, err := proximoNumeroSerie(ctx, tx, user.TenantID, "NC")
	if err != nil {
		jsonErr(w, "Não existe nenhuma série activa configurada para Notas de Crédito. Configure em Faturação > Séries Documentais.", http.StatusUnprocessableEntity)
		return
	}

	var id int64
	err = tx.QueryRow(ctx, `
		INSERT INTO credit_notes (tenant_id, invoice_id, customer_id, numero, serie_id, motivo, moeda, observacoes)
		VALUES ($1,$2,$3,$4,$5,$6,COALESCE($7,'MZN'),$8) RETURNING id`,
		user.TenantID, body.InvoiceID, body.CustomerID, numero, serieID, body.Motivo, body.Moeda, body.Observacoes).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id, "numero": numero}, http.StatusCreated)
}
