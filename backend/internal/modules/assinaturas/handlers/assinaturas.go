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

// ── Planos ──────────────────────────────────────────────────────

func (h *Handler) ListarPlanos(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome),'[]') FROM (
		SELECT id,codigo,nome,billing_period,preco,moeda,activo,created_at
		FROM assinaturas.subscription_plans WHERE tenant_id=$1) x`, u.TenantID)
}

func (h *Handler) CriarPlano(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		Codigo        string  `json:"codigo"`
		Nome          string  `json:"nome"`
		BillingPeriod string  `json:"billing_period"`
		Preco         float64 `json:"preco"`
		Moeda         string  `json:"moeda"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Codigo == "" || b.Nome == "" {
		jsonErr(w, "codigo e nome sao obrigatorios", http.StatusBadRequest)
		return
	}
	if b.BillingPeriod == "" {
		b.BillingPeriod = "mensal"
	}
	if b.Moeda == "" {
		b.Moeda = "MZN"
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO assinaturas.subscription_plans
		(tenant_id,codigo,nome,billing_period,preco,moeda) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		u.TenantID, b.Codigo, b.Nome, b.BillingPeriod, b.Preco, b.Moeda).Scan(&id)
	if err != nil {
		jsonErr(w, "Plano duplicado ou invalido", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarPlano(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var b struct {
		Nome   *string  `json:"nome"`
		Preco  *float64 `json:"preco"`
		Activo *bool    `json:"activo"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil {
		jsonErr(w, "Corpo invalido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `UPDATE assinaturas.subscription_plans
		SET nome=COALESCE($1,nome), preco=COALESCE($2,preco), activo=COALESCE($3,activo), updated_at=NOW()
		WHERE id=$4 AND tenant_id=$5`, b.Nome, b.Preco, b.Activo, id, u.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Plano nao encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// ── Assinaturas ─────────────────────────────────────────────────

func (h *Handler) ListarAssinaturas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "s.tenant_id=$1"
	args := []any{u.TenantID}
	status := strings.TrimSpace(r.URL.Query().Get("status"))
	if status != "" {
		args = append(args, status)
		where += " AND s.status=$2"
	}
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.created_at DESC),'[]') FROM (
		SELECT s.*,p.nome plano_nome FROM assinaturas.subscriptions s
		JOIN assinaturas.subscription_plans p ON p.id=s.plan_id WHERE `+where+`) x`, args...)
}

func (h *Handler) CriarAssinatura(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		PlanID    int64   `json:"plan_id"`
		Numero    string  `json:"numero"`
		StartsAt  string  `json:"starts_at"`
		UnitPrice float64 `json:"unit_price"`
		Moeda     string  `json:"moeda"`
		CompanyID *int64  `json:"company_id"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.PlanID == 0 || b.Numero == "" || b.StartsAt == "" {
		jsonErr(w, "plan_id, numero e starts_at sao obrigatorios", http.StatusBadRequest)
		return
	}
	if b.Moeda == "" {
		b.Moeda = "MZN"
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO assinaturas.subscriptions
		(tenant_id,company_id,plan_id,numero,starts_at,unit_price,moeda,created_by)
		VALUES ($1,$2,$3,$4,$5::date,$6,$7,$8) RETURNING id`,
		u.TenantID, b.CompanyID, b.PlanID, b.Numero, b.StartsAt, b.UnitPrice, b.Moeda, u.ID).Scan(&id)
	if err != nil {
		jsonErr(w, "Numero de assinatura duplicado ou plano invalido", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) CancelarAssinatura(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(), `UPDATE assinaturas.subscriptions
		SET status='cancelada',updated_at=NOW() WHERE id=$1 AND tenant_id=$2 AND status NOT IN ('cancelada')`,
		id, u.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Assinatura nao encontrada ou ja cancelada", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

func (h *Handler) RenovarAssinatura(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var b struct {
		NextBillingDate string `json:"next_billing_date"`
		EndsAt          string `json:"ends_at"`
	}
	json.NewDecoder(r.Body).Decode(&b)
	tag, err := h.db.Exec(r.Context(), `UPDATE assinaturas.subscriptions
		SET status='activa',
		    next_billing_date=COALESCE(NULLIF($1,'')::date,next_billing_date),
		    ends_at=COALESCE(NULLIF($2,'')::date,ends_at),
		    updated_at=NOW()
		WHERE id=$3 AND tenant_id=$4`,
		b.NextBillingDate, b.EndsAt, id, u.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Assinatura nao encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

func (h *Handler) ListarFacturasAssinatura(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.due_date DESC),'[]') FROM (
		SELECT * FROM assinaturas.subscription_invoices
		WHERE tenant_id=$1 AND subscription_id=$2) x`, u.TenantID, id)
}

func (h *Handler) ListarUtilizacaoAssinatura(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.periodo DESC),'[]') FROM (
		SELECT * FROM assinaturas.subscription_usage
		WHERE tenant_id=$1 AND subscription_id=$2) x`, u.TenantID, id)
}
