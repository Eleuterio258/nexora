package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) ListarAgenda(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}

	desde := r.URL.Query().Get("desde")
	if desde == "" {
		desde = time.Now().Format("2006-01-02")
	}
	ate := r.URL.Query().Get("ate")

	where := "user_id = $1 AND data >= $2"
	args := []any{userID, desde}
	if ate != "" {
		args = append(args, ate)
		where += " AND data <= $3"
	}

	rows, err := h.db.Query(r.Context(),
		"SELECT id, titulo, descricao, data, hora_inicio, hora_fim, tipo, created_at FROM utilizadores.user_agenda WHERE "+
			where+" ORDER BY data, hora_inicio",
		args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID         int64     `json:"id"`
		Titulo     string    `json:"titulo"`
		Descricao  *string   `json:"descricao"`
		Data       time.Time `json:"data"`
		HoraInicio string    `json:"hora_inicio"`
		HoraFim    *string   `json:"hora_fim"`
		Tipo       string    `json:"tipo"`
		CreatedAt  time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var x Row
		var horaInicio, horaFim *time.Time
		if rows.Scan(&x.ID, &x.Titulo, &x.Descricao, &x.Data, &horaInicio, &horaFim, &x.Tipo, &x.CreatedAt) == nil {
			if horaInicio != nil {
				x.HoraInicio = horaInicio.Format("15:04")
			}
			if horaFim != nil {
				f := horaFim.Format("15:04")
				x.HoraFim = &f
			}
			data = append(data, x)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarItemAgenda(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}

	var body struct {
		Titulo     string  `json:"titulo"`
		Descricao  *string `json:"descricao"`
		Data       string  `json:"data"`
		HoraInicio string  `json:"hora_inicio"`
		HoraFim    *string `json:"hora_fim"`
		Tipo       string  `json:"tipo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil ||
		body.Titulo == "" || body.Data == "" || body.HoraInicio == "" {
		jsonErr(w, "titulo, data e hora_inicio são obrigatórios", http.StatusBadRequest)
		return
	}
	if body.Tipo == "" {
		body.Tipo = "reuniao"
	}

	var id int64
	var createdAt time.Time
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO utilizadores.user_agenda (user_id, titulo, descricao, data, hora_inicio, hora_fim, tipo)
		VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id, created_at`,
		userID, body.Titulo, body.Descricao, body.Data, body.HoraInicio, body.HoraFim, body.Tipo).
		Scan(&id, &createdAt)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}
