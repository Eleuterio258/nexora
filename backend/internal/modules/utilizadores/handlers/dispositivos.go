package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) ListarDispositivos(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}
	rows, err := h.db.Query(r.Context(), `
		SELECT id, device_id, nome, plataforma, user_agent, ultimo_acesso_em, confiavel, created_at
		  FROM user_devices WHERE user_id = $1 ORDER BY created_at DESC`, userID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID             int64      `json:"id"`
		DeviceID       string     `json:"device_id"`
		Nome           *string    `json:"nome"`
		Plataforma     *string    `json:"plataforma"`
		UserAgent      *string    `json:"user_agent"`
		UltimoAcessoEm *time.Time `json:"ultimo_acesso_em"`
		Confiavel      bool       `json:"confiavel"`
		CreatedAt      time.Time  `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var x Row
		if rows.Scan(&x.ID, &x.DeviceID, &x.Nome, &x.Plataforma, &x.UserAgent,
			&x.UltimoAcessoEm, &x.Confiavel, &x.CreatedAt) == nil {
			data = append(data, x)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) RegistarDispositivo(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}
	var body struct {
		DeviceID   string  `json:"device_id"`
		Nome       *string `json:"nome"`
		Plataforma *string `json:"plataforma"`
		Confiavel  bool    `json:"confiavel"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.DeviceID == "" {
		jsonErr(w, "device_id é obrigatório", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO user_devices (user_id, device_id, nome, plataforma, user_agent, ultimo_acesso_em, confiavel)
		VALUES ($1, $2, $3, $4, $5, NOW(), $6)
		ON CONFLICT (user_id, device_id) DO UPDATE
		  SET nome = COALESCE($3, user_devices.nome),
		      plataforma = COALESCE($4, user_devices.plataforma),
		      user_agent = COALESCE($5, user_devices.user_agent),
		      ultimo_acesso_em = NOW(),
		      confiavel = $6
		RETURNING id`,
		userID, body.DeviceID, body.Nome, body.Plataforma,
		r.Header.Get("User-Agent"), body.Confiavel).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) RemoverDispositivo(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	deviceID := chi.URLParam(r, "deviceId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}
	tag, _ := h.db.Exec(r.Context(), `DELETE FROM user_devices WHERE id = $1 AND user_id = $2`, deviceID, userID)
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Dispositivo não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
