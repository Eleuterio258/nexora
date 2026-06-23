package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

const fiscalYearSelect = `SELECT id, ano, data_inicio, data_fim, status, fechado_em, fechado_por FROM contabilidade.fiscal_years`

type fiscalYearRow struct {
	ID         int64      `json:"id"`
	Ano        int        `json:"ano"`
	DataInicio time.Time  `json:"data_inicio"`
	DataFim    time.Time  `json:"data_fim"`
	Status     string     `json:"status"`
	FechadoEm  *time.Time `json:"fechado_em"`
	FechadoPor *int64     `json:"fechado_por"`
}

func scanFiscalYears(rows pgx.Rows) []fiscalYearRow {
	data := []fiscalYearRow{}
	for rows.Next() {
		var y fiscalYearRow
		if rows.Scan(&y.ID, &y.Ano, &y.DataInicio, &y.DataFim, &y.Status, &y.FechadoEm, &y.FechadoPor) == nil {
			data = append(data, y)
		}
	}
	return data
}

func (h *Handler) ListarAnosFiscais(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, err := h.db.Query(r.Context(), fiscalYearSelect+` WHERE tenant_id=$1 ORDER BY ano DESC`, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	jsonOK(w, scanFiscalYears(rows), http.StatusOK)
}

func (h *Handler) CriarAnoFiscal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Ano        int    `json:"ano"`
		DataInicio string `json:"data_inicio"`
		DataFim    string `json:"data_fim"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Ano == 0 || body.DataInicio == "" || body.DataFim == "" {
		jsonErr(w, "ano, data_inicio e data_fim são obrigatórios", http.StatusBadRequest)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var id int64
	err = tx.QueryRow(r.Context(), `
		INSERT INTO contabilidade.fiscal_years (tenant_id,ano,data_inicio,data_fim)
		VALUES ($1,$2,$3,$4) RETURNING id`,
		user.TenantID, body.Ano, body.DataInicio, body.DataFim).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Ano fiscal já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	_, err = tx.Exec(r.Context(), `
		INSERT INTO contabilidade.fiscal_periods (tenant_id, fiscal_year_id, ano, mes, data_inicio, data_fim, status)
		SELECT $1, $2, $3,
		       EXTRACT(MONTH FROM (m.inicio))::int,
		       m.inicio,
		       (m.inicio + INTERVAL '1 month' - INTERVAL '1 day')::date,
		       'aberto'
		  FROM (
		      SELECT ($4::date + ((n-1) * INTERVAL '1 month'))::date AS inicio
		        FROM generate_series(1,12) AS n
		  ) m`,
		user.TenantID, id, body.Ano, body.DataInicio)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterAnoFiscal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var y fiscalYearRow
	err := h.db.QueryRow(r.Context(), fiscalYearSelect+` WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).
		Scan(&y.ID, &y.Ano, &y.DataInicio, &y.DataFim, &y.Status, &y.FechadoEm, &y.FechadoPor)
	if err != nil {
		jsonErr(w, "Ano fiscal não encontrado", http.StatusNotFound)
		return
	}

	rows, err := h.db.Query(r.Context(), fiscalPeriodSelect+` WHERE fiscal_year_id=$1 AND tenant_id=$2 ORDER BY mes`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	periodos := scanFiscalPeriods(rows)
	rows.Close()

	jsonOK(w, map[string]any{
		"id": y.ID, "ano": y.Ano, "data_inicio": y.DataInicio, "data_fim": y.DataFim,
		"status": y.Status, "fechado_em": y.FechadoEm, "fechado_por": y.FechadoPor,
		"periodos": periodos,
	}, http.StatusOK)
}

func (h *Handler) ActualizarAnoFiscal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		DataInicio *string `json:"data_inicio"`
		DataFim    *string `json:"data_fim"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE contabilidade.fiscal_years SET
		  data_inicio=COALESCE($1,data_inicio), data_fim=COALESCE($2,data_fim)
		WHERE id=$3 AND tenant_id=$4`,
		body.DataInicio, body.DataFim, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Ano fiscal não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) FecharAnoFiscal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var pendentes int
	err := h.db.QueryRow(r.Context(), `
		SELECT COUNT(*) FROM contabilidade.fiscal_periods
		 WHERE fiscal_year_id=$1 AND tenant_id=$2 AND status<>'fechado'`,
		id, user.TenantID).Scan(&pendentes)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if pendentes > 0 {
		jsonErr(w, "Existem períodos fiscais não encerrados", http.StatusConflict)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE contabilidade.fiscal_years SET status='fechado', fechado_em=NOW(), fechado_por=$1
		WHERE id=$2 AND tenant_id=$3 AND status='aberto'`,
		user.ID, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Ano fiscal não encontrado ou já encerrado", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
