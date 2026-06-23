package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// ── Roles ─────────────────────────────────────────────────────────────────────

func (h *Handler) ListarRoles(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, err := h.db.Query(r.Context(), `
		SELECT id, codigo, nome, descricao, ativo, created_at
		  FROM roles WHERE tenant_id = $1 ORDER BY nome`, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID        int64     `json:"id"`
		Codigo    string    `json:"codigo"`
		Nome      string    `json:"nome"`
		Descricao *string   `json:"descricao"`
		Ativo     bool      `json:"ativo"`
		CreatedAt time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var r Row
		if rows.Scan(&r.ID, &r.Codigo, &r.Nome, &r.Descricao, &r.Ativo, &r.CreatedAt) == nil {
			data = append(data, r)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarRole(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo    string  `json:"codigo"`
		Nome      string  `json:"nome"`
		Descricao *string `json:"descricao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO roles (tenant_id, codigo, nome, descricao) VALUES ($1,$2,$3,$4) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Descricao).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Código de role já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarRole(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Nome      *string `json:"nome"`
		Descricao *string `json:"descricao"`
		Ativo     *bool   `json:"ativo"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	tag, err := h.db.Exec(r.Context(), `
		UPDATE roles SET
		  nome = COALESCE($1, nome),
		  descricao = COALESCE($2, descricao),
		  ativo = COALESCE($3, ativo)
		WHERE id = $4 AND tenant_id = $5`,
		body.Nome, body.Descricao, body.Ativo, id, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Role não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Permissions ───────────────────────────────────────────────────────────────

func (h *Handler) ListarPermissoes(w http.ResponseWriter, r *http.Request) {
	recurso := r.URL.Query().Get("recurso")
	where := "1=1"
	args := []any{}
	if recurso != "" {
		args = append(args, recurso)
		where = "recurso = $1"
	}
	rows, err := h.db.Query(r.Context(),
		"SELECT id, codigo, nome, descricao, recurso, acao FROM permissions WHERE "+where+" ORDER BY recurso, acao",
		args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID        int64   `json:"id"`
		Codigo    string  `json:"codigo"`
		Nome      string  `json:"nome"`
		Descricao *string `json:"descricao"`
		Recurso   *string `json:"recurso"`
		Acao      *string `json:"acao"`
	}
	data := []Row{}
	for rows.Next() {
		var p Row
		if rows.Scan(&p.ID, &p.Codigo, &p.Nome, &p.Descricao, &p.Recurso, &p.Acao) == nil {
			data = append(data, p)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarPermissao(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Codigo    string  `json:"codigo"`
		Nome      string  `json:"nome"`
		Descricao *string `json:"descricao"`
		Recurso   *string `json:"recurso"`
		Acao      *string `json:"acao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO permissions (codigo, nome, descricao, recurso, acao) VALUES ($1,$2,$3,$4,$5) RETURNING id`,
		body.Codigo, body.Nome, body.Descricao, body.Recurso, body.Acao).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Código de permissão já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ── Role Permissions ──────────────────────────────────────────────────────────

func (h *Handler) ListarPermissoesRole(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	rows, _ := h.db.Query(r.Context(), `
		SELECT p.id, p.codigo, p.nome, p.recurso, p.acao
		  FROM role_permissions rp
		  JOIN permissions p ON p.id = rp.permission_id
		 WHERE rp.role_id = $1 ORDER BY p.recurso, p.acao`, id)
	defer rows.Close()
	type Row struct {
		ID      int64   `json:"id"`
		Codigo  string  `json:"codigo"`
		Nome    string  `json:"nome"`
		Recurso *string `json:"recurso"`
		Acao    *string `json:"acao"`
	}
	data := []Row{}
	for rows.Next() {
		var p Row
		if rows.Scan(&p.ID, &p.Codigo, &p.Nome, &p.Recurso, &p.Acao) == nil {
			data = append(data, p)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) AdicionarPermissaoRole(w http.ResponseWriter, r *http.Request) {
	roleID := chi.URLParam(r, "id")
	var body struct {
		PermissionID int64 `json:"permission_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.PermissionID == 0 {
		jsonErr(w, "permission_id é obrigatório", http.StatusBadRequest)
		return
	}
	_, err := h.db.Exec(r.Context(), `
		INSERT INTO role_permissions (role_id, permission_id) VALUES ($1,$2) ON CONFLICT DO NOTHING`,
		roleID, body.PermissionID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverPermissaoRole(w http.ResponseWriter, r *http.Request) {
	roleID := chi.URLParam(r, "id")
	permID := chi.URLParam(r, "permissionId")
	h.db.Exec(r.Context(), `DELETE FROM role_permissions WHERE role_id = $1 AND permission_id = $2`, roleID, permID)
	w.WriteHeader(http.StatusNoContent)
}

// ── User Roles ────────────────────────────────────────────────────────────────

func (h *Handler) ListarRolesUser(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	rows, _ := h.db.Query(r.Context(), `
		SELECT r.id, r.codigo, r.nome FROM user_roles ur
		  JOIN roles r ON r.id = ur.role_id WHERE ur.user_id = $1`, userID)
	defer rows.Close()
	type Row struct {
		ID     int64  `json:"id"`
		Codigo string `json:"codigo"`
		Nome   string `json:"nome"`
	}
	data := []Row{}
	for rows.Next() {
		var r Row
		if rows.Scan(&r.ID, &r.Codigo, &r.Nome) == nil {
			data = append(data, r)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) AdicionarRoleUser(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	var body struct {
		RoleID int64 `json:"role_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.RoleID == 0 {
		jsonErr(w, "role_id é obrigatório", http.StatusBadRequest)
		return
	}
	h.db.Exec(r.Context(), `INSERT INTO user_roles (user_id, role_id) VALUES ($1,$2) ON CONFLICT DO NOTHING`, userID, body.RoleID)
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverRoleUser(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	roleID := chi.URLParam(r, "roleId")
	h.db.Exec(r.Context(), `DELETE FROM user_roles WHERE user_id = $1 AND role_id = $2`, userID, roleID)
	w.WriteHeader(http.StatusNoContent)
}
