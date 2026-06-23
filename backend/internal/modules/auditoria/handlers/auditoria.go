package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) ListarAuditLogs(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()

	where := "tenant_id = $1"
	args := []any{user.TenantID}

	if m := q.Get("modulo"); m != "" {
		args = append(args, m)
		where += " AND modulo = $" + strconv.Itoa(len(args))
	}
	if uid := q.Get("user_id"); uid != "" {
		args = append(args, uid)
		where += " AND user_id = $" + strconv.Itoa(len(args))
	}
	if e := q.Get("entidade"); e != "" {
		args = append(args, e)
		where += " AND entidade = $" + strconv.Itoa(len(args))
	}
	if eid := q.Get("entidade_id"); eid != "" {
		args = append(args, eid)
		where += " AND entidade_id = $" + strconv.Itoa(len(args))
	}
	if a := q.Get("acao"); a != "" {
		args = append(args, a)
		where += " AND acao = $" + strconv.Itoa(len(args))
	}

	page, _ := strconv.Atoi(q.Get("page"))
	if page < 1 {
		page = 1
	}
	limit, _ := strconv.Atoi(q.Get("limit"))
	if limit < 1 || limit > 100 {
		limit = 50
	}
	offset := (page - 1) * limit
	args = append(args, limit, offset)
	n := len(args)

	rows, err := h.db.Query(r.Context(),
		"SELECT id, user_id, modulo, entidade, entidade_id, acao, detalhes, ip_address, created_at FROM audit_logs WHERE "+
			where+" ORDER BY created_at DESC LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n),
		args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID         int64           `json:"id"`
		UserID     *int64          `json:"user_id"`
		Modulo     string          `json:"modulo"`
		Entidade   string          `json:"entidade"`
		EntidadeID *int64          `json:"entidade_id"`
		Acao       string          `json:"acao"`
		Detalhes   json.RawMessage `json:"detalhes"`
		IPAddress  *string         `json:"ip_address"`
		CreatedAt  time.Time       `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var l Row
		if rows.Scan(&l.ID, &l.UserID, &l.Modulo, &l.Entidade, &l.EntidadeID,
			&l.Acao, &l.Detalhes, &l.IPAddress, &l.CreatedAt) == nil {
			data = append(data, l)
		}
	}

	var total int
	countArgs := args[:len(args)-2]
	h.db.QueryRow(r.Context(), "SELECT COUNT(*) FROM audit_logs WHERE "+where, countArgs...).Scan(&total)

	jsonOK(w, map[string]any{
		"data": data,
		"meta": map[string]int{"total": total, "page": page, "limit": limit},
	}, http.StatusOK)
}

func (h *Handler) ObterAuditLog(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var l struct {
		ID         int64           `json:"id"`
		UserID     *int64          `json:"user_id"`
		Modulo     string          `json:"modulo"`
		Entidade   string          `json:"entidade"`
		EntidadeID *int64          `json:"entidade_id"`
		Acao       string          `json:"acao"`
		Detalhes   json.RawMessage `json:"detalhes"`
		IPAddress  *string         `json:"ip_address"`
		CreatedAt  time.Time       `json:"created_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, user_id, modulo, entidade, entidade_id, acao, detalhes, ip_address, created_at
		  FROM audit_logs WHERE id = $1 AND tenant_id = $2`, id, user.TenantID).
		Scan(&l.ID, &l.UserID, &l.Modulo, &l.Entidade, &l.EntidadeID,
			&l.Acao, &l.Detalhes, &l.IPAddress, &l.CreatedAt)
	if err != nil {
		jsonErr(w, "Log não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, l, http.StatusOK)
}

// RegistarAuditLog é chamado internamente pelos outros módulos.
func (h *Handler) RegistarAuditLog(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Modulo     string          `json:"modulo"`
		Entidade   string          `json:"entidade"`
		EntidadeID *int64          `json:"entidade_id"`
		Acao       string          `json:"acao"`
		Detalhes   json.RawMessage `json:"detalhes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Modulo == "" || body.Entidade == "" || body.Acao == "" {
		jsonErr(w, "modulo, entidade e acao são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	h.db.QueryRow(r.Context(), `
		INSERT INTO audit_logs (tenant_id, user_id, modulo, entidade, entidade_id, acao, detalhes, ip_address)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
		user.TenantID, user.ID, body.Modulo, body.Entidade, body.EntidadeID,
		body.Acao, body.Detalhes, r.RemoteAddr).Scan(&id)
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}
