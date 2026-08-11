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

// auditEventsFilterWhere constrói a cláusula WHERE + args a partir dos
// mesmos filtros de query usados por ListarAuditEvents/ExportarAuditEventsCSV.
func auditEventsFilterWhere(tenantID int64, q map[string][]string) (string, []any) {
	get := func(k string) string {
		if v, ok := q[k]; ok && len(v) > 0 {
			return v[0]
		}
		return ""
	}
	where := "tenant_id = $1"
	args := []any{tenantID}
	if m := get("module_name"); m != "" {
		args = append(args, m)
		where += " AND module_name = $" + strconv.Itoa(len(args))
	}
	if a := get("action"); a != "" {
		args = append(args, a)
		where += " AND action = $" + strconv.Itoa(len(args))
	}
	if et := get("entity_type"); et != "" {
		args = append(args, et)
		where += " AND entity_type = $" + strconv.Itoa(len(args))
	}
	if eid := get("entity_id"); eid != "" {
		args = append(args, eid)
		where += " AND entity_id = $" + strconv.Itoa(len(args))
	}
	if uid := get("actor_user_id"); uid != "" {
		args = append(args, uid)
		where += " AND actor_user_id = $" + strconv.Itoa(len(args))
	}
	if s := get("status"); s != "" {
		args = append(args, s)
		where += " AND status = $" + strconv.Itoa(len(args))
	}
	return where, args
}

