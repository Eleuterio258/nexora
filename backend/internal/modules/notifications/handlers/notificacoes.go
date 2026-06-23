package handlers

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) listAll(w http.ResponseWriter, r *http.Request, query string, args ...any) {
	var raw []byte
	if err := h.db.QueryRow(r.Context(), query, args...).Scan(&raw); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

// ── Canais de notificação ────────────────────────────────────────

func (h *Handler) ListarCanais(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome),'[]') FROM (
		SELECT * FROM notifications.notification_channels WHERE tenant_id=$1) x`, u.TenantID)
}

func (h *Handler) CriarCanal(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		Nome       string          `json:"nome"`
		Tipo       string          `json:"tipo"`
		Configuracao json.RawMessage `json:"configuracao"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Nome == "" || b.Tipo == "" {
		jsonErr(w, "nome e tipo sao obrigatorios", http.StatusBadRequest)
		return
	}
	cfg := b.Configuracao
	if len(cfg) == 0 {
		cfg = json.RawMessage(`{}`)
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO notifications.notification_channels
		(tenant_id,nome,tipo,configuracao) VALUES ($1,$2,$3,$4) RETURNING id`,
		u.TenantID, b.Nome, b.Tipo, cfg).Scan(&id)
	if err != nil {
		jsonErr(w, "Canal invalido ou duplicado", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ── Templates ────────────────────────────────────────────────────

func (h *Handler) ListarTemplates(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "tenant_id=$1"
	args := []any{u.TenantID}
	canal := strings.TrimSpace(r.URL.Query().Get("canal_tipo"))
	if canal != "" {
		args = append(args, canal)
		where += " AND canal_tipo=$2"
	}
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.codigo),'[]') FROM (
		SELECT * FROM notifications.notification_templates WHERE `+where+`) x`, args...)
}

func (h *Handler) CriarTemplate(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		Codigo    string          `json:"codigo"`
		CanalTipo string          `json:"canal_tipo"`
		Assunto   *string         `json:"assunto"`
		Corpo     string          `json:"corpo"`
		Variaveis json.RawMessage `json:"variaveis"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Codigo == "" || b.CanalTipo == "" || b.Corpo == "" {
		jsonErr(w, "codigo, canal_tipo e corpo sao obrigatorios", http.StatusBadRequest)
		return
	}
	vars := b.Variaveis
	if len(vars) == 0 {
		vars = json.RawMessage(`[]`)
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO notifications.notification_templates
		(tenant_id,codigo,canal_tipo,assunto,corpo,variaveis) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		u.TenantID, b.Codigo, b.CanalTipo, b.Assunto, b.Corpo, vars).Scan(&id)
	if err != nil {
		jsonErr(w, "Template duplicado ou invalido", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarTemplate(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var b struct {
		Assunto *string `json:"assunto"`
		Corpo   *string `json:"corpo"`
		Activo  *bool   `json:"activo"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil {
		jsonErr(w, "Corpo invalido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `UPDATE notifications.notification_templates
		SET assunto=COALESCE($1,assunto),
		    corpo=COALESCE($2,corpo),
		    activo=COALESCE($3,activo),
		    updated_at=NOW()
		WHERE id=$4 AND tenant_id=$5`, b.Assunto, b.Corpo, b.Activo, id, u.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Template nao encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// ── Mensagens ────────────────────────────────────────────────────

func (h *Handler) ListarMensagens(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "tenant_id=$1"
	args := []any{u.TenantID}
	status := strings.TrimSpace(r.URL.Query().Get("status"))
	if status != "" {
		args = append(args, status)
		where += " AND status=$2"
	}
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.created_at DESC),'[]') FROM (
		SELECT * FROM notifications.notification_messages WHERE `+where+`) x`, args...)
}

func (h *Handler) EnviarNotificacao(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		CanalTipo    string `json:"canal_tipo"`
		Destinatario string `json:"destinatario"`
		Corpo        string `json:"corpo"`
		TemplateID   *int64 `json:"template_id"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.CanalTipo == "" || b.Destinatario == "" || b.Corpo == "" {
		jsonErr(w, "canal_tipo, destinatario e corpo sao obrigatorios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO notifications.notification_messages
		(tenant_id,canal_tipo,destinatario,corpo,template_id) VALUES ($1,$2,$3,$4,$5) RETURNING id`,
		u.TenantID, b.CanalTipo, b.Destinatario, b.Corpo, b.TemplateID).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro ao criar mensagem", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}
