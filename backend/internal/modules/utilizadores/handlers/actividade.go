package handlers

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) ListarActividade(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID && caller.Tipo != "superadmin" {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}
	limit, offset := pageParams(r)
	modulo := r.URL.Query().Get("modulo")

	where := "user_id = $1"
	args := []any{userID}
	if modulo != "" {
		args = append(args, modulo)
		where += " AND modulo = $2"
	}
	args = append(args, limit, offset)
	n := len(args)

	rows, err := h.db.Query(r.Context(),
		"SELECT id, modulo, acao, descricao, ip_address, created_at FROM user_activity WHERE "+
			where+" ORDER BY created_at DESC LIMIT $"+itoa(int64(n-1))+" OFFSET $"+itoa(int64(n)),
		args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID        int64     `json:"id"`
		Modulo    *string   `json:"modulo"`
		Acao      string    `json:"acao"`
		Descricao *string   `json:"descricao"`
		IPAddress *string   `json:"ip_address"`
		CreatedAt time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var x Row
		if rows.Scan(&x.ID, &x.Modulo, &x.Acao, &x.Descricao, &x.IPAddress, &x.CreatedAt) == nil {
			data = append(data, x)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// RegistarActividade é chamado internamente por outros serviços.
func (h *Handler) RegistarActividade(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	var body struct {
		Modulo    *string `json:"modulo"`
		Acao      string  `json:"acao"`
		Descricao *string `json:"descricao"`
	}
	if err := h.decodeBody(r, &body); err != nil || body.Acao == "" {
		jsonErr(w, "acao é obrigatória", http.StatusBadRequest)
		return
	}
	h.db.Exec(r.Context(), `
		INSERT INTO user_activity (user_id, modulo, acao, descricao, ip_address)
		VALUES ($1, $2, $3, $4, $5)`,
		userID, body.Modulo, body.Acao, body.Descricao, r.RemoteAddr)
	w.WriteHeader(http.StatusCreated)
}

func (h *Handler) decodeBody(r *http.Request, v any) error {
	return jsonDecode(r, v)
}
