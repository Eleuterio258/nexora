package handlers

import (
	"net/http"
	"strconv"
	"time"

	mw "nexora/internal/middleware"
)

func (h *Handler) HistoricoLogin(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	page, _ := strconv.Atoi(q.Get("page"))
	if page < 1 {
		page = 1
	}
	limit, _ := strconv.Atoi(q.Get("limit"))
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	where := "tenant_id = $1"
	args := []interface{}{user.TenantID}

	if s := q.Get("sucesso"); s == "true" || s == "false" {
		args = append(args, s == "true")
		where += " AND sucesso = $" + strconv.Itoa(len(args))
	}
	if email := q.Get("email"); email != "" {
		args = append(args, "%"+email+"%")
		where += " AND email_tentado ILIKE $" + strconv.Itoa(len(args))
	}

	countArgs := make([]interface{}, len(args))
	copy(countArgs, args)
	args = append(args, limit, offset)

	rows, err := h.db.Query(r.Context(),
		"SELECT id, user_id, email_tentado, sucesso, ip_address, user_agent, motivo_falha, criado_em FROM login_history WHERE "+
			where+" ORDER BY criado_em DESC LIMIT $"+strconv.Itoa(len(args)-1)+" OFFSET $"+strconv.Itoa(len(args)),
		args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID           int64     `json:"id"`
		UserID       *int64    `json:"user_id"`
		EmailTentado *string   `json:"email_tentado"`
		Sucesso      bool      `json:"sucesso"`
		IPAddress    *string   `json:"ip_address"`
		UserAgent    *string   `json:"user_agent"`
		MotivoFalha  *string   `json:"motivo_falha"`
		CriadoEm     time.Time `json:"criado_em"`
	}
	data := []Row{}
	for rows.Next() {
		var e Row
		if err := rows.Scan(&e.ID, &e.UserID, &e.EmailTentado, &e.Sucesso,
			&e.IPAddress, &e.UserAgent, &e.MotivoFalha, &e.CriadoEm); err == nil {
			data = append(data, e)
		}
	}

	var total int
	h.db.QueryRow(r.Context(), "SELECT COUNT(*) FROM login_history WHERE "+where, countArgs...).Scan(&total)

	jsonOK(w, map[string]interface{}{
		"data": data,
		"meta": map[string]int{"total": total, "page": page, "limit": limit},
	}, http.StatusOK)
}