// ListarAuditEvents lista a cadeia de eventos legais (auditoria.audit_events)
// do tenant, com filtros opcionais. Só leitura — a escrita é feita pelos
// próprios módulos via contracts.LegalAuditPort (ver internal/shared/adapters/legal_audit.go).
func (h *Handler) ListarAuditEvents(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()

	where, args := auditEventsFilterWhere(user.TenantID, q)

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
		`SELECT id, actor_user_id, actor_email, actor_nome, service_name, module_name, action,
		        entity_type, entity_id, status, ip_address, user_agent,
		        metadata, payload_before, payload_after, previous_hash, event_hash, created_at
		   FROM auditoria.audit_events WHERE `+where+
			` ORDER BY id DESC LIMIT $`+strconv.Itoa(n-1)+` OFFSET $`+strconv.Itoa(n),
		args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID            int64           `json:"id"`
		ActorUserID   *int64          `json:"actor_user_id"`
		ActorEmail    *string         `json:"actor_email"`
		ActorNome     *string         `json:"actor_nome"`
		ServiceName   string          `json:"service_name"`
		ModuleName    string          `json:"module_name"`
		Action        string          `json:"action"`
		EntityType    string          `json:"entity_type"`
		EntityID      *string         `json:"entity_id"`
		Status        string          `json:"status"`
		IPAddress     *string         `json:"ip_address"`
		UserAgent     *string         `json:"user_agent"`
		Metadata      json.RawMessage `json:"metadata"`
		PayloadBefore json.RawMessage `json:"payload_before"`
		PayloadAfter  json.RawMessage `json:"payload_after"`
		PreviousHash  *string         `json:"previous_hash"`
		EventHash     string          `json:"event_hash"`
		CreatedAt     time.Time       `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var e Row
		if rows.Scan(&e.ID, &e.ActorUserID, &e.ActorEmail, &e.ActorNome, &e.ServiceName, &e.ModuleName, &e.Action,
			&e.EntityType, &e.EntityID, &e.Status, &e.IPAddress, &e.UserAgent,
			&e.Metadata, &e.PayloadBefore, &e.PayloadAfter, &e.PreviousHash, &e.EventHash, &e.CreatedAt) == nil {
			data = append(data, e)
		}
	}

	var total int
	countArgs := args[:len(args)-2]
	h.db.QueryRow(r.Context(), "SELECT COUNT(*) FROM auditoria.audit_events WHERE "+where, countArgs...).Scan(&total)

	jsonOK(w, map[string]any{
		"data": data,
		"meta": map[string]int{"total": total, "page": page, "limit": limit},
	}, http.StatusOK)
}

// ObterAuditEvent devolve um evento legal específico.
func (h *Handler) ObterAuditEvent(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var e struct {
		ID            int64           `json:"id"`
		ActorUserID   *int64          `json:"actor_user_id"`
		ActorEmail    *string         `json:"actor_email"`
		ActorNome     *string         `json:"actor_nome"`
		ServiceName   string          `json:"service_name"`
		ModuleName    string          `json:"module_name"`
		Action        string          `json:"action"`
		EntityType    string          `json:"entity_type"`
		EntityID      *string         `json:"entity_id"`
		Status        string          `json:"status"`
		IPAddress     *string         `json:"ip_address"`
		UserAgent     *string         `json:"user_agent"`
		Metadata      json.RawMessage `json:"metadata"`
		PayloadBefore json.RawMessage `json:"payload_before"`
		PayloadAfter  json.RawMessage `json:"payload_after"`
		PreviousHash  *string         `json:"previous_hash"`
		EventHash     string          `json:"event_hash"`
		CreatedAt     time.Time       `json:"created_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, actor_user_id, actor_email, actor_nome, service_name, module_name, action,
		       entity_type, entity_id, status, ip_address, user_agent,
		       metadata, payload_before, payload_after, previous_hash, event_hash, created_at
		  FROM auditoria.audit_events WHERE id = $1 AND tenant_id = $2`, id, user.TenantID).
		Scan(&e.ID, &e.ActorUserID, &e.ActorEmail, &e.ActorNome, &e.ServiceName, &e.ModuleName, &e.Action,
			&e.EntityType, &e.EntityID, &e.Status, &e.IPAddress, &e.UserAgent,
			&e.Metadata, &e.PayloadBefore, &e.PayloadAfter, &e.PreviousHash, &e.EventHash, &e.CreatedAt)
	if err != nil {
		jsonErr(w, "Evento não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, e, http.StatusOK)
}

// VerificarIntegridadeAuditEvents percorre a cadeia de eventos legais do
// tenant, do mais antigo ao mais recente, e confirma que cada previous_hash
// corresponde exactamente ao event_hash do evento anterior (e que o primeiro
// evento não tem previous_hash) — ou seja, que nenhum evento foi apagado,
// inserido fora de ordem, ou teve o seu link para o evento anterior alterado.
//
// Não recalcula o event_hash a partir do conteúdo (module_name/action/
// metadata/etc.): o jsonb do Postgres não preserva byte-a-byte a formatação
// da serialização original (internal/shared/adapters/legal_audit.go usa
// encoding/json do Go antes do INSERT), por isso reconstruir esse hash a
// partir do que a BD devolve produziria falsos positivos de "corrupção".
// A verificação de ligação sequencial é a garantia fiável que se consegue
// dar sem um segundo armazenamento fora da BD (ex.: ancoragem externa).
func (h *Handler) VerificarIntegridadeAuditEvents(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	rows, err := h.db.Query(r.Context(), `
		SELECT id, previous_hash, event_hash
		  FROM auditoria.audit_events
		 WHERE tenant_id = $1
		 ORDER BY id ASC`, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type quebra struct {
		EventoID int64  `json:"evento_id"`
		Motivo   string `json:"motivo"`
	}
	var quebras []quebra
	var total int
	var hashAnterior *string
	primeiro := true

	for rows.Next() {
		var id int64
		var previousHash *string
		var eventHash string
		if rows.Scan(&id, &previousHash, &eventHash) != nil {
			continue
		}
		total++

		if primeiro {
			if previousHash != nil {
				quebras = append(quebras, quebra{EventoID: id, Motivo: "primeiro evento da cadeia tem previous_hash preenchido (deveria ser nulo)"})
			}
			primeiro = false
		} else {
			switch {
			case previousHash == nil:
				quebras = append(quebras, quebra{EventoID: id, Motivo: "previous_hash em falta"})
			case hashAnterior == nil || *previousHash != *hashAnterior:
				quebras = append(quebras, quebra{EventoID: id, Motivo: "previous_hash não corresponde ao event_hash do evento anterior"})
			}
		}
		eh := eventHash
		hashAnterior = &eh
	}

	jsonOK(w, map[string]any{
		"integro":       len(quebras) == 0,
		"total_eventos": total,
		"quebras":       quebras,
	}, http.StatusOK)
}

// auditEventsExportLimite é o número máximo de linhas devolvidas por
// exportação — evita que um filtro largo (ou nenhum) tente materializar
// anos de auditoria numa só resposta.
const auditEventsExportLimite = 20000

// ExportarAuditEventsCSV exporta a cadeia de eventos legais do tenant
// (filtrada pelos mesmos parâmetros de ListarAuditEvents) para CSV.
func (h *Handler) ExportarAuditEventsCSV(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	where, args := auditEventsFilterWhere(user.TenantID, r.URL.Query())
	args = append(args, auditEventsExportLimite)

	rows, err := h.db.Query(r.Context(),
		`SELECT id, actor_user_id, actor_email, actor_nome, service_name, module_name, action,
		        entity_type, entity_id, status, ip_address, event_hash, created_at
		   FROM auditoria.audit_events WHERE `+where+
			` ORDER BY id DESC LIMIT $`+strconv.Itoa(len(args)),
		args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	w.Header().Set("Content-Type", "text/csv; charset=utf-8")
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="audit-events-%s.csv"`, time.Now().Format("20060102-150405")))
	w.WriteHeader(http.StatusOK)
	w.Write([]byte{0xEF, 0xBB, 0xBF})

	cw := csv.NewWriter(w)
	cw.Write([]string{"id", "actor_user_id", "actor_email", "actor_nome", "service_name", "module_name", "action",
		"entity_type", "entity_id", "status", "ip_address", "event_hash", "created_at"})
	for rows.Next() {
		var id int64
		var actorUserID *int64
		var actorEmail, actorNome, serviceName, moduleName, action, entityType, entityID, status, ipAddress, eventHash *string
		var createdAt time.Time
		if rows.Scan(&id, &actorUserID, &actorEmail, &actorNome, &serviceName, &moduleName, &action,
			&entityType, &entityID, &status, &ipAddress, &eventHash, &createdAt) != nil {
			continue
		}
		cw.Write([]string{
			strconv.FormatInt(id, 10), derefStrOrEmpty(actorUserID), derefStr(actorEmail), derefStr(actorNome),
			derefStr(serviceName), derefStr(moduleName), derefStr(action), derefStr(entityType), derefStr(entityID),
			derefStr(status), derefStr(ipAddress), derefStr(eventHash), createdAt.Format(time.RFC3339),
		})
	}
	cw.Flush()
}

func derefStr(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

func derefStrOrEmpty(n *int64) string {
	if n == nil {
		return ""
	}
	return strconv.FormatInt(*n, 10)
}
