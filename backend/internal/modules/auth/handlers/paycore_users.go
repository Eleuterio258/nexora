package handlers

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"golang.org/x/crypto/bcrypt"

	mw "nexora/internal/middleware"
)

// ── PayCore-compatible user API (/api/v1/users) ──────────────────────────────
//
// O frontend PHP foi adaptado ao PayCore (Node.js) e espera endpoints REST
// simples com campos em inglês/camelCase. O backend Nexora ERP guarda os
// mesmos dados num schema ligeiramente diferente. Estes handlers fazem a
// ponte, sem alterar o modelo existente.

type paycoreUser struct {
	ID               int64     `json:"id"`
	Name             string    `json:"name"`
	Email            string    `json:"email"`
	Role             string    `json:"role"`
	Active           bool      `json:"active"`
	PhoneNumber      *string   `json:"phoneNumber"`
	TwoFactorEnabled bool      `json:"twoFactorEnabled"`
	CreatedAt        time.Time `json:"createdAt"`
	UpdatedAt        *time.Time `json:"updatedAt,omitempty"`
}

func (h *Handler) PayCoreListarUtilizadores(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	roleFilter := r.URL.Query().Get("role")

	rows, err := h.db.Query(r.Context(), `
		SELECT u.id, u.nome, u.email, u.telefone, u.estado, u.created_at, u.updated_at, COALESCE(NULLIF(m.papel, ''), u.tipo)
		FROM auth.users u
		JOIN auth.memberships m ON m.user_id = u.id AND m.tenant_id = $1
		WHERE u.tipo IN ('superadmin', 'funcionario')
		ORDER BY u.nome ASC
	`, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var result []paycoreUser
	for rows.Next() {
		var u paycoreUser
		var estado, papel string
		var updatedAt *time.Time
		if err := rows.Scan(&u.ID, &u.Name, &u.Email, &u.PhoneNumber, &estado, &u.CreatedAt, &updatedAt, &papel); err != nil {
			continue
		}
		u.TwoFactorEnabled = false
		u.Active = estado == "ativo"
		u.Role = paycoreRoleFromPapel(papel)
		u.UpdatedAt = updatedAt
		if roleFilter != "" && !strings.EqualFold(u.Role, roleFilter) {
			continue
		}
		result = append(result, u)
	}

	jsonOK(w, result, http.StatusOK)
}

func (h *Handler) PayCoreObterUtilizador(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var u paycoreUser
	var estado, papel string
	var updatedAt *time.Time
	err := h.db.QueryRow(r.Context(), `
		SELECT u.id, u.nome, u.email, u.telefone, u.estado, u.created_at, u.updated_at, COALESCE(NULLIF(m.papel, ''), u.tipo)
		FROM auth.users u
		JOIN auth.memberships m ON m.user_id = u.id AND m.tenant_id = $1
		WHERE u.id = $2
	`, user.TenantID, id).Scan(&u.ID, &u.Name, &u.Email, &u.PhoneNumber, &estado, &u.CreatedAt, &updatedAt, &papel)
	if err != nil {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}
	u.TwoFactorEnabled = false
	u.Active = estado == "ativo"
	u.Role = paycoreRoleFromPapel(papel)
	u.UpdatedAt = updatedAt
	jsonOK(w, u, http.StatusOK)
}

func (h *Handler) PayCoreCriarUtilizador(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Name        string  `json:"name"`
		Email       string  `json:"email"`
		Password    string  `json:"password"`
		Role        string  `json:"role"`
		Active      bool    `json:"active"`
		PhoneNumber *string `json:"phoneNumber"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Name == "" || body.Email == "" || body.Password == "" {
		jsonErr(w, "name, email e password são obrigatórios", http.StatusBadRequest)
		return
	}
	if len(body.Password) < 8 {
		jsonErr(w, "password deve ter pelo menos 8 caracteres", http.StatusBadRequest)
		return
	}

	tipo, papel := paycoreRoleToModel(body.Role)
	estado := "ativo"
	if !body.Active {
		estado = "bloqueado"
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte(body.Password), 12)

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var created paycoreUser
	var updatedAt *time.Time
	err = tx.QueryRow(r.Context(), `
		INSERT INTO auth.users (nome, email, password_hash, telefone, estado, tipo)
		VALUES ($1, LOWER($2), $3, $4, $5, $6)
		RETURNING id, nome, email, telefone, estado, created_at, updated_at`,
		body.Name, body.Email, string(hash), body.PhoneNumber, estado, tipo,
	).Scan(&created.ID, &created.Name, &created.Email, &created.PhoneNumber, &estado, &created.CreatedAt, &updatedAt)
	if err != nil {
		if isPgUniqueViolation(err) {
			jsonErr(w, "email já está em uso", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno ao criar utilizador", http.StatusInternalServerError)
		return
	}

	_, err = tx.Exec(r.Context(), `
		INSERT INTO auth.memberships (user_id, tenant_id, escopo, papel)
		VALUES ($1, $2, 'erp', $3)`,
		created.ID, user.TenantID, papel)
	if err != nil {
		jsonErr(w, "Erro interno ao associar tenant", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	created.Active = estado == "ativo"
	created.Role = body.Role
	if created.Role == "" {
		created.Role = paycoreRoleFromPapel(papel)
	}
	created.UpdatedAt = updatedAt
	jsonOK(w, created, http.StatusCreated)
}

func (h *Handler) PayCoreActualizarUtilizador(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Name        *string `json:"name"`
		Role        *string `json:"role"`
		Active      *bool   `json:"active"`
		PhoneNumber *string `json:"phoneNumber"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "payload inválido", http.StatusBadRequest)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	if body.Role != nil {
		tipo, papel := paycoreRoleToModel(*body.Role)
		_, err = tx.Exec(r.Context(), `
			UPDATE auth.users SET tipo = $1 WHERE id = $2`, tipo, id)
		if err != nil {
			jsonErr(w, "Erro interno ao actualizar role", http.StatusInternalServerError)
			return
		}
		_, err = tx.Exec(r.Context(), `
			UPDATE auth.memberships SET papel = $1 WHERE user_id = $2 AND tenant_id = $3`, papel, id, user.TenantID)
		if err != nil {
			jsonErr(w, "Erro interno ao actualizar role", http.StatusInternalServerError)
			return
		}
	}

	if body.Active != nil {
		estado := "ativo"
		if !*body.Active {
			estado = "bloqueado"
		}
		_, err = tx.Exec(r.Context(), `
			UPDATE auth.users SET estado = $1, updated_at = NOW() WHERE id = $2`, estado, id)
		if err != nil {
			jsonErr(w, "Erro interno ao actualizar estado", http.StatusInternalServerError)
			return
		}
	}

	var u paycoreUser
	var estado, papel string
	var updatedAt *time.Time
	err = tx.QueryRow(r.Context(), `
		UPDATE auth.users SET
		  nome = COALESCE($1, nome),
		  telefone = COALESCE($2, telefone),
		  updated_at = NOW()
		WHERE id = $3
		RETURNING id, nome, email, telefone, estado, created_at, updated_at`,
		body.Name, body.PhoneNumber, id,
	).Scan(&u.ID, &u.Name, &u.Email, &u.PhoneNumber, &estado, &u.CreatedAt, &updatedAt)
	if err != nil {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}

	_ = tx.QueryRow(r.Context(), `SELECT COALESCE(NULLIF(papel, ''), (SELECT tipo FROM auth.users WHERE id = $1)) FROM auth.memberships WHERE user_id = $1 AND tenant_id = $2`, id, user.TenantID).Scan(&papel)

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	u.Active = estado == "ativo"
	u.Role = paycoreRoleFromPapel(papel)
	u.UpdatedAt = updatedAt
	jsonOK(w, u, http.StatusOK)
}

func (h *Handler) PayCoreRemoverUtilizador(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	_, err := h.db.Exec(r.Context(), `
		UPDATE auth.users SET estado = 'desactivado', updated_at = NOW()
		WHERE id = $1 AND EXISTS (SELECT 1 FROM auth.memberships WHERE user_id = $1 AND tenant_id = $2)`,
		id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── helpers ──────────────────────────────────────────────────────────────────

func paycoreRoleFromPapel(papel string) string {
	switch strings.ToLower(papel) {
	case "superadmin":
		return "SUPER_ADMIN"
	case "funcionario":
		return "OPERADOR"
	default:
		return "OPERADOR"
	}
}

func paycoreRoleToModel(role string) (tipo, papel string) {
	switch strings.ToUpper(role) {
	case "SUPER_ADMIN":
		return "superadmin", "superadmin"
	case "ADMIN", "OPERADOR":
		return "funcionario", "funcionario"
	default:
		return "funcionario", "funcionario"
	}
}

