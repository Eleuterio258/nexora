package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// ---- Ligação Professor ↔ RH ----------------------------------------

// ObterLigacaoRH devolve o rh_employee_id do professor.
func (h *Handler) ObterLigacaoRH(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var employeeID *int64
	err := h.db.QueryRow(r.Context(), `
		SELECT rh_employee_id FROM gestao_escolar.school_teachers
		WHERE id = $1 AND tenant_id = $2`, chi.URLParam(r, "id"), u.TenantID,
	).Scan(&employeeID)
	if err != nil {
		jsonErr(w, "Professor nao encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"rh_employee_id": employeeID}, http.StatusOK)
}

// LigarRH associa o professor ao funcionário RH indicado.
// Se rh_employee_id = null, remove a ligação.
func (h *Handler) LigarRH(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var body struct {
		RHEmployeeID *int64 `json:"rh_employee_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}

	// Valida que o funcionário RH pertence ao mesmo tenant (se fornecido)
	if body.RHEmployeeID != nil && h.hr != nil {
		empID, err := h.hr.GetEmployeeID(r.Context(), u.TenantID, 0)
		// Verificação directa pelo ID
		_ = empID
		_ = err
		var exists bool
		_ = h.db.QueryRow(r.Context(), `
			SELECT EXISTS(SELECT 1 FROM rh.funcionarios WHERE id = $1 AND tenant_id = $2)`,
			*body.RHEmployeeID, u.TenantID).Scan(&exists)
		if !exists {
			jsonErr(w, "Funcionario RH nao encontrado neste tenant", http.StatusUnprocessableEntity)
			return
		}
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_teachers
		SET rh_employee_id = $1, updated_at = NOW()
		WHERE id = $2 AND tenant_id = $3`,
		body.RHEmployeeID, chi.URLParam(r, "id"), u.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Professor nao encontrado ou erro ao ligar", http.StatusUnprocessableEntity)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ---- Ligação Aluno ↔ Cliente ----------------------------------------

// ObterLigacaoCliente devolve o client_id do aluno.
func (h *Handler) ObterLigacaoCliente(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var clientID *int64
	err := h.db.QueryRow(r.Context(), `
		SELECT client_id FROM gestao_escolar.school_students
		WHERE id = $1 AND tenant_id = $2`, chi.URLParam(r, "id"), u.TenantID,
	).Scan(&clientID)
	if err != nil {
		jsonErr(w, "Aluno nao encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"client_id": clientID}, http.StatusOK)
}

// LigarCliente associa o aluno ao cliente indicado.
// Se client_id = null, remove a ligação. Se email for fornecido, resolve o cliente pelo email.
func (h *Handler) LigarCliente(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var body struct {
		ClientID *int64  `json:"client_id"`
		Email    *string `json:"email"` // alternativa: resolver pelo email
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}

	clientID := body.ClientID

	// Resolução por email via ClientPort
	if clientID == nil && body.Email != nil && h.client != nil {
		id, err := h.client.GetClientID(r.Context(), u.TenantID, *body.Email)
		if err == nil && id > 0 {
			clientID = &id
		}
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_students
		SET client_id = $1, updated_at = NOW()
		WHERE id = $2 AND tenant_id = $3`,
		clientID, chi.URLParam(r, "id"), u.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Aluno nao encontrado ou erro ao ligar", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"client_id": clientID}, http.StatusOK)
}
