package handlers

import (
	"net/http"
	"strconv"
	"time"
)

type globalUserResponse struct {
	ID            int64      `json:"id"`
	TenantID      *int64     `json:"tenant_id"`
	TenantNome    *string    `json:"tenant_nome"`
	Nome          string     `json:"nome"`
	Email         string     `json:"email"`
	Telefone      *string    `json:"telefone"`
	Estado        string     `json:"estado"`
	Tipo          string     `json:"tipo"`
	UltimoLoginEm *time.Time `json:"ultimo_login_em"`
	CreatedAt     time.Time  `json:"created_at"`
}

func (h *Handler) ListarUtilizadoresGlobais(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	tenantID := q.Get("tenant_id")
	search := q.Get("search")
	page, _ := strconv.Atoi(q.Get("page"))
	if page < 1 {
		page = 1
	}
	limit, _ := strconv.Atoi(q.Get("limit"))
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	where := "1=1"
	args := []any{}

	if tenantID != "" {
		args = append(args, tenantID)
		where += " AND m.tenant_id = $" + strconv.Itoa(len(args))
	}
	if search != "" {
		args = append(args, "%"+search+"%")
		idx := strconv.Itoa(len(args))
		where += " AND (u.nome ILIKE $" + idx + " OR u.email ILIKE $" + idx + ")"
	}

	countArgs := make([]any, len(args))
	copy(countArgs, args)

	args = append(args, limit, offset)
	dataQ := `
		SELECT u.id, m.tenant_id, t.nome, u.nome, u.email, u.telefone, u.estado, u.tipo,
		       u.ultimo_login_em, u.created_at
		  FROM auth.users u
		  LEFT JOIN auth.memberships m ON m.user_id = u.id
		  LEFT JOIN saas.tenants t ON t.id = m.tenant_id
		 WHERE ` + where + `
		 ORDER BY u.created_at DESC
		 LIMIT $` + strconv.Itoa(len(args)-1) + ` OFFSET $` + strconv.Itoa(len(args))

	rows, err := h.db.Query(r.Context(), dataQ, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []globalUserResponse{}
	for rows.Next() {
		var u globalUserResponse
		if err := rows.Scan(&u.ID, &u.TenantID, &u.TenantNome, &u.Nome, &u.Email,
			&u.Telefone, &u.Estado, &u.Tipo, &u.UltimoLoginEm, &u.CreatedAt); err == nil {
			data = append(data, u)
		}
	}

	var total int
	h.db.QueryRow(r.Context(),
		`SELECT COUNT(*) FROM auth.users u LEFT JOIN auth.memberships m ON m.user_id = u.id WHERE `+where,
		countArgs...).Scan(&total)

	jsonOK(w, map[string]any{
		"data": data,
		"meta": map[string]int{"total": total, "page": page, "limit": limit},
	}, http.StatusOK)
}
