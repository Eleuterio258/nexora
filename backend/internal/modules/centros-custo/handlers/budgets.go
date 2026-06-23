package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

type costCenterBudgetRow struct {
	ID               int64   `json:"id"`
	CostCenterID     int64   `json:"cost_center_id"`
	Ano              int     `json:"ano"`
	Mes              *int    `json:"mes"`
	ValorOrcamentado float64 `json:"valor_orcamentado"`
	Moeda            string  `json:"moeda"`
}

const costCenterBudgetSelect = `
	SELECT id, cost_center_id, ano, mes, valor_orcamentado, moeda
	  FROM centros_custo.cost_center_budgets
`

func scanCostCenterBudgets(rows pgx.Rows) []costCenterBudgetRow {
	data := []costCenterBudgetRow{}
	for rows.Next() {
		var b costCenterBudgetRow
		if rows.Scan(&b.ID, &b.CostCenterID, &b.Ano, &b.Mes, &b.ValorOrcamentado, &b.Moeda) == nil {
			data = append(data, b)
		}
	}
	return data
}

func (h *Handler) ListarOrcamentosCC(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("cost_center_id"); v != "" {
		args = append(args, v)
		where += " AND cost_center_id=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("ano"); v != "" {
		args = append(args, v)
		where += " AND ano=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("mes"); v != "" {
		args = append(args, v)
		where += " AND mes=$" + strconv.Itoa(len(args))
	}
	rows, err := h.db.Query(r.Context(), costCenterBudgetSelect+` WHERE `+where+` ORDER BY ano DESC, mes NULLS FIRST, cost_center_id`, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	jsonOK(w, scanCostCenterBudgets(rows), http.StatusOK)
}

func (h *Handler) CriarOrcamentoCC(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		CostCenterID     int64    `json:"cost_center_id"`
		Ano              int      `json:"ano"`
		Mes              *int     `json:"mes"`
		ValorOrcamentado *float64 `json:"valor_orcamentado"`
		Moeda            *string  `json:"moeda"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.CostCenterID == 0 || body.Ano == 0 || body.ValorOrcamentado == nil {
		jsonErr(w, "cost_center_id, ano e valor_orcamentado são obrigatórios", http.StatusBadRequest)
		return
	}
	if body.Mes != nil && (*body.Mes < 1 || *body.Mes > 12) {
		jsonErr(w, "mes deve estar entre 1 e 12", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO centros_custo.cost_center_budgets (tenant_id, cost_center_id, ano, mes, valor_orcamentado, moeda, created_by)
		VALUES ($1,$2,$3,$4,$5,COALESCE($6,'MZN'),$7) RETURNING id`,
		user.TenantID, body.CostCenterID, body.Ano, body.Mes, *body.ValorOrcamentado, body.Moeda, user.ID).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um orçamento para este centro de custo, ano e mês", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarOrcamentoCC(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		ValorOrcamentado *float64 `json:"valor_orcamentado"`
		Moeda            *string  `json:"moeda"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE centros_custo.cost_center_budgets SET
		  valor_orcamentado=COALESCE($1,valor_orcamentado), moeda=COALESCE($2,moeda), updated_at=NOW()
		WHERE id=$3 AND tenant_id=$4`,
		body.ValorOrcamentado, body.Moeda, id, user.TenantID)
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

func (h *Handler) EliminarOrcamentoCC(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(), `DELETE FROM centros_custo.cost_center_budgets WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
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

type orcadoVsRealizadoRow struct {
	CostCenterID     int64    `json:"cost_center_id"`
	Codigo           string   `json:"codigo"`
	Nome             string   `json:"nome"`
	ValorOrcamentado float64  `json:"valor_orcamentado"`
	ValorRealizado   float64  `json:"valor_realizado"`
	Variacao         float64  `json:"variacao"`
	VariacaoPct      *float64 `json:"variacao_pct"`
}

func (h *Handler) OrcadoVsRealizadoCC(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()

	ano, err := strconv.Atoi(q.Get("ano"))
	if err != nil || ano == 0 {
		jsonErr(w, "ano é obrigatório", http.StatusBadRequest)
		return
	}

	var mesArg *int64
	if v := q.Get("mes"); v != "" {
		m, err := strconv.Atoi(v)
		if err != nil || m < 1 || m > 12 {
			jsonErr(w, "mes deve estar entre 1 e 12", http.StatusBadRequest)
			return
		}
		m64 := int64(m)
		mesArg = &m64
	}

	where := "cc.tenant_id=$1"
	args := []any{user.TenantID, ano, mesArg}
	if v := q.Get("cost_center_id"); v != "" {
		args = append(args, v)
		where += " AND cc.id=$" + strconv.Itoa(len(args))
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT cc.id, cc.codigo, cc.nome,
		       COALESCE(b.valor_orcamentado, 0), COALESCE(a.valor_realizado, 0)
		  FROM centros_custo.cost_centers cc
		  LEFT JOIN (
		      SELECT cost_center_id, SUM(valor_orcamentado) AS valor_orcamentado
		        FROM centros_custo.cost_center_budgets
		       WHERE tenant_id=$1 AND ano=$2
		         AND ((mes = $3::bigint) OR (mes IS NULL AND $3::bigint IS NULL))
		       GROUP BY cost_center_id
		  ) b ON b.cost_center_id = cc.id
		  LEFT JOIN (
		      SELECT cost_center_id, SUM(valor) AS valor_realizado
		        FROM centros_custo.cost_center_allocations
		       WHERE tenant_id=$1 AND EXTRACT(YEAR FROM created_at)=$2
		         AND ($3::bigint IS NULL OR EXTRACT(MONTH FROM created_at)=$3::bigint)
		       GROUP BY cost_center_id
		  ) a ON a.cost_center_id = cc.id
		 WHERE `+where+`
		 ORDER BY cc.codigo`, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	linhas := []orcadoVsRealizadoRow{}
	var totalOrcado, totalRealizado float64
	for rows.Next() {
		var l orcadoVsRealizadoRow
		if rows.Scan(&l.CostCenterID, &l.Codigo, &l.Nome, &l.ValorOrcamentado, &l.ValorRealizado) != nil {
			continue
		}
		l.Variacao = l.ValorRealizado - l.ValorOrcamentado
		if l.ValorOrcamentado != 0 {
			pct := l.Variacao / l.ValorOrcamentado * 100
			l.VariacaoPct = &pct
		}
		totalOrcado += l.ValorOrcamentado
		totalRealizado += l.ValorRealizado
		linhas = append(linhas, l)
	}

	jsonOK(w, map[string]any{
		"ano":    ano,
		"mes":    mesArg,
		"linhas": linhas,
		"totais": map[string]any{
			"valor_orcamentado": totalOrcado,
			"valor_realizado":   totalRealizado,
			"variacao":          totalRealizado - totalOrcado,
		},
	}, http.StatusOK)
}
