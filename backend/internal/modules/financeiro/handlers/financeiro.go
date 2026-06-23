package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) listAll(w http.ResponseWriter, r *http.Request, query string, args ...any) {
	var raw []byte
	if err := h.db.QueryRow(r.Context(), query, args...).Scan(&raw); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

func finFilter(r *http.Request, where *string, args *[]any, key, col string) {
	v := strings.TrimSpace(r.URL.Query().Get(key))
	if v == "" {
		return
	}
	*args = append(*args, v)
	*where += " AND " + col + "=$" + strconv.Itoa(len(*args))
}

// ── Categorias ──────────────────────────────────────────────────

func (h *Handler) ListarCategorias(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.codigo),'[]') FROM (
		SELECT * FROM financeiro.financial_categories WHERE tenant_id=$1 AND ativo) x`, u.TenantID)
}

func (h *Handler) CriarCategoria(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		Nome     string  `json:"nome"`
		Tipo     string  `json:"tipo"`
		Codigo   *string `json:"codigo"`
		ParentID *int64  `json:"parent_id"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Nome == "" || b.Tipo == "" {
		jsonErr(w, "nome e tipo sao obrigatorios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO financeiro.financial_categories
		(tenant_id,parent_id,codigo,nome,tipo) VALUES ($1,$2,$3,$4,$5) RETURNING id`,
		u.TenantID, b.ParentID, b.Codigo, b.Nome, b.Tipo).Scan(&id)
	if err != nil {
		jsonErr(w, "Categoria invalida ou duplicada", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ── Métodos de pagamento ─────────────────────────────────────────

func (h *Handler) ListarMetodosPagamento(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome),'[]') FROM (
		SELECT * FROM financeiro.payment_methods WHERE tenant_id=$1 AND ativo) x`, u.TenantID)
}

func (h *Handler) CriarMetodoPagamento(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		Codigo string `json:"codigo"`
		Nome   string `json:"nome"`
		Tipo   string `json:"tipo"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Codigo == "" || b.Nome == "" {
		jsonErr(w, "codigo e nome sao obrigatorios", http.StatusBadRequest)
		return
	}
	if b.Tipo == "" {
		b.Tipo = "outro"
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO financeiro.payment_methods
		(tenant_id,codigo,nome,tipo) VALUES ($1,$2,$3,$4) RETURNING id`,
		u.TenantID, b.Codigo, b.Nome, b.Tipo).Scan(&id)
	if err != nil {
		jsonErr(w, "Metodo duplicado ou invalido", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ── Contas a Receber ─────────────────────────────────────────────

func (h *Handler) ListarContasAReceber(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "tenant_id=$1"
	args := []any{u.TenantID}
	finFilter(r, &where, &args, "status", "status")
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.data_vencimento),'[]') FROM (
		SELECT * FROM financeiro.accounts_receivable WHERE `+where+`) x`, args...)
}

func (h *Handler) CriarContaAReceber(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		Numero              string  `json:"numero"`
		CustomerID          int64   `json:"customer_id"`
		ValorTotal          float64 `json:"valor_total"`
		DataEmissao         string  `json:"data_emissao"`
		DataVencimento      string  `json:"data_vencimento"`
		Descricao           *string `json:"descricao"`
		FinancialCategoryID *int64  `json:"financial_category_id"`
		OrigemTipo          *string `json:"origem_tipo"`
		OrigemID            *int64  `json:"origem_id"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Numero == "" || b.CustomerID == 0 || b.ValorTotal <= 0 || b.DataVencimento == "" {
		jsonErr(w, "numero, customer_id, valor_total e data_vencimento sao obrigatorios", http.StatusBadRequest)
		return
	}
	if b.DataEmissao == "" {
		b.DataEmissao = "today"
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO financeiro.accounts_receivable
		(tenant_id,numero,customer_id,financial_category_id,origem_tipo,origem_id,descricao,valor_total,data_emissao,data_vencimento)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,COALESCE(NULLIF($9,'')::date,CURRENT_DATE),$10::date) RETURNING id`,
		u.TenantID, b.Numero, b.CustomerID, b.FinancialCategoryID, b.OrigemTipo, b.OrigemID,
		b.Descricao, b.ValorTotal, b.DataEmissao, b.DataVencimento).Scan(&id)
	if err != nil {
		jsonErr(w, "Numero duplicado ou dados invalidos", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) RegistarPagamentoAReceber(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var b struct {
		Valor          float64 `json:"valor"`
		DataPagamento  string  `json:"data_pagamento"`
		PaymentMethodID *int64 `json:"payment_method_id"`
		Referencia     *string `json:"referencia"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Valor <= 0 {
		jsonErr(w, "valor e obrigatorio", http.StatusBadRequest)
		return
	}
	if b.DataPagamento == "" {
		b.DataPagamento = "today"
	}
	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())
	var payID int64
	err = tx.QueryRow(r.Context(), `INSERT INTO financeiro.payments
		(tenant_id,numero,payment_method_id,tipo,data_pagamento,valor,referencia_tipo,referencia_id,criado_por)
		SELECT $1,'PAG-'||nextval('financeiro.payments_id_seq'),$2,'recebimento',
		COALESCE(NULLIF($3,'')::date,CURRENT_DATE),$4,'accounts_receivable',$5,$6 RETURNING id`,
		u.TenantID, b.PaymentMethodID, b.DataPagamento, b.Valor, id, u.ID).Scan(&payID)
	if err != nil {
		jsonErr(w, "Erro ao registar pagamento", http.StatusUnprocessableEntity)
		return
	}
	_, err = tx.Exec(r.Context(), `UPDATE financeiro.accounts_receivable
		SET valor_pago=valor_pago+$1,
		    valor_pendente=GREATEST(0,valor_total-valor_pago-$1),
		    status=CASE WHEN valor_pago+$1>=valor_total THEN 'pago' ELSE 'parcial' END
		WHERE id=$2 AND tenant_id=$3`, b.Valor, id, u.TenantID)
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro ao actualizar conta", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": payID}, http.StatusCreated)
}

