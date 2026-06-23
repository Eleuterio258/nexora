package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
)

func (h *Handler) ListarBranches(w http.ResponseWriter, r *http.Request) {
	companyID := chi.URLParam(r, "id")
	rows, err := h.db.Query(r.Context(), `
		SELECT id, codigo, nome, status, principal, created_at
		  FROM company_branches WHERE company_id = $1 ORDER BY principal DESC, nome`, companyID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID        int64     `json:"id"`
		Codigo    string    `json:"codigo"`
		Nome      string    `json:"nome"`
		Status    string    `json:"status"`
		Principal bool      `json:"principal"`
		CreatedAt time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var b Row
		if rows.Scan(&b.ID, &b.Codigo, &b.Nome, &b.Status, &b.Principal, &b.CreatedAt) == nil {
			data = append(data, b)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarBranch(w http.ResponseWriter, r *http.Request) {
	companyID := chi.URLParam(r, "id")
	var body struct {
		Codigo    string  `json:"codigo"`
		Nome      string  `json:"nome"`
		Principal *bool   `json:"principal"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO company_branches (company_id, codigo, nome, principal)
		VALUES ($1, $2, $3, COALESCE($4, FALSE)) RETURNING id`,
		companyID, body.Codigo, body.Nome, body.Principal).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Código já existe nesta empresa", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterBranch(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "branchId")
	var b struct {
		ID        int64     `json:"id"`
		CompanyID int64     `json:"company_id"`
		Codigo    string    `json:"codigo"`
		Nome      string    `json:"nome"`
		Status    string    `json:"status"`
		Principal bool      `json:"principal"`
		CreatedAt time.Time `json:"created_at"`
		UpdatedAt time.Time `json:"updated_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, company_id, codigo, nome, status, principal, created_at, updated_at
		  FROM company_branches WHERE id = $1`, id).
		Scan(&b.ID, &b.CompanyID, &b.Codigo, &b.Nome, &b.Status, &b.Principal, &b.CreatedAt, &b.UpdatedAt)
	if err != nil {
		jsonErr(w, "Filial não encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, b, http.StatusOK)
}

func (h *Handler) ActualizarBranch(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "branchId")
	var body struct {
		Nome      *string `json:"nome"`
		Status    *string `json:"status"`
		Principal *bool   `json:"principal"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	tag, err := h.db.Exec(r.Context(), `
		UPDATE company_branches SET
		  nome      = COALESCE($1, nome),
		  status    = COALESCE($2, status),
		  principal = COALESCE($3, principal),
		  updated_at = NOW()
		WHERE id = $4`, body.Nome, body.Status, body.Principal, id)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Filial não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
