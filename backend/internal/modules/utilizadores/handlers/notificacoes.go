package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) ListarNotificacoes(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}
	limit, offset := pageParams(r)
	lida := r.URL.Query().Get("lida")

	where := "user_id = $1"
	args := []any{userID}
	if lida == "true" || lida == "false" {
		args = append(args, lida == "true")
		where += " AND lida = $" + strconv.Itoa(len(args))
	}
	args = append(args, limit, offset)
	n := len(args)

	rows, err := h.db.Query(r.Context(),
		"SELECT id, tipo, titulo, mensagem, lida, lida_em, created_at FROM utilizadores.user_notifications WHERE "+
			where+" ORDER BY created_at DESC LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n),
		args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID        int64      `json:"id"`
		Tipo      string     `json:"tipo"`
		Titulo    string     `json:"titulo"`
		Mensagem  string     `json:"mensagem"`
		Lida      bool       `json:"lida"`
		LidaEm    *time.Time `json:"lida_em"`
		CreatedAt time.Time  `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var x Row
		if rows.Scan(&x.ID, &x.Tipo, &x.Titulo, &x.Mensagem, &x.Lida, &x.LidaEm, &x.CreatedAt) == nil {
			data = append(data, x)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarNotificacao(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	var body struct {
		Tipo     string `json:"tipo"`
		Titulo   string `json:"titulo"`
		Mensagem string `json:"mensagem"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Titulo == "" || body.Mensagem == "" {
		jsonErr(w, "tipo, titulo e mensagem são obrigatórios", http.StatusBadRequest)
		return
	}

	var id int64
	var createdAt time.Time
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO utilizadores.user_notifications (user_id, tipo, titulo, mensagem)
		VALUES ($1, $2, $3, $4) RETURNING id, created_at`,
		userID, body.Tipo, body.Titulo, body.Mensagem).Scan(&id, &createdAt)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	// Empurrar via WS se o utilizador estiver ligado
	if h.hub != nil {
		uid, _ := strconv.ParseInt(userID, 10, 64)
		payload, _ := json.Marshal(map[string]any{
			"type":       "notification",
			"data": map[string]any{
				"id":         id,
				"tipo":       body.Tipo,
				"titulo":     body.Titulo,
				"mensagem":   body.Mensagem,
				"lida":       false,
				"created_at": createdAt.Format(time.RFC3339),
			},
		})
		h.hub.SendToUser(uid, payload)
	}

	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) MarcarNotificacaoLida(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	notifID := chi.URLParam(r, "notificationId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}
	tag, _ := h.db.Exec(r.Context(), `
		UPDATE utilizadores.user_notifications SET lida = TRUE, lida_em = NOW()
		 WHERE id = $1 AND user_id = $2`, notifID, userID)
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Notificação não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) MarcarTodasNotificacoesLidas(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}
	h.db.Exec(r.Context(), `
		UPDATE utilizadores.user_notifications SET lida = TRUE, lida_em = NOW()
		 WHERE user_id = $1 AND lida = FALSE`, userID)
	w.WriteHeader(http.StatusNoContent)
}
