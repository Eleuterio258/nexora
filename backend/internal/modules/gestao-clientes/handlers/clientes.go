package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// â”€â”€ Grupos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func (h *Handler) ListarGrupos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, codigo, nome, descricao, ativo FROM customer_groups
		 WHERE tenant_id=$1 ORDER BY nome`, user.TenantID)
	defer rows.Close()
	type Row struct {
		ID        int64   `json:"id"`
		Codigo    string  `json:"codigo"`
		Nome      string  `json:"nome"`
		Descricao *string `json:"descricao"`
		Ativo     bool    `json:"ativo"`
	}
	data := []Row{}
	for rows.Next() {
		var g Row
		if rows.Scan(&g.ID, &g.Codigo, &g.Nome, &g.Descricao, &g.Ativo) == nil {
			data = append(data, g)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarGrupo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo    string  `json:"codigo"`
		Nome      string  `json:"nome"`
		Descricao *string `json:"descricao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome sÃ£o obrigatÃ³rios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO customer_groups (tenant_id, codigo, nome, descricao) VALUES ($1,$2,$3,$4) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Descricao).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "CÃ³digo jÃ¡ existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarGrupo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Nome      *string `json:"nome"`
		Descricao *string `json:"descricao"`
		Ativo     *bool   `json:"ativo"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	h.db.Exec(r.Context(), `UPDATE customer_groups SET nome=COALESCE($1,nome), descricao=COALESCE($2,descricao), ativo=COALESCE($3,ativo) WHERE id=$4 AND tenant_id=$5`,
		body.Nome, body.Descricao, body.Ativo, id, user.TenantID)
	w.WriteHeader(http.StatusNoContent)
}

// â”€â”€ Clientes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func (h *Handler) ListarClientes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)
	where := "tenant_id=$1"
	args := []any{user.TenantID}

	if s := q.Get("status"); s != "" {
		args = append(args, s)
		where += " AND estado=$" + strconv.Itoa(len(args))
	}
	if g := q.Get("grupo_id"); g != "" {
		args = append(args, g)
		where += " AND customer_group_id=$" + strconv.Itoa(len(args))
	}
	if s := q.Get("search"); s != "" {
		args = append(args, "%"+s+"%")
		n := strconv.Itoa(len(args))
		where += " AND (nome ILIKE $" + n + " OR email ILIKE $" + n + " OR nuit ILIKE $" + n + ")"
	}
	countArgs := make([]any, len(args))
	copy(countArgs, args)
	args = append(args, limit, offset)
	n := len(args)

	rows, err := h.db.Query(r.Context(),
		"SELECT id, codigo, nome, nuit, email, telefone, estado, customer_group_id, created_at FROM customers WHERE "+
			where+" ORDER BY nome LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n), args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID              int64     `json:"id"`
		Codigo          *string   `json:"codigo"`
		Nome            string    `json:"nome"`
		Nuit            *string   `json:"nuit"`
		Email           *string   `json:"email"`
		Telefone        *string   `json:"telefone"`
		Estado          string    `json:"estado"`
		CustomerGroupID *int64    `json:"customer_group_id"`
		CreatedAt       time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var c Row
		if rows.Scan(&c.ID, &c.Codigo, &c.Nome, &c.Nuit, &c.Email, &c.Telefone, &c.Estado, &c.CustomerGroupID, &c.CreatedAt) == nil {
			data = append(data, c)
		}
	}
	var total int
	h.db.QueryRow(r.Context(), "SELECT COUNT(*) FROM customers WHERE "+where, countArgs...).Scan(&total)
	page, _ := strconv.Atoi(q.Get("page"))
	if page < 1 {
		page = 1
	}
	jsonOK(w, map[string]any{"data": data, "meta": map[string]int{"total": total, "page": page, "limit": limit}}, http.StatusOK)
}

func (h *Handler) CriarCliente(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo          *string `json:"codigo"`
		Nome            string  `json:"nome"`
		Nuit            *string `json:"nuit"`
		Email           *string `json:"email"`
		Telefone        *string `json:"telefone"`
		CustomerGroupID *int64  `json:"customer_group_id"`
		Observacao      *string `json:"observacao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Nome == "" {
		jsonErr(w, "nome Ã© obrigatÃ³rio", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO customers (tenant_id, codigo, nome, nuit, email, telefone, customer_group_id, observacao)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Nuit, body.Email, body.Telefone, body.CustomerGroupID, body.Observacao).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "CÃ³digo ou NUIT jÃ¡ existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterCliente(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var c struct {
		ID              int64     `json:"id"`
		Codigo          *string   `json:"codigo"`
		Nome            string    `json:"nome"`
		Nuit            *string   `json:"nuit"`
		Email           *string   `json:"email"`
		Telefone        *string   `json:"telefone"`
		Estado          string    `json:"estado"`
		CustomerGroupID *int64    `json:"customer_group_id"`
		Observacao      *string   `json:"observacao"`
		CreatedAt       time.Time `json:"created_at"`
		UpdatedAt       time.Time `json:"updated_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, codigo, nome, nuit, email, telefone, estado, customer_group_id, observacao, created_at, updated_at
		  FROM customers WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).
		Scan(&c.ID, &c.Codigo, &c.Nome, &c.Nuit, &c.Email, &c.Telefone, &c.Estado, &c.CustomerGroupID, &c.Observacao, &c.CreatedAt, &c.UpdatedAt)
	if err != nil {
		jsonErr(w, "Cliente nÃ£o encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, c, http.StatusOK)
}

func (h *Handler) ActualizarCliente(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Nome            *string `json:"nome"`
		Email           *string `json:"email"`
		Telefone        *string `json:"telefone"`
		CustomerGroupID *int64  `json:"customer_group_id"`
		Observacao      *string `json:"observacao"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	tag, _ := h.db.Exec(r.Context(), `
		UPDATE customers SET nome=COALESCE($1,nome), email=COALESCE($2,email), telefone=COALESCE($3,telefone),
		  customer_group_id=COALESCE($4,customer_group_id), observacao=COALESCE($5,observacao), updated_at=NOW()
		WHERE id=$6 AND tenant_id=$7`,
		body.Nome, body.Email, body.Telefone, body.CustomerGroupID, body.Observacao, id, user.TenantID)
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Cliente nÃ£o encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) mudarEstadoCliente(estado string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user := mw.GetUser(r)
		id := chi.URLParam(r, "id")
		tag, _ := h.db.Exec(r.Context(), `UPDATE customers SET estado=$1, updated_at=NOW() WHERE id=$2 AND tenant_id=$3`, estado, id, user.TenantID)
		if tag.RowsAffected() == 0 {
			jsonErr(w, "Cliente nÃ£o encontrado", http.StatusNotFound)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

func (h *Handler) ActivarCliente(w http.ResponseWriter, r *http.Request) {
	h.mudarEstadoCliente("ativo")(w, r)
}
func (h *Handler) BloquearCliente(w http.ResponseWriter, r *http.Request) {
	h.mudarEstadoCliente("bloqueado")(w, r)
}
func (h *Handler) DesbloquearCliente(w http.ResponseWriter, r *http.Request) {
	h.mudarEstadoCliente("ativo")(w, r)
}
