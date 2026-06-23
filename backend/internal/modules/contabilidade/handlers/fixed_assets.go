package handlers

import (
	"encoding/json"
	"math"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

var metodosAmortizacaoValidos = map[string]bool{"linha_recta": true}

const fixedAssetSelect = `
	SELECT id, chart_account_id, depreciation_account_id, accumulated_depreciation_account_id,
	       codigo, nome, data_aquisicao, valor_aquisicao, valor_residual, vida_util_meses,
	       metodo, estado, data_alienacao, valor_alienacao, created_at
	  FROM contabilidade.fixed_assets`

type fixedAssetRow struct {
	ID                               int64      `json:"id"`
	ChartAccountID                   int64      `json:"chart_account_id"`
	DepreciationAccountID            int64      `json:"depreciation_account_id"`
	AccumulatedDepreciationAccountID int64      `json:"accumulated_depreciation_account_id"`
	Codigo                           string     `json:"codigo"`
	Nome                             string     `json:"nome"`
	DataAquisicao                    time.Time  `json:"data_aquisicao"`
	ValorAquisicao                   float64    `json:"valor_aquisicao"`
	ValorResidual                    float64    `json:"valor_residual"`
	VidaUtilMeses                    int        `json:"vida_util_meses"`
	Metodo                           string     `json:"metodo"`
	Estado                           string     `json:"estado"`
	DataAlienacao                    *time.Time `json:"data_alienacao"`
	ValorAlienacao                   *float64   `json:"valor_alienacao"`
	CreatedAt                        time.Time  `json:"created_at"`
}

func scanFixedAsset(row pgx.Row) (fixedAssetRow, error) {
	var a fixedAssetRow
	err := row.Scan(&a.ID, &a.ChartAccountID, &a.DepreciationAccountID, &a.AccumulatedDepreciationAccountID,
		&a.Codigo, &a.Nome, &a.DataAquisicao, &a.ValorAquisicao, &a.ValorResidual, &a.VidaUtilMeses,
		&a.Metodo, &a.Estado, &a.DataAlienacao, &a.ValorAlienacao, &a.CreatedAt)
	return a, err
}

func (h *Handler) ListarAtivosFixos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("estado"); v != "" {
		args = append(args, v)
		where += " AND estado=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("chart_account_id"); v != "" {
		args = append(args, v)
		where += " AND chart_account_id=$" + strconv.Itoa(len(args))
	}
	rows, err := h.db.Query(r.Context(), fixedAssetSelect+" WHERE "+where+" ORDER BY codigo", args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data := []fixedAssetRow{}
	for rows.Next() {
		a, err := scanFixedAsset(rows)
		if err == nil {
			data = append(data, a)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarAtivoFixo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		ChartAccountID                   int64    `json:"chart_account_id"`
		DepreciationAccountID            int64    `json:"depreciation_account_id"`
		AccumulatedDepreciationAccountID int64    `json:"accumulated_depreciation_account_id"`
		Codigo                           string   `json:"codigo"`
		Nome                             string   `json:"nome"`
		DataAquisicao                    string   `json:"data_aquisicao"`
		ValorAquisicao                   float64  `json:"valor_aquisicao"`
		ValorResidual                    *float64 `json:"valor_residual"`
		VidaUtilMeses                    int      `json:"vida_util_meses"`
		Metodo                           *string  `json:"metodo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil ||
		body.ChartAccountID == 0 || body.DepreciationAccountID == 0 || body.AccumulatedDepreciationAccountID == 0 ||
		body.Codigo == "" || body.Nome == "" || body.DataAquisicao == "" ||
		body.ValorAquisicao <= 0 || body.VidaUtilMeses <= 0 {
		jsonErr(w, "chart_account_id, depreciation_account_id, accumulated_depreciation_account_id, codigo, nome, data_aquisicao, valor_aquisicao e vida_util_meses são obrigatórios", http.StatusBadRequest)
		return
	}

	metodo := "linha_recta"
	if body.Metodo != nil && *body.Metodo != "" {
		if !metodosAmortizacaoValidos[*body.Metodo] {
			jsonErr(w, "método de amortização inválido", http.StatusBadRequest)
			return
		}
		metodo = *body.Metodo
	}

	valorResidual := 0.0
	if body.ValorResidual != nil {
		if *body.ValorResidual < 0 {
			jsonErr(w, "valor_residual não pode ser negativo", http.StatusBadRequest)
			return
		}
		valorResidual = *body.ValorResidual
	}
	if valorResidual >= body.ValorAquisicao {
		jsonErr(w, "valor_residual deve ser inferior ao valor_aquisicao", http.StatusBadRequest)
		return
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO contabilidade.fixed_assets
		  (tenant_id, chart_account_id, depreciation_account_id, accumulated_depreciation_account_id,
		   codigo, nome, data_aquisicao, valor_aquisicao, valor_residual, vida_util_meses, metodo)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING id`,
		user.TenantID, body.ChartAccountID, body.DepreciationAccountID, body.AccumulatedDepreciationAccountID,
		body.Codigo, body.Nome, body.DataAquisicao, body.ValorAquisicao, valorResidual, body.VidaUtilMeses, metodo).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Código já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterAtivoFixo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	a, err := scanFixedAsset(h.db.QueryRow(r.Context(), fixedAssetSelect+` WHERE id=$1 AND tenant_id=$2`, id, user.TenantID))
	if err != nil {
		jsonErr(w, "Ativo fixo não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, a, http.StatusOK)
}

func (h *Handler) ActualizarAtivoFixo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Nome                             *string  `json:"nome"`
		DepreciationAccountID            *int64   `json:"depreciation_account_id"`
		AccumulatedDepreciationAccountID *int64   `json:"accumulated_depreciation_account_id"`
		ValorResidual                    *float64 `json:"valor_residual"`
		VidaUtilMeses                    *int     `json:"vida_util_meses"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	if body.ValorResidual != nil && *body.ValorResidual < 0 {
		jsonErr(w, "valor_residual não pode ser negativo", http.StatusBadRequest)
		return
	}
	if body.VidaUtilMeses != nil && *body.VidaUtilMeses <= 0 {
		jsonErr(w, "vida_util_meses deve ser positivo", http.StatusBadRequest)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE contabilidade.fixed_assets SET
		  nome=COALESCE($1,nome), depreciation_account_id=COALESCE($2,depreciation_account_id),
		  accumulated_depreciation_account_id=COALESCE($3,accumulated_depreciation_account_id),
		  valor_residual=COALESCE($4,valor_residual), vida_util_meses=COALESCE($5,vida_util_meses),
		  updated_at=NOW()
		WHERE id=$6 AND tenant_id=$7`,
		body.Nome, body.DepreciationAccountID, body.AccumulatedDepreciationAccountID,
		body.ValorResidual, body.VidaUtilMeses, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Ativo fixo não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) AlienarAtivoFixo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		DataAlienacao  string  `json:"data_alienacao"`
		ValorAlienacao float64 `json:"valor_alienacao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.DataAlienacao == "" {
		jsonErr(w, "data_alienacao é obrigatória", http.StatusBadRequest)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE contabilidade.fixed_assets SET
		  estado='alienado', data_alienacao=$1, valor_alienacao=$2, updated_at=NOW()
		WHERE id=$3 AND tenant_id=$4 AND estado='ativo'`,
		body.DataAlienacao, body.ValorAlienacao, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Ativo fixo não encontrado ou já alienado", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ObterPlanoAmortizacao calcula o plano de amortização pelo método de linha
// recta e cruza-o com as depreciation_entries já registadas.
func (h *Handler) ObterPlanoAmortizacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	a, err := scanFixedAsset(h.db.QueryRow(r.Context(), fixedAssetSelect+` WHERE id=$1 AND tenant_id=$2`, id, user.TenantID))
	if err != nil {
		jsonErr(w, "Ativo fixo não encontrado", http.StatusNotFound)
		return
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT numero_parcela, fiscal_period_id, valor_amortizacao, status, journal_entry_id
		  FROM contabilidade.depreciation_entries WHERE fixed_asset_id=$1`, a.ID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	type entradaExistente struct {
		FiscalPeriodID   int64   `json:"fiscal_period_id"`
		ValorAmortizacao float64 `json:"valor_amortizacao"`
		Status           string  `json:"status"`
		JournalEntryID   *int64  `json:"journal_entry_id"`
	}
	existentes := map[int]entradaExistente{}
	for rows.Next() {
		var n int
		var e entradaExistente
		if rows.Scan(&n, &e.FiscalPeriodID, &e.ValorAmortizacao, &e.Status, &e.JournalEntryID) == nil {
			existentes[n] = e
		}
	}
	rows.Close()

	base := a.ValorAquisicao - a.ValorResidual
	parcela := math.Round(base/float64(a.VidaUtilMeses)*100) / 100

	type planoLinha struct {
		NumeroParcela    int     `json:"numero_parcela"`
		ValorAmortizacao float64 `json:"valor_amortizacao"`
		Status           string  `json:"status"`
		FiscalPeriodID   *int64  `json:"fiscal_period_id"`
		JournalEntryID   *int64  `json:"journal_entry_id"`
	}
	plano := make([]planoLinha, 0, a.VidaUtilMeses)
	for n := 1; n <= a.VidaUtilMeses; n++ {
		valor := parcela
		if n == a.VidaUtilMeses {
			valor = math.Round((base-parcela*float64(a.VidaUtilMeses-1))*100) / 100
		}
		linha := planoLinha{NumeroParcela: n, ValorAmortizacao: valor, Status: "pendente"}
		if e, ok := existentes[n]; ok {
			fiscalPeriodID := e.FiscalPeriodID
			linha.ValorAmortizacao = e.ValorAmortizacao
			linha.Status = e.Status
			linha.FiscalPeriodID = &fiscalPeriodID
			linha.JournalEntryID = e.JournalEntryID
		}
		plano = append(plano, linha)
	}

	jsonOK(w, map[string]any{
		"fixed_asset_id": a.ID, "valor_aquisicao": a.ValorAquisicao, "valor_residual": a.ValorResidual,
		"vida_util_meses": a.VidaUtilMeses, "valor_parcela": parcela, "plano": plano,
	}, http.StatusOK)
}
