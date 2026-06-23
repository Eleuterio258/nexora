package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) ListarEmpresas(w http.ResponseWriter, r *http.Request) {
	caller := mw.GetUser(r)
	status := r.URL.Query().Get("status")

	where := "1=1"
	args := []any{}
	if caller.Tipo != "superadmin" {
		args = append(args, caller.TenantID)
		where = "id = $1"
	}
	if status != "" {
		args = append(args, status)
		where += " AND status = $" + itoa(int64(len(args)))
	}

	rows, err := h.db.Query(r.Context(),
		"SELECT id, codigo, nome, nome_comercial, tipo, status, moeda_base, timezone, created_at FROM companies WHERE "+where+" ORDER BY nome",
		args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID          int64     `json:"id"`
		Codigo      string    `json:"codigo"`
		Nome        string    `json:"nome"`
		NomeComercial *string `json:"nome_comercial"`
		Tipo        string    `json:"tipo"`
		Status      string    `json:"status"`
		MoedaBase   string    `json:"moeda_base"`
		Timezone    string    `json:"timezone"`
		CreatedAt   time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var c Row
		if rows.Scan(&c.ID, &c.Codigo, &c.Nome, &c.NomeComercial, &c.Tipo, &c.Status, &c.MoedaBase, &c.Timezone, &c.CreatedAt) == nil {
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarEmpresa(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Codigo      string  `json:"codigo"`
		Nome        string  `json:"nome"`
		NomeComercial *string `json:"nome_comercial"`
		Tipo        *string `json:"tipo"`
		MoedaBase   *string `json:"moeda_base"`
		Timezone    *string `json:"timezone"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}

	var id int64
	var createdAt time.Time
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO companies (codigo, nome, nome_comercial, tipo, moeda_base, timezone)
		VALUES ($1, $2, $3, COALESCE($4,'empresa'), COALESCE($5,'MZN'), COALESCE($6,'Africa/Maputo'))
		RETURNING id, created_at`,
		body.Codigo, body.Nome, body.NomeComercial, body.Tipo, body.MoedaBase, body.Timezone).
		Scan(&id, &createdAt)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Código já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id, "codigo": body.Codigo, "nome": body.Nome, "created_at": createdAt}, http.StatusCreated)
}

func (h *Handler) ObterEmpresa(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var c struct {
		ID            int64      `json:"id"`
		Codigo        string     `json:"codigo"`
		Nome          string     `json:"nome"`
		NomeComercial *string    `json:"nome_comercial"`
		Tipo          string     `json:"tipo"`
		Status        string     `json:"status"`
		MoedaBase     string     `json:"moeda_base"`
		Timezone      string     `json:"timezone"`
		CreatedAt     time.Time  `json:"created_at"`
		UpdatedAt     time.Time  `json:"updated_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, codigo, nome, nome_comercial, tipo, status, moeda_base, timezone, created_at, updated_at
		  FROM companies WHERE id = $1`, id).
		Scan(&c.ID, &c.Codigo, &c.Nome, &c.NomeComercial, &c.Tipo, &c.Status, &c.MoedaBase, &c.Timezone, &c.CreatedAt, &c.UpdatedAt)
	if err != nil {
		jsonErr(w, "Empresa não encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, c, http.StatusOK)
}

func (h *Handler) ActualizarEmpresa(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		Nome          *string `json:"nome"`
		NomeComercial *string `json:"nome_comercial"`
		Status        *string `json:"status"`
		MoedaBase     *string `json:"moeda_base"`
		Timezone      *string `json:"timezone"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	tag, err := h.db.Exec(r.Context(), `
		UPDATE companies SET
		  nome           = COALESCE($1, nome),
		  nome_comercial = COALESCE($2, nome_comercial),
		  status         = COALESCE($3, status),
		  moeda_base     = COALESCE($4, moeda_base),
		  timezone       = COALESCE($5, timezone),
		  updated_at     = NOW()
		WHERE id = $6`,
		body.Nome, body.NomeComercial, body.Status, body.MoedaBase, body.Timezone, id)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Empresa não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
