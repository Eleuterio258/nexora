package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

const fiscalPeriodSelect = `SELECT id, fiscal_year_id, ano, mes, data_inicio, data_fim, status, fechado_em, fechado_por FROM contabilidade.fiscal_periods`

type fiscalPeriodRow struct {
	ID           int64      `json:"id"`
	FiscalYearID *int64     `json:"fiscal_year_id"`
	Ano          int        `json:"ano"`
	Mes          int        `json:"mes"`
	DataInicio   time.Time  `json:"data_inicio"`
	DataFim      time.Time  `json:"data_fim"`
	Status       string     `json:"status"`
	FechadoEm    *time.Time `json:"fechado_em"`
	FechadoPor   *int64     `json:"fechado_por"`
}

func scanFiscalPeriods(rows pgx.Rows) []fiscalPeriodRow {
	data := []fiscalPeriodRow{}
	for rows.Next() {
		var p fiscalPeriodRow
		if rows.Scan(&p.ID, &p.FiscalYearID, &p.Ano, &p.Mes, &p.DataInicio, &p.DataFim, &p.Status, &p.FechadoEm, &p.FechadoPor) == nil {
			data = append(data, p)
		}
	}
	return data
}

func (h *Handler) ListarPeriodosFiscais(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("fiscal_year_id"); v != "" {
		args = append(args, v)
		where += " AND fiscal_year_id=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("status"); v != "" {
		args = append(args, v)
		where += " AND status=$" + strconv.Itoa(len(args))
	}
	rows, err := h.db.Query(r.Context(), fiscalPeriodSelect+` WHERE `+where+` ORDER BY ano, mes`, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	jsonOK(w, scanFiscalPeriods(rows), http.StatusOK)
}

func (h *Handler) CriarPeriodoFiscal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		FiscalYearID *int64 `json:"fiscal_year_id"`
		Ano          int    `json:"ano"`
		Mes          int    `json:"mes"`
		DataInicio   string `json:"data_inicio"`
		DataFim      string `json:"data_fim"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Ano == 0 || body.Mes < 1 || body.Mes > 12 || body.DataInicio == "" || body.DataFim == "" {
		jsonErr(w, "ano, mes (1-12), data_inicio e data_fim são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO contabilidade.fiscal_periods (tenant_id,fiscal_year_id,ano,mes,data_inicio,data_fim)
		VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		user.TenantID, body.FiscalYearID, body.Ano, body.Mes, body.DataInicio, body.DataFim).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Período fiscal já existe para este ano/mês", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterPeriodoFiscal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var p fiscalPeriodRow
	err := h.db.QueryRow(r.Context(), fiscalPeriodSelect+` WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).
		Scan(&p.ID, &p.FiscalYearID, &p.Ano, &p.Mes, &p.DataInicio, &p.DataFim, &p.Status, &p.FechadoEm, &p.FechadoPor)
	if err != nil {
		jsonErr(w, "Período fiscal não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, p, http.StatusOK)
}

func (h *Handler) AbrirPeriodoFiscal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(), `
		UPDATE contabilidade.fiscal_periods SET status='aberto', fechado_em=NULL, fechado_por=NULL
		WHERE id=$1 AND tenant_id=$2 AND status='fechado'`,
		id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Período fiscal não encontrado ou já está aberto", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) FecharPeriodoFiscal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(), `
		UPDATE contabilidade.fiscal_periods SET status='fechado', fechado_em=NOW(), fechado_por=$1
		WHERE id=$2 AND tenant_id=$3 AND status='aberto'`,
		user.ID, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Período fiscal não encontrado ou já está fechado", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
