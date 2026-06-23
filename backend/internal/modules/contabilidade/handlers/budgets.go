package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

type accountingBudgetRow struct {
	ID               int64   `json:"id"`
	ChartAccountID   int64   `json:"chart_account_id"`
	AccountCodigo    string  `json:"account_codigo"`
	AccountNome      string  `json:"account_nome"`
	FiscalYearID     int64   `json:"fiscal_year_id"`
	Mes              *int    `json:"mes"`
	ValorOrcamentado float64 `json:"valor_orcamentado"`
}

const accountingBudgetSelect = `
	SELECT b.id, b.chart_account_id, c.codigo, c.nome, b.fiscal_year_id, b.mes, b.valor_orcamentado
	  FROM contabilidade.accounting_budgets b
	  JOIN contabilidade.chart_of_accounts c ON c.id = b.chart_account_id
`

func scanAccountingBudgets(rows interface {
	Next() bool
	Scan(dest ...any) error
}) []accountingBudgetRow {
	data := []accountingBudgetRow{}
	for rows.Next() {
		var b accountingBudgetRow
		if rows.Scan(&b.ID, &b.ChartAccountID, &b.AccountCodigo, &b.AccountNome, &b.FiscalYearID, &b.Mes, &b.ValorOrcamentado) == nil {
			data = append(data, b)
		}
	}
	return data
}

func (h *Handler) ListarOrcamentos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "b.tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("fiscal_year_id"); v != "" {
		args = append(args, v)
		where += " AND b.fiscal_year_id=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("chart_account_id"); v != "" {
		args = append(args, v)
		where += " AND b.chart_account_id=$" + strconv.Itoa(len(args))
	}
	rows, err := h.db.Query(r.Context(), accountingBudgetSelect+` WHERE `+where+` ORDER BY c.codigo, b.mes NULLS FIRST`, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	jsonOK(w, scanAccountingBudgets(rows), http.StatusOK)
}

