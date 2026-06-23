package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) ListarPreferencias(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID && caller.Tipo != "superadmin" {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}
	rows, err := h.db.Query(r.Context(), `
		SELECT id, chave, valor, updated_at FROM user_preferences WHERE user_id = $1 ORDER BY chave`, userID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID        int64     `json:"id"`
		Chave     string    `json:"chave"`
		Valor     *string   `json:"valor"`
		UpdatedAt time.Time `json:"updated_at"`
	}
	data := []Row{}
	for rows.Next() {
		var x Row
		if rows.Scan(&x.ID, &x.Chave, &x.Valor, &x.UpdatedAt) == nil {
			data = append(data, x)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) GuardarPreferencia(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}
	var body struct {
		Chave string  `json:"chave"`
		Valor *string `json:"valor"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Chave == "" {
		jsonErr(w, "chave é obrigatória", http.StatusBadRequest)
		return
	}
	_, err := h.db.Exec(r.Context(), `
		INSERT INTO user_preferences (user_id, chave, valor)
		VALUES ($1, $2, $3)
		ON CONFLICT (user_id, chave) DO UPDATE SET valor = $3, updated_at = NOW()`,
		userID, body.Chave, body.Valor)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Settings (mesmo padrão que preferências) ──────────────────────────────────

func (h *Handler) ListarSettings(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID && caller.Tipo != "superadmin" {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}
	rows, err := h.db.Query(r.Context(), `
		SELECT id, chave, valor, updated_at FROM user_settings WHERE user_id = $1 ORDER BY chave`, userID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID        int64     `json:"id"`
		Chave     string    `json:"chave"`
		Valor     *string   `json:"valor"`
		UpdatedAt time.Time `json:"updated_at"`
	}
	data := []Row{}
	for rows.Next() {
		var x Row
		if rows.Scan(&x.ID, &x.Chave, &x.Valor, &x.UpdatedAt) == nil {
			data = append(data, x)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) GuardarSetting(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}
	var body struct {
		Chave string  `json:"chave"`
		Valor *string `json:"valor"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Chave == "" {
		jsonErr(w, "chave é obrigatória", http.StatusBadRequest)
		return
	}
	_, err := h.db.Exec(r.Context(), `
		INSERT INTO user_settings (user_id, chave, valor)
		VALUES ($1, $2, $3)
		ON CONFLICT (user_id, chave) DO UPDATE SET valor = $3, updated_at = NOW()`,
		userID, body.Chave, body.Valor)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