// ── Contas a Pagar ───────────────────────────────────────────────

func (h *Handler) ListarContasAPagar(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "tenant_id=$1"
	args := []any{u.TenantID}
	finFilter(r, &where, &args, "status", "status")
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.data_vencimento),'[]') FROM (
		SELECT * FROM financeiro.accounts_payable WHERE `+where+`) x`, args...)
}

func (h *Handler) CriarContaAPagar(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		Numero              string  `json:"numero"`
		SupplierID          *int64  `json:"supplier_id"`
		ValorTotal          float64 `json:"valor_total"`
		DataEmissao         string  `json:"data_emissao"`
		DataVencimento      string  `json:"data_vencimento"`
		Descricao           *string `json:"descricao"`
		FinancialCategoryID *int64  `json:"financial_category_id"`
		OrigemTipo          *string `json:"origem_tipo"`
		OrigemID            *int64  `json:"origem_id"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Numero == "" || b.ValorTotal <= 0 || b.DataVencimento == "" {
		jsonErr(w, "numero, valor_total e data_vencimento sao obrigatorios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO financeiro.accounts_payable
		(tenant_id,numero,supplier_id,financial_category_id,origem_tipo,origem_id,descricao,valor_total,data_emissao,data_vencimento)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,COALESCE(NULLIF($9,'')::date,CURRENT_DATE),$10::date) RETURNING id`,
		u.TenantID, b.Numero, b.SupplierID, b.FinancialCategoryID, b.OrigemTipo, b.OrigemID,
		b.Descricao, b.ValorTotal, b.DataEmissao, b.DataVencimento).Scan(&id)
	if err != nil {
		jsonErr(w, "Numero duplicado ou dados invalidos", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) RegistarPagamentoAPagar(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var b struct {
		Valor           float64 `json:"valor"`
		DataPagamento   string  `json:"data_pagamento"`
		PaymentMethodID *int64  `json:"payment_method_id"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Valor <= 0 {
		jsonErr(w, "valor e obrigatorio", http.StatusBadRequest)
		return
	}
	if b.DataPagamento == "" {
		b.DataPagamento = "today"
	}
	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())
	var payID int64
	err = tx.QueryRow(r.Context(), `INSERT INTO financeiro.payments
		(tenant_id,numero,payment_method_id,tipo,data_pagamento,valor,referencia_tipo,referencia_id,criado_por)
		SELECT $1,'PAG-'||nextval('financeiro.payments_id_seq'),$2,'pagamento',
		COALESCE(NULLIF($3,'')::date,CURRENT_DATE),$4,'accounts_payable',$5,$6 RETURNING id`,
		u.TenantID, b.PaymentMethodID, b.DataPagamento, b.Valor, id, u.ID).Scan(&payID)
	if err != nil {
		jsonErr(w, "Erro ao registar pagamento", http.StatusUnprocessableEntity)
		return
	}
	_, err = tx.Exec(r.Context(), `UPDATE financeiro.accounts_payable
		SET valor_pago=valor_pago+$1,
		    valor_pendente=GREATEST(0,valor_total-valor_pago-$1),
		    status=CASE WHEN valor_pago+$1>=valor_total THEN 'pago' ELSE 'parcial' END
		WHERE id=$2 AND tenant_id=$3`, b.Valor, id, u.TenantID)
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro ao actualizar conta", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": payID}, http.StatusCreated)
}

// ── Cash Flow ────────────────────────────────────────────────────

func (h *Handler) ListarCashFlow(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "tenant_id=$1"
	args := []any{u.TenantID}
	finFilter(r, &where, &args, "tipo", "tipo")
	finFilter(r, &where, &args, "origem", "origem")
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.data DESC),'[]') FROM (
		SELECT * FROM financeiro.cash_flow_entries WHERE `+where+`) x`, args...)
}
