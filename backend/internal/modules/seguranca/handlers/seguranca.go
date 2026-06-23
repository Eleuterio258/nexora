package handlers

import (
	"encoding/json"
	"net/http"

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

// ── Políticas de segurança ───────────────────────────────────────

func (h *Handler) ListarPoliticas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.codigo),'[]') FROM (
		SELECT * FROM seguranca.security_policies WHERE tenant_id=$1) x`, u.TenantID)
}

func (h *Handler) CriarPolitica(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		Codigo       string          `json:"codigo"`
		Nome         string          `json:"nome"`
		Configuracao json.RawMessage `json:"configuracao"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Codigo == "" || b.Nome == "" {
		jsonErr(w, "codigo e nome sao obrigatorios", http.StatusBadRequest)
		return
	}
	cfg := b.Configuracao
	if len(cfg) == 0 {
		cfg = json.RawMessage(`{}`)
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO seguranca.security_policies
		(tenant_id,codigo,nome,configuracao) VALUES ($1,$2,$3,$4) RETURNING id`,
		u.TenantID, b.Codigo, b.Nome, cfg).Scan(&id)
	if err != nil {
		jsonErr(w, "Politica duplicada ou invalida", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarPolitica(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var b struct {
		Nome         *string         `json:"nome"`
		Configuracao json.RawMessage `json:"configuracao"`
		Activo       *bool           `json:"activo"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil {
		jsonErr(w, "Corpo invalido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `UPDATE seguranca.security_policies
		SET nome=COALESCE($1,nome),
		    configuracao=COALESCE(NULLIF($2::text,'')::jsonb,configuracao),
		    activo=COALESCE($3,activo),
		    updated_at=NOW()
		WHERE id=$4 AND tenant_id=$5`,
		b.Nome, nullableJSON(b.Configuracao), b.Activo, id, u.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Politica nao encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// ── MFA Enrollments ──────────────────────────────────────────────

func (h *Handler) ListarMFAEnrollments(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.created_at DESC),'[]') FROM (
		SELECT id,user_id,metodo,verified,created_at
		FROM seguranca.security_mfa_enrollments WHERE tenant_id=$1) x`, u.TenantID)
}

// ── IP Allowlist ─────────────────────────────────────────────────

func (h *Handler) ListarIPAllowlist(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.ip_or_cidr),'[]') FROM (
		SELECT * FROM seguranca.security_ip_allowlist WHERE tenant_id=$1) x`, u.TenantID)
}

func (h *Handler) AdicionarIP(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		IPOrCIDR  string  `json:"ip_or_cidr"`
		Descricao *string `json:"descricao"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.IPOrCIDR == "" {
		jsonErr(w, "ip_or_cidr e obrigatorio", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO seguranca.security_ip_allowlist
		(tenant_id,ip_or_cidr,descricao) VALUES ($1,$2,$3) RETURNING id`,
		u.TenantID, b.IPOrCIDR, b.Descricao).Scan(&id)
	if err != nil {
		jsonErr(w, "IP duplicado ou invalido", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) RemoverIP(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(),
		`DELETE FROM seguranca.security_ip_allowlist WHERE id=$1 AND tenant_id=$2`, id, u.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "IP nao encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// nullableJSON converte json.RawMessage em *string para uso em COALESCE
func nullableJSON(raw json.RawMessage) *string {
	if len(raw) == 0 || string(raw) == "null" {
		return nil
	}
	s := string(raw)
	return &s
}
