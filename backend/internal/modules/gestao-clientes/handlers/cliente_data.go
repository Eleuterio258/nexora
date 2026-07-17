package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/shared/pessoas"
)

// tenantOwnsCustomer verifica que o customer pertence ao tenant antes de operar.
func (h *Handler) tenantOwnsCustomer(r *http.Request, customerID string, tenantID int64) bool {
	var exists bool
	h.db.QueryRow(r.Context(),
		`SELECT EXISTS(SELECT 1 FROM customers WHERE id=$1 AND tenant_id=$2)`,
		customerID, tenantID).Scan(&exists)
	return exists
}

// ── Contactos ─────────────────────────────────────────────────────────────────

func (h *Handler) ListarContactos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	rows, err := h.db.Query(r.Context(), `
		SELECT cc.id, cc.nome, cc.cargo, cc.telefone, cc.email, cc.principal
		  FROM customer_contacts cc
		  JOIN customers c ON c.id = cc.customer_id AND c.tenant_id = $2
		 WHERE cc.customer_id = $1
		 ORDER BY cc.principal DESC, cc.nome`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID        int64   `json:"id"`
		Nome      string  `json:"nome"`
		Cargo     *string `json:"cargo"`
		Telefone  *string `json:"telefone"`
		Email     *string `json:"email"`
		Principal bool    `json:"principal"`
	}
	data := []Row{}
	for rows.Next() {
		var c Row
		if rows.Scan(&c.ID, &c.Nome, &c.Cargo, &c.Telefone, &c.Email, &c.Principal) == nil {
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) AdicionarContacto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	if !h.tenantOwnsCustomer(r, id, user.TenantID) {
		jsonErr(w, "Cliente não encontrado", http.StatusNotFound)
		return
	}
	var body struct {
		Nome      string  `json:"nome"`
		Cargo     *string `json:"cargo"`
		Telefone  *string `json:"telefone"`
		Email     *string `json:"email"`
		Principal bool    `json:"principal"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Nome == "" {
		jsonErr(w, "nome é obrigatório", http.StatusBadRequest)
		return
	}
	var pessoaID *int64
	if pid, err := pessoas.EnsurePessoa(r.Context(), h.db, body.Nome); err == nil {
		pessoaID = &pid
	}

	var cid int64
	h.db.QueryRow(r.Context(),
		`INSERT INTO customer_contacts (customer_id,nome,cargo,telefone,email,principal,pessoa_id) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id`,
		id, body.Nome, body.Cargo, body.Telefone, body.Email, body.Principal, pessoaID).Scan(&cid)
	jsonOK(w, map[string]any{"id": cid}, http.StatusCreated)
}

func (h *Handler) ActualizarContacto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	if !h.tenantOwnsCustomer(r, id, user.TenantID) {
		jsonErr(w, "Cliente não encontrado", http.StatusNotFound)
		return
	}
	var body struct {
		Nome      *string `json:"nome"`
		Cargo     *string `json:"cargo"`
		Telefone  *string `json:"telefone"`
		Email     *string `json:"email"`
		Principal *bool   `json:"principal"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	h.db.Exec(r.Context(),
		`UPDATE customer_contacts SET nome=COALESCE($1,nome), cargo=COALESCE($2,cargo),
		 telefone=COALESCE($3,telefone), email=COALESCE($4,email), principal=COALESCE($5,principal)
		 WHERE id=$6 AND customer_id=$7`,
		body.Nome, body.Cargo, body.Telefone, body.Email, body.Principal,
		chi.URLParam(r, "contactoId"), id)
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverContacto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	if !h.tenantOwnsCustomer(r, id, user.TenantID) {
		jsonErr(w, "Cliente não encontrado", http.StatusNotFound)
		return
	}
	h.db.Exec(r.Context(),
		`DELETE FROM customer_contacts WHERE id=$1 AND customer_id=$2`,
		chi.URLParam(r, "contactoId"), id)
	w.WriteHeader(http.StatusNoContent)
}

// ── Endereços ─────────────────────────────────────────────────────────────────

func (h *Handler) ListarEnderecos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	rows, err := h.db.Query(r.Context(), `
		SELECT ca.id, ca.tipo, ca.pais, ca.provincia, ca.cidade, ca.endereco, ca.codigo_postal, ca.principal
		  FROM customer_addresses ca
		  JOIN customers c ON c.id = ca.customer_id AND c.tenant_id = $2
		 WHERE ca.customer_id = $1
		 ORDER BY ca.principal DESC`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID           int64   `json:"id"`
		Tipo         string  `json:"tipo"`
		Pais         string  `json:"pais"`
		Provincia    *string `json:"provincia"`
		Cidade       *string `json:"cidade"`
		Endereco     string  `json:"endereco"`
		CodigoPostal *string `json:"codigo_postal"`
		Principal    bool    `json:"principal"`
	}
	data := []Row{}
	for rows.Next() {
		var a Row
		if rows.Scan(&a.ID, &a.Tipo, &a.Pais, &a.Provincia, &a.Cidade, &a.Endereco, &a.CodigoPostal, &a.Principal) == nil {
			data = append(data, a)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) AdicionarEndereco(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	if !h.tenantOwnsCustomer(r, id, user.TenantID) {
		jsonErr(w, "Cliente não encontrado", http.StatusNotFound)
		return
	}
	var body struct {
		Tipo         *string `json:"tipo"`
		Pais         *string `json:"pais"`
		Provincia    *string `json:"provincia"`
		Cidade       *string `json:"cidade"`
		Endereco     string  `json:"endereco"`
		CodigoPostal *string `json:"codigo_postal"`
		Principal    bool    `json:"principal"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Endereco == "" {
		jsonErr(w, "endereco é obrigatório", http.StatusBadRequest)
		return
	}
	var eid int64
	h.db.QueryRow(r.Context(),
		`INSERT INTO customer_addresses (customer_id,tipo,pais,provincia,cidade,endereco,codigo_postal,principal)
		 VALUES ($1,COALESCE($2,'principal'),COALESCE($3,'Mocambique'),$4,$5,$6,$7,$8) RETURNING id`,
		id, body.Tipo, body.Pais, body.Provincia, body.Cidade, body.Endereco, body.CodigoPostal, body.Principal).Scan(&eid)
	jsonOK(w, map[string]any{"id": eid}, http.StatusCreated)
}

func (h *Handler) ActualizarEndereco(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	if !h.tenantOwnsCustomer(r, id, user.TenantID) {
		jsonErr(w, "Cliente não encontrado", http.StatusNotFound)
		return
	}
	var body struct {
		Endereco  *string `json:"endereco"`
		Cidade    *string `json:"cidade"`
		Provincia *string `json:"provincia"`
		Principal *bool   `json:"principal"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	h.db.Exec(r.Context(),
		`UPDATE customer_addresses SET endereco=COALESCE($1,endereco), cidade=COALESCE($2,cidade),
		 provincia=COALESCE($3,provincia), principal=COALESCE($4,principal)
		 WHERE id=$5 AND customer_id=$6`,
		body.Endereco, body.Cidade, body.Provincia, body.Principal,
		chi.URLParam(r, "endId"), id)
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverEndereco(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	if !h.tenantOwnsCustomer(r, id, user.TenantID) {
		jsonErr(w, "Cliente não encontrado", http.StatusNotFound)
		return
	}
	h.db.Exec(r.Context(),
		`DELETE FROM customer_addresses WHERE id=$1 AND customer_id=$2`,
		chi.URLParam(r, "endId"), id)
	w.WriteHeader(http.StatusNoContent)
}

// ── Crédito e Saldo ───────────────────────────────────────────────────────────

func (h *Handler) ObterLimiteCredito(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var c struct {
		Nome   string  `json:"nome"`
		Estado string  `json:"estado"`
		Nuit   *string `json:"nuit"`
	}
	h.db.QueryRow(r.Context(),
		`SELECT nome, estado, nuit FROM customers WHERE id=$1 AND tenant_id=$2`,
		id, user.TenantID).Scan(&c.Nome, &c.Estado, &c.Nuit)
	jsonOK(w, c, http.StatusOK)
}

func (h *Handler) ActualizarLimiteCredito(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	if !h.tenantOwnsCustomer(r, id, user.TenantID) {
		jsonErr(w, "Cliente não encontrado", http.StatusNotFound)
		return
	}
	var body struct {
		Limite float64 `json:"limite"`
		Motivo string  `json:"motivo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Motivo == "" {
		jsonErr(w, "limite e motivo são obrigatórios", http.StatusBadRequest)
		return
	}
	h.db.Exec(r.Context(), `
		INSERT INTO customer_credit_limits (customer_id, limite, motivo) VALUES ($1,$2,$3)
		ON CONFLICT (customer_id) DO UPDATE SET limite=$2, motivo=$3, updated_at=NOW()`,
		id, body.Limite, body.Motivo)
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ObterSaldo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var s struct {
		SaldoDevedor      *float64   `json:"saldo_devedor"`
		TotalCompras      *float64   `json:"total_compras"`
		TotalPago         *float64   `json:"total_pago"`
		UltimaCompraEm    *time.Time `json:"ultima_compra_em"`
		UltimoPagamentoEm *time.Time `json:"ultimo_pagamento_em"`
	}
	h.db.QueryRow(r.Context(), `
		SELECT cb.saldo_devedor, cb.total_compras, cb.total_pago,
		       cb.ultima_compra_em, cb.ultimo_pagamento_em
		  FROM customer_balances cb
		  JOIN customers c ON c.id = cb.customer_id AND c.tenant_id = $2
		 WHERE cb.customer_id = $1`, id, user.TenantID).
		Scan(&s.SaldoDevedor, &s.TotalCompras, &s.TotalPago, &s.UltimaCompraEm, &s.UltimoPagamentoEm)
	jsonOK(w, s, http.StatusOK)
}

// ── Pagamentos ────────────────────────────────────────────────────────────────

func (h *Handler) ListarPagamentos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	limit, offset := pageParams(r)
	rows, err := h.db.Query(r.Context(), `
		SELECT cp.id, cp.metodo, cp.valor, cp.referencia, cp.pago_em
		  FROM customer_payments cp
		  JOIN customers c ON c.id = cp.customer_id AND c.tenant_id = $2
		 WHERE cp.customer_id = $1
		 ORDER BY cp.pago_em DESC LIMIT $3 OFFSET $4`, id, user.TenantID, limit, offset)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID         int64     `json:"id"`
		Metodo     string    `json:"metodo"`
		Valor      float64   `json:"valor"`
		Referencia *string   `json:"referencia"`
		PagoEm     time.Time `json:"pago_em"`
	}
	data := []Row{}
	for rows.Next() {
		var p Row
		if rows.Scan(&p.ID, &p.Metodo, &p.Valor, &p.Referencia, &p.PagoEm) == nil {
			data = append(data, p)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) RegistarPagamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	if !h.tenantOwnsCustomer(r, id, user.TenantID) {
		jsonErr(w, "Cliente não encontrado", http.StatusNotFound)
		return
	}
	var body struct {
		Metodo     string  `json:"metodo"`
		Valor      float64 `json:"valor"`
		Referencia *string `json:"referencia"`
		Observacao *string `json:"observacao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Valor <= 0 || body.Metodo == "" {
		jsonErr(w, "metodo e valor são obrigatórios", http.StatusBadRequest)
		return
	}
	var pid int64
	h.db.QueryRow(r.Context(),
		`INSERT INTO customer_payments (tenant_id,customer_id,metodo,valor,referencia,observacao) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		user.TenantID, id, body.Metodo, body.Valor, body.Referencia, body.Observacao).Scan(&pid)
	jsonOK(w, map[string]any{"id": pid}, http.StatusCreated)
}

// ── Histórico ─────────────────────────────────────────────────────────────────

func (h *Handler) ListarHistorico(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	limit, offset := pageParams(r)
	rows, err := h.db.Query(r.Context(), `
		SELECT ch.id, ch.evento, ch.descricao, ch.referencia_tipo, ch.referencia_id, ch.created_at
		  FROM customer_history ch
		  JOIN customers c ON c.id = ch.customer_id AND c.tenant_id = $2
		 WHERE ch.customer_id = $1
		 ORDER BY ch.created_at DESC LIMIT $3 OFFSET $4`, id, user.TenantID, limit, offset)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID             int64     `json:"id"`
		Evento         string    `json:"evento"`
		Descricao      *string   `json:"descricao"`
		ReferenciaTipo *string   `json:"referencia_tipo"`
		ReferenciaID   *int64    `json:"referencia_id"`
		CreatedAt      time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var e Row
		if rows.Scan(&e.ID, &e.Evento, &e.Descricao, &e.ReferenciaTipo, &e.ReferenciaID, &e.CreatedAt) == nil {
			data = append(data, e)
		}
	}
	jsonOK(w, data, http.StatusOK)
}
