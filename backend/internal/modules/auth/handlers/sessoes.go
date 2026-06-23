package handlers

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

func (h *Handler) ListarSessoes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	rows, err := h.db.Query(r.Context(), `
		SELECT id, ip_address, user_agent, iniciado_em, expira_em,
		       (id = $2) AS atual
		  FROM sessions
		 WHERE user_id = $1 AND ativa = TRUE AND expira_em > NOW()
		 ORDER BY iniciado_em DESC`,
		user.ID, user.SessionID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID         int64     `json:"id"`
		IPAddress  *string   `json:"ip_address"`
		UserAgent  *string   `json:"user_agent"`
		IniciadoEm time.Time `json:"iniciado_em"`
		ExpiraEm   time.Time `json:"expira_em"`
		Atual      bool      `json:"atual"`
	}
	data := []Row{}
	for rows.Next() {
		var s Row
		if err := rows.Scan(&s.ID, &s.IPAddress, &s.UserAgent, &s.IniciadoEm, &s.ExpiraEm, &s.Atual); err == nil {
			data = append(data, s)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) RevogarSessao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tag, err := h.db.Exec(r.Context(), `
		UPDATE sessions SET ativa = FALSE, encerrado_em = NOW()
		 WHERE id = $1 AND user_id = $2`, id, user.ID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Sessão não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RevogarTodasSessoes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	h.db.Exec(r.Context(), `
		UPDATE sessions SET ativa = FALSE, encerrado_em = NOW()
		 WHERE user_id = $1 AND id != $2`, user.ID, user.SessionID)
	w.WriteHeader(http.StatusNoContent)
}
