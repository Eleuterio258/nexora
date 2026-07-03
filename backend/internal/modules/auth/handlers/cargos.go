package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
	"nexora/internal/modules/auth/models"
)

// ── Listar ────────────────────────────────────────────────────────────────────

func (h *Handler) ListarCargos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, err := h.db.Query(r.Context(), `
		SELECT id, nome, descricao, ativo, created_at
		  FROM cargos WHERE tenant_id = $1 ORDER BY nome`, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID        int64     `json:"id"`
		Nome      string    `json:"nome"`
		Descricao *string   `json:"descricao"`
		Ativo     bool      `json:"ativo"`
		CreatedAt time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var c Row
		if rows.Scan(&c.ID, &c.Nome, &c.Descricao, &c.Ativo, &c.CreatedAt) == nil {
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// ── Criar ─────────────────────────────────────────────────────────────────────

func (h *Handler) CriarCargo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Nome      string  `json:"nome"`
		Descricao *string `json:"descricao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Nome == "" {
		jsonErr(w, "nome é obrigatório", http.StatusBadRequest)
		return
	}

	var created struct {
		ID        int64     `json:"id"`
		Nome      string    `json:"nome"`
		Descricao *string   `json:"descricao"`
		Ativo     bool      `json:"ativo"`
		CreatedAt time.Time `json:"created_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO cargos (tenant_id, nome, descricao)
		VALUES ($1, $2, $3)
		RETURNING id, nome, descricao, ativo, created_at`,
		user.TenantID, body.Nome, body.Descricao).
		Scan(&created.ID, &created.Nome, &created.Descricao, &created.Ativo, &created.CreatedAt)
	if err != nil {
		if isPgUniqueViolation(err) {
			jsonErr(w, "Cargo já existe neste tenant", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, created, http.StatusCreated)
}

// ── Obter ─────────────────────────────────────────────────────────────────────

func (h *Handler) ObterCargo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var c struct {
		ID        int64     `json:"id"`
		Nome      string    `json:"nome"`
		Descricao *string   `json:"descricao"`
		Ativo     bool      `json:"ativo"`
		CreatedAt time.Time `json:"created_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, nome, descricao, ativo, created_at
		  FROM cargos WHERE id = $1 AND tenant_id = $2`, id, user.TenantID).
		Scan(&c.ID, &c.Nome, &c.Descricao, &c.Ativo, &c.CreatedAt)
	if err != nil {
		jsonErr(w, "Cargo não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, c, http.StatusOK)
}

// ── Actualizar ────────────────────────────────────────────────────────────────

func (h *Handler) ActualizarCargo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Nome      *string `json:"nome"`
		Descricao *string `json:"descricao"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	var c struct {
		ID        int64   `json:"id"`
		Nome      string  `json:"nome"`
		Descricao *string `json:"descricao"`
		Ativo     bool    `json:"ativo"`
	}
	err := h.db.QueryRow(r.Context(), `
		UPDATE cargos SET
		  nome = COALESCE($1, nome),
		  descricao = COALESCE($2, descricao)
		WHERE id = $3 AND tenant_id = $4
		RETURNING id, nome, descricao, ativo`,
		body.Nome, body.Descricao, id, user.TenantID).
		Scan(&c.ID, &c.Nome, &c.Descricao, &c.Ativo)
	if err != nil {
		jsonErr(w, "Cargo não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, c, http.StatusOK)
}

// ── Ativar / Desativar ────────────────────────────────────────────────────────

func (h *Handler) ActivarCargo(w http.ResponseWriter, r *http.Request) {
	h.mudarAtivoCargo(true)(w, r)
}

func (h *Handler) DesactivarCargo(w http.ResponseWriter, r *http.Request) {
	h.mudarAtivoCargo(false)(w, r)
}

func (h *Handler) mudarAtivoCargo(ativo bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user := mw.GetUser(r)
		id := chi.URLParam(r, "id")
		tag, err := h.db.Exec(r.Context(), `
			UPDATE cargos SET ativo = $1 WHERE id = $2 AND tenant_id = $3`,
			ativo, id, user.TenantID)
		if err != nil || tag.RowsAffected() == 0 {
			jsonErr(w, "Cargo não encontrado", http.StatusNotFound)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

// ── Permissões do Cargo ───────────────────────────────────────────────────────

func (h *Handler) ListarPermissoesCargo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	// Confirmar que o cargo pertence ao tenant
	var exists bool
	h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM cargos WHERE id = $1 AND tenant_id = $2)`,
		id, user.TenantID).Scan(&exists)
	if !exists {
		jsonErr(w, "Cargo não encontrado", http.StatusNotFound)
		return
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT modulo, acao FROM permissoes_cargo WHERE cargo_id = $1 ORDER BY modulo, acao`, id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []models.Permission{}
	for rows.Next() {
		var p models.Permission
		if rows.Scan(&p.Modulo, &p.Acao) == nil {
			data = append(data, p)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// DefinirPermissoesCargo substitui todas as permissões do cargo.
func (h *Handler) DefinirPermissoesCargo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Permissoes []models.Permission `json:"permissoes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Body inválido", http.StatusBadRequest)
		return
	}

	var exists bool
	h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM cargos WHERE id = $1 AND tenant_id = $2)`,
		id, user.TenantID).Scan(&exists)
	if !exists {
		jsonErr(w, "Cargo não encontrado", http.StatusNotFound)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	tx.Exec(r.Context(), `DELETE FROM permissoes_cargo WHERE cargo_id = $1`, id)

	for _, p := range body.Permissoes {
		if p.Modulo == "" || p.Acao == "" {
			continue
		}
		tx.Exec(r.Context(), `
			INSERT INTO permissoes_cargo (cargo_id, modulo, acao) VALUES ($1, $2, $3)
			ON CONFLICT DO NOTHING`, id, p.Modulo, p.Acao)
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro ao guardar permissões", http.StatusInternalServerError)
		return
	}

	// Sinalizar todos os utilizadores com este cargo para refresh imediato de permissões
	h.db.Exec(r.Context(), `
		UPDATE users SET permissoes_atualizadas_em = NOW()
		WHERE id IN (SELECT user_id FROM auth.memberships WHERE cargo_id = $1 AND tenant_id = $2)`,
		id, user.TenantID)

	w.WriteHeader(http.StatusNoContent)
}
