package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	mw "nexora/internal/middleware"
)

// RegistarPushToken guarda (ou actualiza) o token FCM do dispositivo do
// candidato autenticado. O registo em si é feito pelo serviço genérico
// internal/push (por user_id) — aqui só resolvemos o user_id ligado a esta
// sessão de candidato.
func (h *Handler) RegistarPushToken(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)

	var body struct {
		Token    string `json:"token"`
		Platform string `json:"platform"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	token := strings.TrimSpace(body.Token)
	if token == "" {
		jsonErr(w, "token é obrigatório", http.StatusUnprocessableEntity)
		return
	}

	userID, err := h.userIDDoCandidato(r.Context(), c.ID)
	if err != nil {
		jsonErr(w, "Conta sem utilizador associado", http.StatusConflict)
		return
	}

	if err := h.push.RegisterToken(r.Context(), userID, token, body.Platform); err != nil {
		jsonErr(w, "Erro ao guardar token", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// userIDDoCandidato resolve o auth.users.id ligado a um candidato — a
// identidade universal usada pelo serviço genérico de push (ver
// internal/push), partilhada por todos os tipos de principal do sistema.
func (h *Handler) userIDDoCandidato(ctx context.Context, candidatoID int64) (int64, error) {
	var userID *int64
	if err := h.db.QueryRow(ctx,
		`SELECT user_id FROM recrutamento.candidatos WHERE id=$1`, candidatoID,
	).Scan(&userID); err != nil {
		return 0, err
	}
	if userID == nil {
		return 0, fmt.Errorf("candidato %d sem user_id associado", candidatoID)
	}
	return *userID, nil
}

// notificarCandidatoPush envia um push ao candidato da candidatura quando o
// recrutador (ou o sistema) lhe deixa uma nova mensagem/nota. Falhas aqui
// nunca devem impedir a operação que a chamou — por isso não devolve erro,
// apenas ignora silenciosamente (o Service já regista falhas em log).
func (h *Handler) notificarCandidatoPush(ctx context.Context, candidaturaID int64, autor, conteudo string) {
	var candidatoID *int64
	var vagaTitulo string
	if err := h.db.QueryRow(ctx, `
		SELECT candidato_id, vaga_titulo FROM recrutamento.candidaturas WHERE id=$1`,
		candidaturaID).Scan(&candidatoID, &vagaTitulo); err != nil || candidatoID == nil {
		return
	}

	userID, err := h.userIDDoCandidato(ctx, *candidatoID)
	if err != nil {
		return
	}

	corpo := fmt.Sprintf("%s: %s", autor, conteudo)
	if len(corpo) > 140 {
		corpo = corpo[:137] + "..."
	}

	h.push.SendToUser(ctx, userID, "Nova mensagem — "+vagaTitulo, corpo, map[string]string{
		"tipo":           "candidatura_mensagem",
		"candidatura_id": strconv.FormatInt(candidaturaID, 10),
	})
}
