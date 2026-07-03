package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// ── Settings ──────────────────────────────────────────────────────────────────

func (h *Handler) ListarSettings(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	escopo := r.URL.Query().Get("escopo")

	where := "(tenant_id = $1 OR escopo = 'global')"
	args := []any{user.TenantID}
	if escopo != "" {
		args = append(args, escopo)
		where += " AND escopo = $2"
	}

	rows, _ := h.db.Query(r.Context(),
		"SELECT id, tenant_id, chave, valor, escopo FROM settings WHERE "+where+" ORDER BY chave", args...)
	defer rows.Close()
	type Row struct {
		ID       int64   `json:"id"`
		TenantID *int64  `json:"tenant_id"`
		Chave    string  `json:"chave"`
		Valor    *string `json:"valor"`
		Escopo   string  `json:"escopo"`
	}
	data := []Row{}
	for rows.Next() {
		var s Row
		if rows.Scan(&s.ID, &s.TenantID, &s.Chave, &s.Valor, &s.Escopo) == nil {
			data = append(data, s)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) GuardarSetting(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Chave  string  `json:"chave"`
		Valor  *string `json:"valor"`
		Escopo *string `json:"escopo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Chave == "" {
		jsonErr(w, "chave é obrigatória", http.StatusBadRequest)
		return
	}
	escopo := "tenant"
	if body.Escopo != nil {
		escopo = *body.Escopo
	}
	h.db.Exec(r.Context(), `
		INSERT INTO settings (tenant_id, chave, valor, escopo)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (tenant_id, chave) DO UPDATE SET valor = EXCLUDED.valor, escopo = EXCLUDED.escopo`,
		user.TenantID, body.Chave, body.Valor, escopo)
	w.WriteHeader(http.StatusNoContent)
}

// ── Currencies ────────────────────────────────────────────────────────────────

func (h *Handler) ListarMoedas(w http.ResponseWriter, r *http.Request) {
	rows, _ := h.db.Query(r.Context(), `SELECT id, codigo, nome, simbolo, ativa FROM currencies ORDER BY codigo`)
	defer rows.Close()
	type Row struct {
		ID      int64   `json:"id"`
		Codigo  string  `json:"codigo"`
		Nome    string  `json:"nome"`
		Simbolo *string `json:"simbolo"`
		Ativa   bool    `json:"ativa"`
	}
	data := []Row{}
	for rows.Next() {
		var c Row
		if rows.Scan(&c.ID, &c.Codigo, &c.Nome, &c.Simbolo, &c.Ativa) == nil {
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarMoeda(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Codigo  string  `json:"codigo"`
		Nome    string  `json:"nome"`
		Simbolo *string `json:"simbolo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO currencies (codigo, nome, simbolo) VALUES ($1,$2,$3) RETURNING id`,
		body.Codigo, body.Nome, body.Simbolo).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Moeda já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ── Exchange Rates ────────────────────────────────────────────────────────────

func (h *Handler) ListarTaxasCambio(w http.ResponseWriter, r *http.Request) {
	rows, _ := h.db.Query(r.Context(), `
		SELECT er.id, f.codigo, t.codigo, er.rate, er.rate_date
		  FROM exchange_rates er
		  JOIN currencies f ON f.id = er.from_currency_id
		  JOIN currencies t ON t.id = er.to_currency_id
		  ORDER BY er.rate_date DESC`)
	defer rows.Close()
	type Row struct {
		ID       int64     `json:"id"`
		De       string    `json:"de"`
		Para     string    `json:"para"`
		Rate     float64   `json:"rate"`
		RateDate time.Time `json:"rate_date"`
	}
	data := []Row{}
	for rows.Next() {
		var e Row
		if rows.Scan(&e.ID, &e.De, &e.Para, &e.Rate, &e.RateDate) == nil {
			data = append(data, e)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarTaxaCambio(w http.ResponseWriter, r *http.Request) {
	var body struct {
		FromCurrencyID int64   `json:"from_currency_id"`
		ToCurrencyID   int64   `json:"to_currency_id"`
		Rate           float64 `json:"rate"`
		RateDate       string  `json:"rate_date"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.FromCurrencyID == 0 || body.ToCurrencyID == 0 {
		jsonErr(w, "from_currency_id, to_currency_id e rate são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	h.db.QueryRow(r.Context(), `
		INSERT INTO exchange_rates (from_currency_id, to_currency_id, rate, rate_date)
		VALUES ($1,$2,$3,COALESCE($4::date, CURRENT_DATE)) RETURNING id`,
		body.FromCurrencyID, body.ToCurrencyID, body.Rate, body.RateDate).Scan(&id)
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ── Countries ─────────────────────────────────────────────────────────────────

func (h *Handler) ListarPaises(w http.ResponseWriter, r *http.Request) {
	rows, _ := h.db.Query(r.Context(), `SELECT id, codigo, nome FROM countries ORDER BY nome`)
	defer rows.Close()
	type Row struct {
		ID     int64  `json:"id"`
		Codigo string `json:"codigo"`
		Nome   string `json:"nome"`
	}
	data := []Row{}
	for rows.Next() {
		var c Row
		if rows.Scan(&c.ID, &c.Codigo, &c.Nome) == nil {
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarPais(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Codigo string `json:"codigo"`
		Nome   string `json:"nome"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	h.db.QueryRow(r.Context(), `INSERT INTO countries (codigo, nome) VALUES ($1,$2) ON CONFLICT DO NOTHING RETURNING id`,
		body.Codigo, body.Nome).Scan(&id)
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ── Cities ────────────────────────────────────────────────────────────────────

func (h *Handler) ListarCidades(w http.ResponseWriter, r *http.Request) {
	countryID := r.URL.Query().Get("country_id")
	where := "1=1"
	args := []any{}
	if countryID != "" {
		args = append(args, countryID)
		where = "country_id = $1"
	}
	rows, _ := h.db.Query(r.Context(), "SELECT id, country_id, nome FROM cities WHERE "+where+" ORDER BY nome", args...)
	defer rows.Close()
	type Row struct {
		ID        int64  `json:"id"`
		CountryID *int64 `json:"country_id"`
		Nome      string `json:"nome"`
	}
	data := []Row{}
	for rows.Next() {
		var c Row
		if rows.Scan(&c.ID, &c.CountryID, &c.Nome) == nil {
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarCidade(w http.ResponseWriter, r *http.Request) {
	var body struct {
		CountryID *int64 `json:"country_id"`
		Nome      string `json:"nome"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Nome == "" {
		jsonErr(w, "nome é obrigatório", http.StatusBadRequest)
		return
	}
	var id int64
	h.db.QueryRow(r.Context(), `INSERT INTO cities (country_id, nome) VALUES ($1,$2) RETURNING id`,
		body.CountryID, body.Nome).Scan(&id)
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ── Languages ─────────────────────────────────────────────────────────────────

func (h *Handler) ListarIdiomas(w http.ResponseWriter, r *http.Request) {
	rows, _ := h.db.Query(r.Context(), `SELECT id, codigo, nome FROM languages ORDER BY nome`)
	defer rows.Close()
	type Row struct {
		ID     int64  `json:"id"`
		Codigo string `json:"codigo"`
		Nome   string `json:"nome"`
	}
	data := []Row{}
	for rows.Next() {
		var l Row
		if rows.Scan(&l.ID, &l.Codigo, &l.Nome) == nil {
			data = append(data, l)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarIdioma(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Codigo string `json:"codigo"`
		Nome   string `json:"nome"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	h.db.QueryRow(r.Context(), `INSERT INTO languages (codigo, nome) VALUES ($1,$2) ON CONFLICT DO NOTHING RETURNING id`,
		body.Codigo, body.Nome).Scan(&id)
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ── Email Templates ───────────────────────────────────────────────────────────

func (h *Handler) ListarEmailTemplates(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, tenant_id, codigo, assunto FROM email_templates
		 WHERE tenant_id = $1 OR tenant_id IS NULL ORDER BY codigo`, user.TenantID)
	defer rows.Close()
	type Row struct {
		ID       int64  `json:"id"`
		TenantID *int64 `json:"tenant_id"`
		Codigo   string `json:"codigo"`
		Assunto  string `json:"assunto"`
	}
	data := []Row{}
	for rows.Next() {
		var t Row
		if rows.Scan(&t.ID, &t.TenantID, &t.Codigo, &t.Assunto) == nil {
			data = append(data, t)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarEmailTemplate(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo  string `json:"codigo"`
		Assunto string `json:"assunto"`
		Corpo   string `json:"corpo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Assunto == "" {
		jsonErr(w, "codigo, assunto e corpo são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	h.db.QueryRow(r.Context(), `INSERT INTO email_templates (tenant_id, codigo, assunto, corpo) VALUES ($1,$2,$3,$4) RETURNING id`,
		user.TenantID, body.Codigo, body.Assunto, body.Corpo).Scan(&id)
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ── SMS Templates ─────────────────────────────────────────────────────────────

func (h *Handler) ListarSMSTemplates(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, tenant_id, codigo, corpo FROM sms_templates
		 WHERE tenant_id = $1 OR tenant_id IS NULL ORDER BY codigo`, user.TenantID)
	defer rows.Close()
	type Row struct {
		ID       int64  `json:"id"`
		TenantID *int64 `json:"tenant_id"`
		Codigo   string `json:"codigo"`
		Corpo    string `json:"corpo"`
	}
	data := []Row{}
	for rows.Next() {
		var t Row
		if rows.Scan(&t.ID, &t.TenantID, &t.Codigo, &t.Corpo) == nil {
			data = append(data, t)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarSMSTemplate(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo string `json:"codigo"`
		Corpo  string `json:"corpo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Corpo == "" {
		jsonErr(w, "codigo e corpo são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	h.db.QueryRow(r.Context(), `INSERT INTO sms_templates (tenant_id, codigo, corpo) VALUES ($1,$2,$3) RETURNING id`,
		user.TenantID, body.Codigo, body.Corpo).Scan(&id)
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ── System Logs ───────────────────────────────────────────────────────────────

func (h *Handler) ListarSystemLogs(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	nivel := r.URL.Query().Get("nivel")
	where := "tenant_id = $1"
	args := []any{user.TenantID}
	if nivel != "" {
		args = append(args, nivel)
		where += " AND nivel = $2"
	}
	rows, _ := h.db.Query(r.Context(),
		"SELECT id, nivel, modulo, mensagem, created_at FROM system_logs WHERE "+where+" ORDER BY created_at DESC LIMIT 100",
		args...)
	defer rows.Close()
	type Row struct {
		ID        int64     `json:"id"`
		Nivel     string    `json:"nivel"`
		Modulo    *string   `json:"modulo"`
		Mensagem  string    `json:"mensagem"`
		CreatedAt time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var l Row
		if rows.Scan(&l.ID, &l.Nivel, &l.Modulo, &l.Mensagem, &l.CreatedAt) == nil {
			data = append(data, l)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// ── Integrations ─────────────────────────────────────────────────────────────

func (h *Handler) ListarIntegracoes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, codigo, nome, ativa FROM integrations WHERE tenant_id = $1 ORDER BY nome`, user.TenantID)
	defer rows.Close()
	type Row struct {
		ID     int64  `json:"id"`
		Codigo string `json:"codigo"`
		Nome   string `json:"nome"`
		Ativa  bool   `json:"ativa"`
	}
	data := []Row{}
	for rows.Next() {
		var i Row
		if rows.Scan(&i.ID, &i.Codigo, &i.Nome, &i.Ativa) == nil {
			data = append(data, i)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarIntegracao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo        string          `json:"codigo"`
		Nome          string          `json:"nome"`
		Configuracao  json.RawMessage `json:"configuracao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	h.db.QueryRow(r.Context(), `INSERT INTO integrations (tenant_id, codigo, nome, configuracao) VALUES ($1,$2,$3,$4) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Configuracao).Scan(&id)
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ── API Logs ──────────────────────────────────────────────────────────────────

func (h *Handler) ListarAPILogs(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, metodo, rota, status_code, duracao_ms, created_at
		  FROM api_logs WHERE tenant_id = $1 ORDER BY created_at DESC LIMIT 200`, user.TenantID)
	defer rows.Close()
	type Row struct {
		ID         int64     `json:"id"`
		Metodo     string    `json:"metodo"`
		Rota       string    `json:"rota"`
		StatusCode *int      `json:"status_code"`
		DuracaoMs  *int      `json:"duracao_ms"`
		CreatedAt  time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var l Row
		if rows.Scan(&l.ID, &l.Metodo, &l.Rota, &l.StatusCode, &l.DuracaoMs, &l.CreatedAt) == nil {
			data = append(data, l)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// ── (unused URL param helper) ─────────────────────────────────────────────────
var _ = chi.URLParam