func (h *Handler) CriarOrcamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		ChartAccountID   int64    `json:"chart_account_id"`
		FiscalYearID     int64    `json:"fiscal_year_id"`
		Mes              *int     `json:"mes"`
		ValorOrcamentado *float64 `json:"valor_orcamentado"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.ChartAccountID == 0 || body.FiscalYearID == 0 || body.ValorOrcamentado == nil {
		jsonErr(w, "chart_account_id, fiscal_year_id e valor_orcamentado são obrigatórios", http.StatusBadRequest)
		return
	}
	if body.Mes != nil && (*body.Mes < 1 || *body.Mes > 12) {
		jsonErr(w, "mes inválido", http.StatusBadRequest)
		return
	}
	if *body.ValorOrcamentado < 0 {
		jsonErr(w, "valor_orcamentado inválido", http.StatusBadRequest)
		return
	}

	var id int64
	var err error
	if body.Mes == nil {
		err = h.db.QueryRow(r.Context(), `
			INSERT INTO contabilidade.accounting_budgets (tenant_id, chart_account_id, fiscal_year_id, mes, valor_orcamentado)
			VALUES ($1,$2,$3,NULL,$4)
			ON CONFLICT (tenant_id, chart_account_id, fiscal_year_id) WHERE mes IS NULL
			DO UPDATE SET valor_orcamentado=$4, updated_at=NOW()
			RETURNING id`,
			user.TenantID, body.ChartAccountID, body.FiscalYearID, *body.ValorOrcamentado).Scan(&id)
	} else {
		err = h.db.QueryRow(r.Context(), `
			INSERT INTO contabilidade.accounting_budgets (tenant_id, chart_account_id, fiscal_year_id, mes, valor_orcamentado)
			VALUES ($1,$2,$3,$4,$5)
			ON CONFLICT (tenant_id, chart_account_id, fiscal_year_id, mes)
			DO UPDATE SET valor_orcamentado=$5, updated_at=NOW()
			RETURNING id`,
			user.TenantID, body.ChartAccountID, body.FiscalYearID, *body.Mes, *body.ValorOrcamentado).Scan(&id)
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarOrcamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		ValorOrcamentado *float64 `json:"valor_orcamentado"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	if body.ValorOrcamentado == nil {
		jsonErr(w, "valor_orcamentado é obrigatório", http.StatusBadRequest)
		return
	}
	if *body.ValorOrcamentado < 0 {
		jsonErr(w, "valor_orcamentado inválido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE contabilidade.accounting_budgets SET valor_orcamentado=$1, updated_at=NOW()
		WHERE id=$2 AND tenant_id=$3`,
		*body.ValorOrcamentado, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Orçamento não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) EliminarOrcamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(), `DELETE FROM contabilidade.accounting_budgets WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Orçamento não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// OrcadoVsRealizado agrega os valores orçamentados de accounting_budgets com
// os valores realizados (journal_entry_lines de lançamentos publicados) para
// um ano fiscal, ajustando o sinal do realizado à natureza da conta.
func (h *Handler) OrcadoVsRealizado(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	fiscalYearID := q.Get("fiscal_year_id")
	if fiscalYearID == "" {
		jsonErr(w, "fiscal_year_id é obrigatório", http.StatusBadRequest)
		return
	}
	var mes *int
	if v := q.Get("mes"); v != "" {
		m, err := strconv.Atoi(v)
		if err != nil || m < 1 || m > 12 {
			jsonErr(w, "mes inválido", http.StatusBadRequest)
			return
		}
		mes = &m
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT b.chart_account_id, c.codigo, c.nome, t.natureza, b.valor_orcamentado,
		       COALESCE(r.total_debit,0), COALESCE(r.total_credit,0)
		  FROM contabilidade.accounting_budgets b
		  JOIN contabilidade.chart_of_accounts c ON c.id = b.chart_account_id
		  LEFT JOIN contabilidade.account_types t ON t.id = c.account_type_id
		  LEFT JOIN (
		      SELECT l.account_id, SUM(l.debit) AS total_debit, SUM(l.credit) AS total_credit
		        FROM contabilidade.journal_entry_lines l
		        JOIN contabilidade.journal_entries e ON e.id = l.journal_entry_id
		        JOIN contabilidade.fiscal_periods p ON p.id = e.fiscal_period_id
		       WHERE e.tenant_id=$1 AND e.status='publicado' AND p.fiscal_year_id=$2
		         AND ($3::int IS NULL OR p.mes=$3)
		       GROUP BY l.account_id
		  ) r ON r.account_id = b.chart_account_id
		 WHERE b.tenant_id=$1 AND b.fiscal_year_id=$2 AND b.mes IS NOT DISTINCT FROM $3
		 ORDER BY c.codigo`,
		user.TenantID, fiscalYearID, mes)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type linha struct {
		ChartAccountID   int64    `json:"chart_account_id"`
		Codigo           string   `json:"codigo"`
		Nome             string   `json:"nome"`
		ValorOrcamentado float64  `json:"valor_orcamentado"`
		ValorRealizado   float64  `json:"valor_realizado"`
		Variacao         float64  `json:"variacao"`
		VariacaoPct      *float64 `json:"variacao_pct"`
	}
	data := []linha{}
	for rows.Next() {
		var (
			contaID                 int64
			codigo, nome            string
			natureza                *string
			valorOrcamentado        float64
			totalDebit, totalCredit float64
		)
		if err := rows.Scan(&contaID, &codigo, &nome, &natureza, &valorOrcamentado, &totalDebit, &totalCredit); err != nil {
			continue
		}
		var realizado float64
		if natureza != nil && *natureza == "credora" {
			realizado = totalCredit - totalDebit
		} else {
			realizado = totalDebit - totalCredit
		}
		l := linha{
			ChartAccountID:   contaID,
			Codigo:           codigo,
			Nome:             nome,
			ValorOrcamentado: valorOrcamentado,
			ValorRealizado:   realizado,
			Variacao:         realizado - valorOrcamentado,
		}
		if valorOrcamentado != 0 {
			pct := (realizado - valorOrcamentado) / valorOrcamentado * 100
			l.VariacaoPct = &pct
		}
		data = append(data, l)
	}
	jsonOK(w, data, http.StatusOK)
}
