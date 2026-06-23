package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
	"nexora/internal/modules/auth/models"
)

// ObterAcessoUtilizador devolve tipo + cargo + permissões mergeadas.
func (h *Handler) ObterAcessoUtilizador(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	access, err := models.LoadUserAccess(r.Context(), h.db, user.ID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, access, http.StatusOK)
}

// ListarPermissoesDiretas lista as permissões diretas de um utilizador.
func (h *Handler) ListarPermissoesDiretas(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	targetID := chi.URLParam(r, "id")

	// Confirmar que o utilizador pertence ao mesmo tenant
	var exists bool
	h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM users WHERE id = $1 AND tenant_id = $2)`,
		targetID, user.TenantID).Scan(&exists)
	if !exists {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT modulo, acao FROM permissoes_diretas WHERE user_id = $1 ORDER BY modulo, acao`, targetID)
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

// DefinirPermissoesDiretas substitui todas as permissões diretas de um utilizador.
func (h *Handler) DefinirPermissoesDiretas(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	targetID := chi.URLParam(r, "id")

	var body struct {
		Permissoes []models.Permission `json:"permissoes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Body inválido", http.StatusBadRequest)
		return
	}

	var exists bool
	h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM users WHERE id = $1 AND tenant_id = $2)`,
		targetID, user.TenantID).Scan(&exists)
	if !exists {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	tx.Exec(r.Context(), `DELETE FROM permissoes_diretas WHERE user_id = $1`, targetID)

	for _, p := range body.Permissoes {
		if p.Modulo == "" || p.Acao == "" {
			continue
		}
		tx.Exec(r.Context(), `
			INSERT INTO permissoes_diretas (user_id, modulo, acao) VALUES ($1, $2, $3)
			ON CONFLICT DO NOTHING`, targetID, p.Modulo, p.Acao)
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro ao guardar permissões", http.StatusInternalServerError)
		return
	}

	// Sinalizar que as permissões foram actualizadas — o cliente PHP detecta e faz sync imediato
	h.db.Exec(r.Context(), `
		UPDATE users SET permissoes_atualizadas_em = NOW() WHERE id = $1`, targetID)

	w.WriteHeader(http.StatusNoContent)
}

// AtribuirCargo atribui ou remove um cargo de um utilizador.
func (h *Handler) AtribuirCargo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	targetID := chi.URLParam(r, "id")

	var body struct {
		CargoID *int64 `json:"cargo_id"` // null para remover cargo
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Body inválido", http.StatusBadRequest)
		return
	}

	// Validar que o cargo pertence ao mesmo tenant (se fornecido)
	if body.CargoID != nil {
		var ok bool
		h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM cargos WHERE id = $1 AND tenant_id = $2 AND ativo = TRUE)`,
			*body.CargoID, user.TenantID).Scan(&ok)
		if !ok {
			jsonErr(w, "Cargo não encontrado ou inactivo", http.StatusBadRequest)
			return
		}
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE users SET cargo_id = $1, permissoes_atualizadas_em = NOW()
		WHERE id = $2 AND tenant_id = $3`,
		body.CargoID, targetID, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
