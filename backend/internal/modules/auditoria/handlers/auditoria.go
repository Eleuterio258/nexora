package handlers

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// auditLogsFilterWhere constrói a cláusula WHERE + args a partir dos mesmos
// filtros de query usados por ListarAuditLogs/ExportarAuditLogsCSV.
func auditLogsFilterWhere(tenantID int64, q map[string][]string) (string, []any) {
	get := func(k string) string {
		if v, ok := q[k]; ok && len(v) > 0 {
			return v[0]
		}
		return ""
	}
	where := "tenant_id = $1"
	args := []any{tenantID}
	if m := get("modulo"); m != "" {
		args = append(args, m)
		where += " AND modulo = $" + strconv.Itoa(len(args))
	}
	if uid := get("user_id"); uid != "" {
		args = append(args, uid)
		where += " AND user_id = $" + strconv.Itoa(len(args))
	}
	if e := get("entidade"); e != "" {
		args = append(args, e)
		where += " AND entidade = $" + strconv.Itoa(len(args))
	}
	if eid := get("entidade_id"); eid != "" {
		args = append(args, eid)
		where += " AND entidade_id = $" + strconv.Itoa(len(args))
	}
	if a := get("acao"); a != "" {
		args = append(args, a)
		where += " AND acao = $" + strconv.Itoa(len(args))
	}
	return where, args
}

func (h *Handler) ListarAuditLogs(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()

	where, args := auditLogsFilterWhere(user.TenantID, q)

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
		"SELECT id, user_id, modulo, entidade, entidade_id, acao, detalhes, ip_address, created_at FROM auditoria.audit_logs WHERE "+
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
	h.db.QueryRow(r.Context(), "SELECT COUNT(*) FROM auditoria.audit_logs WHERE "+where, countArgs...).Scan(&total)

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
		  FROM auditoria.audit_logs WHERE id = $1 AND tenant_id = $2`, id, user.TenantID).
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
		INSERT INTO auditoria.audit_logs (tenant_id, user_id, modulo, entidade, entidade_id, acao, detalhes, ip_address)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
		user.TenantID, user.ID, body.Modulo, body.Entidade, body.EntidadeID,
		body.Acao, body.Detalhes, r.RemoteAddr).Scan(&id)
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// auditLogsExportLimite é o número máximo de linhas devolvidas por
// exportação — mesmo racional de auditEventsExportLimite (audit_events.go).
const auditLogsExportLimite = 20000

// ExportarAuditLogsCSV exporta o log operacional do tenant (filtrado pelos
// mesmos parâmetros de ListarAuditLogs) para CSV.
func (h *Handler) ExportarAuditLogsCSV(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	where, args := auditLogsFilterWhere(user.TenantID, r.URL.Query())
	args = append(args, auditLogsExportLimite)

	rows, err := h.db.Query(r.Context(),
		"SELECT id, user_id, modulo, entidade, entidade_id, acao, ip_address, created_at FROM auditoria.audit_logs WHERE "+
			where+" ORDER BY created_at DESC LIMIT $"+strconv.Itoa(len(args)),
		args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	w.Header().Set("Content-Type", "text/csv; charset=utf-8")
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="audit-logs-%s.csv"`, time.Now().Format("20060102-150405")))
	w.WriteHeader(http.StatusOK)
	w.Write([]byte{0xEF, 0xBB, 0xBF})

	cw := csv.NewWriter(w)
	cw.Write([]string{"id", "user_id", "modulo", "entidade", "entidade_id", "acao", "ip_address", "created_at"})
	for rows.Next() {
		var id int64
		var userID, entidadeID *int64
		var modulo, entidade, acao string
		var ipAddress *string
		var createdAt time.Time
		if rows.Scan(&id, &userID, &modulo, &entidade, &entidadeID, &acao, &ipAddress, &createdAt) != nil {
			continue
		}
		cw.Write([]string{
			strconv.FormatInt(id, 10), derefStrOrEmpty(userID), modulo, entidade, derefStrOrEmpty(entidadeID),
			acao, derefStr(ipAddress), createdAt.Format(time.RFC3339),
		})
	}
	cw.Flush()
}
