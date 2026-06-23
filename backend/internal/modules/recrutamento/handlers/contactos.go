package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

type Contacto struct {
	ID        int64     `json:"id"`
	Nome      string    `json:"nome"`
	Email     string    `json:"email"`
	Assunto   string    `json:"assunto"`
	Mensagem  string    `json:"mensagem"`
	IP        string    `json:"ip"`
	Lido      bool      `json:"lido"`
	CreatedAt time.Time `json:"created_at"`
}

func (h *Handler) ListarContactos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)

	where := "tenant_id=$1"
	args := []any{user.TenantID}

	if lido := q.Get("lido"); lido != "" {
		args = append(args, lido == "1" || lido == "true")
		where += " AND lido=$" + strconv.Itoa(len(args))
	}

	countArgs := append([]any{}, args...)
	args = append(args, limit, offset)
	n := len(args)

	rows, err := h.db.Query(r.Context(),
		"SELECT id, nome, email, assunto, mensagem, ip, lido, created_at FROM contactos WHERE "+where+
			" ORDER BY created_at DESC LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n), args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []Contacto{}
	for rows.Next() {
		var c Contacto
		if rows.Scan(&c.ID, &c.Nome, &c.Email, &c.Assunto, &c.Mensagem, &c.IP, &c.Lido, &c.CreatedAt) == nil {
			data = append(data, c)
		}
	}

	var total int
	h.db.QueryRow(r.Context(), "SELECT COUNT(*) FROM contactos WHERE "+where, countArgs...).Scan(&total)
	page, _ := strconv.Atoi(q.Get("page"))
	if page < 1 {
		page = 1
	}
	jsonOK(w, map[string]any{"data": data, "meta": map[string]int{"total": total, "page": page, "limit": limit}}, http.StatusOK)
}

func (h *Handler) MarcarLido(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tag, err := h.db.Exec(r.Context(), "UPDATE contactos SET lido=TRUE WHERE id=$1 AND tenant_id=$2", id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Contacto não encontrado.", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}
