package handlers

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) ListarSecurityLogs(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID && caller.Tipo != "superadmin" {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}
	limit, offset := pageParams(r)
	severidade := r.URL.Query().Get("severidade")

	where := "user_id = $1"
	args := []any{userID}
	if severidade != "" {
		args = append(args, severidade)
		where += " AND severidade = $2"
	}
	args = append(args, limit, offset)
	n := len(args)

	rows, err := h.db.Query(r.Context(),
		"SELECT id, evento, severidade, detalhe, ip_address, created_at FROM user_security_logs WHERE "+
			where+" ORDER BY created_at DESC LIMIT $"+itoa(int64(n-1))+" OFFSET $"+itoa(int64(n)),
		args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID         int64     `json:"id"`
		Evento     string    `json:"evento"`
		Severidade string    `json:"severidade"`
		Detalhe    *string   `json:"detalhe"`
		IPAddress  *string   `json:"ip_address"`
		CreatedAt  time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var x Row
		if rows.Scan(&x.ID, &x.Evento, &x.Severidade, &x.Detalhe, &x.IPAddress, &x.CreatedAt) == nil {
			data = append(data, x)
		}
	}
	jsonOK(w, data, http.StatusOK)
}
