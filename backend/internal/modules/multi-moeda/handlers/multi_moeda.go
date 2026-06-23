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

// ── Moedas (tabela global, sem tenant_id) ───────────────────────

func (h *Handler) ListarMoedas(w http.ResponseWriter, r *http.Request) {
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.code),'[]') FROM (
		SELECT id,code,name,symbol,decimals,active FROM multi_moeda.currencies) x`)
}

func (h *Handler) CriarMoeda(w http.ResponseWriter, r *http.Request) {
	var b struct {
		Code     string `json:"code"`
		Name     string `json:"name"`
		Symbol   string `json:"symbol"`
		Decimals int    `json:"decimals"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Code == "" || b.Name == "" {
		jsonErr(w, "code e name sao obrigatorios", http.StatusBadRequest)
		return
	}
	if b.Decimals == 0 {
		b.Decimals = 2
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO multi_moeda.currencies (code,name,symbol,decimals)
		VALUES ($1,$2,$3,$4) RETURNING id`, b.Code, b.Name, b.Symbol, b.Decimals).Scan(&id)
	if err != nil {
		jsonErr(w, "Moeda duplicada ou invalida", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ── Taxas de câmbio ──────────────────────────────────────────────

func (h *Handler) ListarTaxasCambio(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.effective_date DESC),'[]') FROM (
		SELECT e.*,
		       b.code base_code, q.code quote_code
		FROM multi_moeda.exchange_rates e
		JOIN multi_moeda.currencies b ON b.id=e.base_currency_id
		JOIN multi_moeda.currencies q ON q.id=e.quote_currency_id
		WHERE e.tenant_id=$1) x`, u.TenantID)
}

func (h *Handler) CriarTaxaCambio(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		BaseCurrencyID  int64   `json:"base_currency_id"`
		QuoteCurrencyID int64   `json:"quote_currency_id"`
		Rate            float64 `json:"rate"`
		Source          string  `json:"source"`
		EffectiveDate   string  `json:"effective_date"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.BaseCurrencyID == 0 || b.QuoteCurrencyID == 0 || b.Rate <= 0 {
		jsonErr(w, "base_currency_id, quote_currency_id e rate sao obrigatorios", http.StatusBadRequest)
		return
	}
	if b.Source == "" {
		b.Source = "manual"
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO multi_moeda.exchange_rates
		(tenant_id,base_currency_id,quote_currency_id,rate,source,effective_date)
		VALUES ($1,$2,$3,$4,$5,COALESCE(NULLIF($6,'')::date,CURRENT_DATE)) RETURNING id`,
		u.TenantID, b.BaseCurrencyID, b.QuoteCurrencyID, b.Rate, b.Source, b.EffectiveDate).Scan(&id)
	if err != nil {
		jsonErr(w, "Taxa invalida ou duplicada", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ── Moedas do tenant ─────────────────────────────────────────────

func (h *Handler) ListarMoedasTenant(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listAll(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.is_base DESC, x.code),'[]') FROM (
		SELECT tc.*,c.code,c.name,c.symbol,c.decimals
		FROM multi_moeda.tenant_currencies tc
		JOIN multi_moeda.currencies c ON c.id=tc.currency_id
		WHERE tc.tenant_id=$1) x`, u.TenantID)
}

func (h *Handler) AdicionarMoedaTenant(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		CurrencyID int64 `json:"currency_id"`
		IsBase     bool  `json:"is_base"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.CurrencyID == 0 {
		jsonErr(w, "currency_id e obrigatorio", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO multi_moeda.tenant_currencies
		(tenant_id,currency_id,is_base) VALUES ($1,$2,$3)
		ON CONFLICT (tenant_id,currency_id) DO UPDATE SET is_base=$3,active=true RETURNING id`,
		u.TenantID, b.CurrencyID, b.IsBase).Scan(&id)
	if err != nil {
		jsonErr(w, "Moeda invalida", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) RemoverMoedaTenant(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(), `UPDATE multi_moeda.tenant_currencies
		SET active=false WHERE id=$1 AND tenant_id=$2 AND is_base=false`, id, u.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Moeda nao encontrada ou e a moeda base", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// ── Conversão ────────────────────────────────────────────────────

func (h *Handler) ConverterValor(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		FromCurrencyID int64   `json:"from_currency_id"`
		ToCurrencyID   int64   `json:"to_currency_id"`
		Valor          float64 `json:"valor"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.FromCurrencyID == 0 || b.ToCurrencyID == 0 || b.Valor <= 0 {
		jsonErr(w, "from_currency_id, to_currency_id e valor sao obrigatorios", http.StatusBadRequest)
		return
	}
	if b.FromCurrencyID == b.ToCurrencyID {
		jsonOK(w, map[string]any{"resultado": b.Valor, "rate": 1}, http.StatusOK)
		return
	}
	var rate float64
	err := h.db.QueryRow(r.Context(), `SELECT rate FROM multi_moeda.exchange_rates
		WHERE tenant_id=$1 AND base_currency_id=$2 AND quote_currency_id=$3
		ORDER BY effective_date DESC LIMIT 1`,
		u.TenantID, b.FromCurrencyID, b.ToCurrencyID).Scan(&rate)
	if err != nil {
		jsonErr(w, "Taxa de cambio nao encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"resultado": b.Valor * rate, "rate": rate}, http.StatusOK)
}
