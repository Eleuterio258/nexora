package handlers

import (
	"encoding/json"
	"net/http"

	mw "nexora/internal/middleware"
)

// RegisterPushToken regista o token de dispositivo (FCM) do utilizador
// autenticado — item 6 do plano-mudancas-backend-paycore-mobile.md. O
// serviço internal/push já aceita user_id genérico; só faltava este
// endpoint HTTP para utilizadores ERP (hoje só existia para candidatos,
// POST /api/candidatos/push-token).
func (h *Handler) RegisterPushToken(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var body struct {
		Token    string `json:"token"`
		Platform string `json:"platform"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Token == "" {
		jsonErr(w, "token é obrigatório", http.StatusBadRequest)
		return
	}

	if err := h.push.RegisterToken(r.Context(), user.ID, body.Token, body.Platform); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
