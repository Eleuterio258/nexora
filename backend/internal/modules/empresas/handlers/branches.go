package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) ListarBranches(w http.ResponseWriter, r *http.Request) {
	caller := mw.GetUser(r)
	companyID := chi.URLParam(r, "id")
	if caller.Tipo != "superadmin" {
		if _, ok := h.empresaDoTenant(r.Context(), companyID, caller.TenantID); !ok {
			jsonErr(w, "Empresa não encontrada", http.StatusNotFound)
			return
		}
	}
	rows, err := h.db.Query(r.Context(), `
		SELECT id, codigo, nome, status, principal, created_at
		  FROM empresas.company_branches WHERE company_id = $1 ORDER BY principal DESC, nome`, companyID)
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
	caller := mw.GetUser(r)
	companyID := chi.URLParam(r, "id")
	if caller.Tipo != "superadmin" {
		if _, ok := h.empresaDoTenant(r.Context(), companyID, caller.TenantID); !ok {
			jsonErr(w, "Empresa não encontrada", http.StatusNotFound)
			return
		}
	}
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
		INSERT INTO empresas.company_branches (company_id, codigo, nome, principal)
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
	caller := mw.GetUser(r)
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
		SELECT b.id, b.company_id, b.codigo, b.nome, b.status, b.principal, b.created_at, b.updated_at
		  FROM empresas.company_branches b
		  JOIN empresas.companies c ON c.id = b.company_id
		 WHERE b.id = $1 AND (c.tenant_id = $2 OR $3)`, id, caller.TenantID, caller.Tipo == "superadmin").
		Scan(&b.ID, &b.CompanyID, &b.Codigo, &b.Nome, &b.Status, &b.Principal, &b.CreatedAt, &b.UpdatedAt)
	if err != nil {
		jsonErr(w, "Filial não encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, b, http.StatusOK)
}

func (h *Handler) ActualizarBranch(w http.ResponseWriter, r *http.Request) {
	caller := mw.GetUser(r)
	id := chi.URLParam(r, "branchId")
	var body struct {
		Nome      *string `json:"nome"`
		Status    *string `json:"status"`
		Principal *bool   `json:"principal"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	tag, err := h.db.Exec(r.Context(), `
		UPDATE empresas.company_branches SET
		  nome      = COALESCE($1, nome),
		  status    = COALESCE($2, status),
		  principal = COALESCE($3, principal),
		  updated_at = NOW()
		FROM empresas.companies c
		WHERE company_branches.id = $4 AND company_branches.company_id = c.id AND (c.tenant_id = $5 OR $6)`,
		body.Nome, body.Status, body.Principal, id, caller.TenantID, caller.Tipo == "superadmin")
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Filial não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
