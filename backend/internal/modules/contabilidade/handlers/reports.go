package handlers

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	mw "nexora/internal/middleware"
)

type reportValidationError struct {
	msg string
}

func (e *reportValidationError) Error() string {
	return e.msg
}

func validationErr(msg string) error {
	return &reportValidationError{msg: msg}
}

func queryParams(r *http.Request) map[string]string {
	out := map[string]string{}
	for k, v := range r.URL.Query() {
		if len(v) > 0 {
			out[k] = v[0]
		}
	}
	return out
}

func respondReport(w http.ResponseWriter, result any, err error) {
	if err != nil {
		var ve *reportValidationError
		if errors.As(err, &ve) {
			jsonErr(w, ve.msg, http.StatusBadRequest)
		} else {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}
	jsonOK(w, result, http.StatusOK)
}

type balanceteConta struct {
	ChartAccountID int64   `json:"chart_account_id"`
	Codigo         string  `json:"codigo"`
	Nome           string  `json:"nome"`
	Classe         string  `json:"classe"`
	Natureza       string  `json:"natureza"`
	TotalDebito    float64 `json:"total_debito"`
	TotalCredito   float64 `json:"total_credito"`
	SaldoDevedor   float64 `json:"saldo_devedor"`
	SaldoCredor    float64 `json:"saldo_credor"`
}

func gerarBalancete(ctx context.Context, db *pgxpool.Pool, tenantID int64, params map[string]string) (any, error) {
	args := []any{tenantID}
	filtro := "je.tenant_id=$1 AND je.status='publicado'"

	if v := params["fiscal_period_id"]; v != "" {
		args = append(args, v)
		filtro += " AND je.fiscal_period_id=$" + strconv.Itoa(len(args))
	} else if params["data_inicio"] != "" && params["data_fim"] != "" {
		args = append(args, params["data_inicio"])
		filtro += " AND je.entry_date>=$" + strconv.Itoa(len(args))
		args = append(args, params["data_fim"])
		filtro += " AND je.entry_date<=$" + strconv.Itoa(len(args))
	}

	rows, err := db.Query(ctx, `
		SELECT c.id, c.codigo, c.nome, at.classe, at.natureza,
		       COALESCE(SUM(jel.debit),0), COALESCE(SUM(jel.credit),0)
		  FROM contabilidade.chart_of_accounts c
		  JOIN contabilidade.account_types at ON at.id = c.account_type_id
		  LEFT JOIN contabilidade.journal_entry_lines jel ON jel.account_id = c.id
		  LEFT JOIN contabilidade.journal_entries je ON je.id = jel.journal_entry_id AND `+filtro+`
		 WHERE c.tenant_id = $1
		 GROUP BY c.id, c.codigo, c.nome, at.classe, at.natureza
		HAVING COALESCE(SUM(jel.debit),0) <> 0 OR COALESCE(SUM(jel.credit),0) <> 0
		 ORDER BY c.codigo`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	contas := []balanceteConta{}
	var totalDebito, totalCredito, totalSaldoDevedor, totalSaldoCredor float64
	for rows.Next() {
		var c balanceteConta
		if err := rows.Scan(&c.ChartAccountID, &c.Codigo, &c.Nome, &c.Classe, &c.Natureza, &c.TotalDebito, &c.TotalCredito); err != nil {
			return nil, err
		}
		saldo := c.TotalDebito - c.TotalCredito
		if saldo > 0 {
			c.SaldoDevedor = saldo
		} else {
			c.SaldoCredor = -saldo
		}
		totalDebito += c.TotalDebito
		totalCredito += c.TotalCredito
		totalSaldoDevedor += c.SaldoDevedor
		totalSaldoCredor += c.SaldoCredor
		contas = append(contas, c)
	}

	return map[string]any{
		"contas": contas,
		"totais": map[string]any{
			"total_debito":  totalDebito,
			"total_credito": totalCredito,
			"saldo_devedor": totalSaldoDevedor,
			"saldo_credor":  totalSaldoCredor,
		},
	}, nil
}

func (h *Handler) BalanceteGeral(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	result, err := gerarBalancete(r.Context(), h.db, user.TenantID, queryParams(r))
	respondReport(w, result, err)
}

type balancoConta struct {
	ChartAccountID int64   `json:"chart_account_id"`
	Codigo         string  `json:"codigo"`
	Nome           string  `json:"nome"`
	Saldo          float64 `json:"saldo"`
}

func gerarBalanco(ctx context.Context, db *pgxpool.Pool, tenantID int64, params map[string]string) (any, error) {
	data := params["data"]
	if data == "" {
		data = time.Now().Format("2006-01-02")
	}

	rows, err := db.Query(ctx, `
		SELECT c.id, c.codigo, c.nome, at.classe, at.natureza,
		       COALESCE(SUM(jel.debit),0), COALESCE(SUM(jel.credit),0)
		  FROM contabilidade.chart_of_accounts c
		  JOIN contabilidade.account_types at ON at.id = c.account_type_id
		  LEFT JOIN contabilidade.journal_entry_lines jel ON jel.account_id = c.id
		  LEFT JOIN contabilidade.journal_entries je ON je.id = jel.journal_entry_id
		       AND je.tenant_id=$1 AND je.status='publicado' AND je.entry_date<=$2
		 WHERE c.tenant_id = $1 AND at.classe IN ('ativo','passivo','capital')
		 GROUP BY c.id, c.codigo, c.nome, at.classe, at.natureza
		HAVING COALESCE(SUM(jel.debit),0) <> 0 OR COALESCE(SUM(jel.credit),0) <> 0
		 ORDER BY at.classe, c.codigo`, tenantID, data)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	grupos := map[string][]balancoConta{"ativo": {}, "passivo": {}, "capital": {}}
	var totalAtivo, totalPassivoCapital float64
	for rows.Next() {
		var id int64
		var codigo, nome, classe, natureza string
		var debito, credito float64
		if err := rows.Scan(&id, &codigo, &nome, &classe, &natureza, &debito, &credito); err != nil {
			return nil, err
		}
		var saldo float64
		if natureza == "devedora" {
			saldo = debito - credito
		} else {
			saldo = credito - debito
		}
		grupos[classe] = append(grupos[classe], balancoConta{ChartAccountID: id, Codigo: codigo, Nome: nome, Saldo: saldo})
		if classe == "ativo" {
			totalAtivo += saldo
		} else {
			totalPassivoCapital += saldo
		}
	}

	return map[string]any{
		"data":                  data,
		"ativo":                 grupos["ativo"],
		"passivo":               grupos["passivo"],
		"capital":               grupos["capital"],
		"total_ativo":           totalAtivo,
		"total_passivo_capital": totalPassivoCapital,
		"diferenca":             totalAtivo - totalPassivoCapital,
	}, nil
}

func (h *Handler) Balanco(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	result, err := gerarBalanco(r.Context(), h.db, user.TenantID, queryParams(r))
	respondReport(w, result, err)
}

func gerarDemonstracaoResultados(ctx context.Context, db *pgxpool.Pool, tenantID int64, params map[string]string) (any, error) {
	dataInicio, dataFim := params["data_inicio"], params["data_fim"]
	if dataInicio == "" || dataFim == "" {
		return nil, validationErr("data_inicio e data_fim são obrigatórios")
	}

	rows, err := db.Query(ctx, `
		SELECT c.id, c.codigo, c.nome, at.classe, at.natureza,
		       COALESCE(SUM(jel.debit),0), COALESCE(SUM(jel.credit),0)
		  FROM contabilidade.chart_of_accounts c
		  JOIN contabilidade.account_types at ON at.id = c.account_type_id
		  LEFT JOIN contabilidade.journal_entry_lines jel ON jel.account_id = c.id
		  LEFT JOIN contabilidade.journal_entries je ON je.id = jel.journal_entry_id
		       AND je.tenant_id=$1 AND je.status='publicado' AND je.entry_date BETWEEN $2 AND $3
		 WHERE c.tenant_id = $1 AND at.classe IN ('rendimento','gasto')
		 GROUP BY c.id, c.codigo, c.nome, at.classe, at.natureza
		HAVING COALESCE(SUM(jel.debit),0) <> 0 OR COALESCE(SUM(jel.credit),0) <> 0
		 ORDER BY at.classe, c.codigo`, tenantID, dataInicio, dataFim)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	grupos := map[string][]balancoConta{"rendimento": {}, "gasto": {}}
	var totalRendimento, totalGasto float64
	for rows.Next() {
		var id int64
		var codigo, nome, classe, natureza string
		var debito, credito float64
		if err := rows.Scan(&id, &codigo, &nome, &classe, &natureza, &debito, &credito); err != nil {
			return nil, err
		}
		var saldo float64
		if natureza == "credora" {
			saldo = credito - debito
		} else {
			saldo = debito - credito
		}
		grupos[classe] = append(grupos[classe], balancoConta{ChartAccountID: id, Codigo: codigo, Nome: nome, Saldo: saldo})
		if classe == "rendimento" {
			totalRendimento += saldo
		} else {
			totalGasto += saldo
		}
	}

	return map[string]any{
		"data_inicio":      dataInicio,
		"data_fim":         dataFim,
		"rendimento":       grupos["rendimento"],
		"gasto":            grupos["gasto"],
		"total_rendimento": totalRendimento,
		"total_gasto":      totalGasto,
		"resultado":        totalRendimento - totalGasto,
	}, nil
}

func (h *Handler) DemonstracaoResultados(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	result, err := gerarDemonstracaoResultados(r.Context(), h.db, user.TenantID, queryParams(r))
	respondReport(w, result, err)
}

type ledgerMovimento struct {
	JournalEntryID int64     `json:"journal_entry_id"`
	Numero         string    `json:"numero"`
	EntryDate      time.Time `json:"entry_date"`
	Descricao      string    `json:"descricao"`
	Debit          float64   `json:"debit"`
	Credit         float64   `json:"credit"`
	Saldo          float64   `json:"saldo"`
}

func gerarRazaoGeral(ctx context.Context, db *pgxpool.Pool, tenantID int64, params map[string]string) (any, error) {
	chartAccountID, errConv := strconv.ParseInt(params["chart_account_id"], 10, 64)
	if errConv != nil || chartAccountID == 0 {
		return nil, validationErr("chart_account_id é obrigatório")
	}

	var codigo, nome, classe, natureza string
	err := db.QueryRow(ctx, `
		SELECT c.codigo, c.nome, at.classe, at.natureza
		  FROM contabilidade.chart_of_accounts c
		  JOIN contabilidade.account_types at ON at.id = c.account_type_id
		 WHERE c.id=$1 AND c.tenant_id=$2`, chartAccountID, tenantID).Scan(&codigo, &nome, &classe, &natureza)
	if err != nil {
		return nil, validationErr("Conta não encontrada")
	}

	saldoInicial := 0.0
	dataInicio := params["data_inicio"]
	if dataInicio != "" {
		var debito, credito float64
		err := db.QueryRow(ctx, `
			SELECT COALESCE(SUM(jel.debit),0), COALESCE(SUM(jel.credit),0)
			  FROM contabilidade.journal_entry_lines jel
			  JOIN contabilidade.journal_entries je ON je.id = jel.journal_entry_id
			 WHERE jel.account_id=$1 AND je.tenant_id=$2 AND je.status='publicado' AND je.entry_date<$3`,
			chartAccountID, tenantID, dataInicio).Scan(&debito, &credito)
		if err != nil {
			return nil, err
		}
		if natureza == "devedora" {
			saldoInicial = debito - credito
		} else {
			saldoInicial = credito - debito
		}
	}

	args := []any{chartAccountID, tenantID}
	filtro := ""
	if v := params["fiscal_period_id"]; v != "" {
		args = append(args, v)
		filtro = " AND je.fiscal_period_id=$" + strconv.Itoa(len(args))
	} else {
		if dataInicio != "" {
			args = append(args, dataInicio)
			filtro += " AND je.entry_date>=$" + strconv.Itoa(len(args))
		}
		if v := params["data_fim"]; v != "" {
			args = append(args, v)
			filtro += " AND je.entry_date<=$" + strconv.Itoa(len(args))
		}
	}

	rows, err := db.Query(ctx, `
		SELECT je.id, je.numero, je.entry_date, je.descricao, jel.debit, jel.credit
		  FROM contabilidade.journal_entry_lines jel
		  JOIN contabilidade.journal_entries je ON je.id = jel.journal_entry_id
		 WHERE jel.account_id=$1 AND je.tenant_id=$2 AND je.status='publicado'`+filtro+`
		 ORDER BY je.entry_date, je.id`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	saldo := saldoInicial
	movimentos := []ledgerMovimento{}
	for rows.Next() {
		var m ledgerMovimento
		if err := rows.Scan(&m.JournalEntryID, &m.Numero, &m.EntryDate, &m.Descricao, &m.Debit, &m.Credit); err != nil {
			return nil, err
		}
		if natureza == "devedora" {
			saldo += m.Debit - m.Credit
		} else {
			saldo += m.Credit - m.Debit
		}
		m.Saldo = saldo
		movimentos = append(movimentos, m)
	}

	return map[string]any{
		"conta": map[string]any{
			"chart_account_id": chartAccountID,
			"codigo":           codigo,
			"nome":             nome,
			"classe":           classe,
			"natureza":         natureza,
		},
		"saldo_inicial": saldoInicial,
		"movimentos":    movimentos,
		"saldo_final":   saldo,
	}, nil
}

func (h *Handler) RazaoGeral(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	result, err := gerarRazaoGeral(r.Context(), h.db, user.TenantID, queryParams(r))
	respondReport(w, result, err)
}

type depreciationAssetRow struct {
	FixedAssetID     int64   `json:"fixed_asset_id"`
	Codigo           string  `json:"codigo"`
	Nome             string  `json:"nome"`
	NumeroParcela    int     `json:"numero_parcela"`
	ValorAmortizacao float64 `json:"valor_amortizacao"`
	Status           string  `json:"status"`
}

type depreciationPeriodRow struct {
	FiscalPeriodID   int64   `json:"fiscal_period_id"`
	Ano              int     `json:"ano"`
	Mes              int     `json:"mes"`
	TotalAmortizacao float64 `json:"total_amortizacao"`
	NumAtivos        int     `json:"num_ativos"`
}

func gerarResumoAmortizacoes(ctx context.Context, db *pgxpool.Pool, tenantID int64, params map[string]string) (any, error) {
	if v := params["fiscal_period_id"]; v != "" {
		rows, err := db.Query(ctx, `
			SELECT fa.id, fa.codigo, fa.nome, de.numero_parcela, de.valor_amortizacao, de.status
			  FROM contabilidade.depreciation_entries de
			  JOIN contabilidade.fixed_assets fa ON fa.id = de.fixed_asset_id
			 WHERE de.tenant_id=$1 AND de.fiscal_period_id=$2
			 ORDER BY fa.codigo`, tenantID, v)
		if err != nil {
			return nil, err
		}
		defer rows.Close()

		ativos := []depreciationAssetRow{}
		var total float64
		for rows.Next() {
			var a depreciationAssetRow
			if err := rows.Scan(&a.FixedAssetID, &a.Codigo, &a.Nome, &a.NumeroParcela, &a.ValorAmortizacao, &a.Status); err != nil {
				return nil, err
			}
			if a.Status == "processado" {
				total += a.ValorAmortizacao
			}
			ativos = append(ativos, a)
		}
		return map[string]any{"ativos": ativos, "total_amortizacao": total}, nil
	}

	if v := params["fiscal_year_id"]; v != "" {
		rows, err := db.Query(ctx, `
			SELECT p.id, p.ano, p.mes, COALESCE(SUM(de.valor_amortizacao),0), COUNT(de.id)
			  FROM contabilidade.fiscal_periods p
			  LEFT JOIN contabilidade.depreciation_entries de
			         ON de.fiscal_period_id = p.id AND de.tenant_id=$1 AND de.status='processado'
			 WHERE p.tenant_id=$1 AND p.fiscal_year_id=$2
			 GROUP BY p.id, p.ano, p.mes
			 ORDER BY p.mes`, tenantID, v)
		if err != nil {
			return nil, err
		}
		defer rows.Close()

		periodos := []depreciationPeriodRow{}
		var total float64
		for rows.Next() {
			var p depreciationPeriodRow
			if err := rows.Scan(&p.FiscalPeriodID, &p.Ano, &p.Mes, &p.TotalAmortizacao, &p.NumAtivos); err != nil {
				return nil, err
			}
			total += p.TotalAmortizacao
			periodos = append(periodos, p)
		}
		return map[string]any{"periodos": periodos, "total_amortizacao": total}, nil
	}

	return nil, validationErr("fiscal_period_id ou fiscal_year_id é obrigatório")
}

func (h *Handler) ResumoAmortizacoes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	result, err := gerarResumoAmortizacoes(r.Context(), h.db, user.TenantID, queryParams(r))
	respondReport(w, result, err)
}

type budgetExecutionRow struct {
	ChartAccountID   int64    `json:"chart_account_id"`
	Codigo           string   `json:"codigo"`
	Nome             string   `json:"nome"`
	ValorOrcamentado float64  `json:"valor_orcamentado"`
	ValorRealizado   float64  `json:"valor_realizado"`
	Variacao         float64  `json:"variacao"`
	VariacaoPct      *float64 `json:"variacao_pct"`
}

func gerarExecucaoOrcamental(ctx context.Context, db *pgxpool.Pool, tenantID int64, params map[string]string) (any, error) {
	fiscalYearID, errConv := strconv.ParseInt(params["fiscal_year_id"], 10, 64)
	if errConv != nil || fiscalYearID == 0 {
		return nil, validationErr("fiscal_year_id é obrigatório")
	}

	rows, err := db.Query(ctx, `
		SELECT c.id, c.codigo, c.nome, at.natureza,
		       COALESCE(b.total_orcado, 0), COALESCE(r.total_debito, 0), COALESCE(r.total_credito, 0)
		  FROM (SELECT DISTINCT chart_account_id FROM contabilidade.accounting_budgets WHERE tenant_id=$1 AND fiscal_year_id=$2) ba
		  JOIN contabilidade.chart_of_accounts c ON c.id = ba.chart_account_id
		  JOIN contabilidade.account_types at ON at.id = c.account_type_id
		  LEFT JOIN (
		      SELECT chart_account_id, SUM(valor_orcamentado) AS total_orcado
		        FROM contabilidade.accounting_budgets
		       WHERE tenant_id=$1 AND fiscal_year_id=$2
		       GROUP BY chart_account_id
		  ) b ON b.chart_account_id = c.id
		  LEFT JOIN (
		      SELECT jel.account_id, SUM(jel.debit) AS total_debito, SUM(jel.credit) AS total_credito
		        FROM contabilidade.journal_entry_lines jel
		        JOIN contabilidade.journal_entries je ON je.id = jel.journal_entry_id
		        JOIN contabilidade.fiscal_periods p ON p.id = je.fiscal_period_id
		       WHERE je.tenant_id=$1 AND je.status='publicado' AND p.fiscal_year_id=$2
		       GROUP BY jel.account_id
		  ) r ON r.account_id = c.id
		 ORDER BY c.codigo`, tenantID, fiscalYearID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	contas := []budgetExecutionRow{}
	var totalOrcado, totalRealizado float64
	for rows.Next() {
		var c budgetExecutionRow
		var natureza string
		var totalDebito, totalCredito float64
		if err := rows.Scan(&c.ChartAccountID, &c.Codigo, &c.Nome, &natureza, &c.ValorOrcamentado, &totalDebito, &totalCredito); err != nil {
			return nil, err
		}
		if natureza == "credora" {
			c.ValorRealizado = totalCredito - totalDebito
		} else {
			c.ValorRealizado = totalDebito - totalCredito
		}
		c.Variacao = c.ValorRealizado - c.ValorOrcamentado
		if c.ValorOrcamentado != 0 {
			pct := c.Variacao / c.ValorOrcamentado * 100
			c.VariacaoPct = &pct
		}
		totalOrcado += c.ValorOrcamentado
		totalRealizado += c.ValorRealizado
		contas = append(contas, c)
	}

	return map[string]any{
		"contas": contas,
		"totais": map[string]any{
			"valor_orcamentado": totalOrcado,
			"valor_realizado":   totalRealizado,
			"variacao":          totalRealizado - totalOrcado,
		},
	}, nil
}

func (h *Handler) ExecucaoOrcamental(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	result, err := gerarExecucaoOrcamental(r.Context(), h.db, user.TenantID, queryParams(r))
	respondReport(w, result, err)
}

func (h *Handler) GerarRelatorio(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var body struct {
		Tipo       string            `json:"tipo"`
		Parametros map[string]string `json:"parametros"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Tipo == "" {
		jsonErr(w, "tipo é obrigatório", http.StatusBadRequest)
		return
	}
	if body.Parametros == nil {
		body.Parametros = map[string]string{}
	}

	var result any
	var err error
	switch body.Tipo {
	case "trial_balance":
		result, err = gerarBalancete(r.Context(), h.db, user.TenantID, body.Parametros)
	case "balance_sheet":
		result, err = gerarBalanco(r.Context(), h.db, user.TenantID, body.Parametros)
	case "income_statement":
		result, err = gerarDemonstracaoResultados(r.Context(), h.db, user.TenantID, body.Parametros)
	case "general_ledger":
		result, err = gerarRazaoGeral(r.Context(), h.db, user.TenantID, body.Parametros)
	case "depreciation_summary":
		result, err = gerarResumoAmortizacoes(r.Context(), h.db, user.TenantID, body.Parametros)
	case "budget_execution":
		result, err = gerarExecucaoOrcamental(r.Context(), h.db, user.TenantID, body.Parametros)
	default:
		err = validationErr("tipo de relatório desconhecido")
	}
	if err != nil {
		var ve *reportValidationError
		if errors.As(err, &ve) {
			jsonErr(w, ve.msg, http.StatusBadRequest)
		} else {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}

	parametrosJSON, err := json.Marshal(body.Parametros)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	conteudoJSON, err := json.Marshal(result)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	var id int64
	err = h.db.QueryRow(r.Context(), `
		INSERT INTO contabilidade.accounting_reports (tenant_id, tipo, parametros, conteudo, gerado_por)
		VALUES ($1,$2,$3,$4,$5) RETURNING id`,
		user.TenantID, body.Tipo, parametrosJSON, conteudoJSON, user.ID).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"id": id, "conteudo": result}, http.StatusCreated)
}

func (h *Handler) ListarRelatorios(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("tipo"); v != "" {
		args = append(args, v)
		where += " AND tipo=$" + strconv.Itoa(len(args))
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT id, tipo, parametros, gerado_por, gerado_em
		  FROM contabilidade.accounting_reports
		 WHERE `+where+`
		 ORDER BY gerado_em DESC
		 LIMIT 50`, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type reportSummary struct {
		ID         int64          `json:"id"`
		Tipo       string         `json:"tipo"`
		Parametros map[string]any `json:"parametros"`
		GeradoPor  *int64         `json:"gerado_por"`
		GeradoEm   time.Time      `json:"gerado_em"`
	}
	data := []reportSummary{}
	for rows.Next() {
		var s reportSummary
		var parametros []byte
		if err := rows.Scan(&s.ID, &s.Tipo, &parametros, &s.GeradoPor, &s.GeradoEm); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		_ = json.Unmarshal(parametros, &s.Parametros)
		data = append(data, s)
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) ObterRelatorio(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var tipo string
	var parametros, conteudo []byte
	var geradoPor *int64
	var geradoEm time.Time
	err := h.db.QueryRow(r.Context(), `
		SELECT tipo, parametros, conteudo, gerado_por, gerado_em
		  FROM contabilidade.accounting_reports
		 WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).
		Scan(&tipo, &parametros, &conteudo, &geradoPor, &geradoEm)
	if err != nil {
		jsonErr(w, "Relatório não encontrado", http.StatusNotFound)
		return
	}

	var parametrosOut, conteudoOut any
	_ = json.Unmarshal(parametros, &parametrosOut)
	_ = json.Unmarshal(conteudo, &conteudoOut)

	jsonOK(w, map[string]any{
		"id":         id,
		"tipo":       tipo,
		"parametros": parametrosOut,
		"conteudo":   conteudoOut,
		"gerado_por": geradoPor,
		"gerado_em":  geradoEm,
	}, http.StatusOK)
}
