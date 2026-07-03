package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"

	mw "nexora/internal/middleware"
)

// calcularIRPS calcula o IRPS mensal usando os escalões configurados para o tenant.
// Se não existirem escalões, aplica os valores padrão de Moçambique 2024.
func (h *Handler) calcularIRPS(ctx context.Context, tenantID int64, salarioBruto float64) float64 {
	type escalao struct {
		LimiteInf  float64
		LimiteSup  *float64
		Taxa       float64
		ParcelaAbd float64
	}
	rows, err := h.db.Query(ctx, `
		SELECT limite_inf, limite_sup, taxa, parcela_ded
		  FROM rh.irps_escaloes
		 WHERE tenant_id=$1 AND ativo=TRUE
		 ORDER BY limite_inf`, tenantID)

	escaloes := []escalao{}
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var e escalao
			if rows.Scan(&e.LimiteInf, &e.LimiteSup, &e.Taxa, &e.ParcelaAbd) == nil {
				escaloes = append(escaloes, e)
			}
		}
	}

	// Escalões padrão Moçambique 2024 (tabela 2 – assalariados) se nenhum configurado
	if len(escaloes) == 0 {
		sup3500 := 3500.0
		sup10000 := 10000.0
		sup20000 := 20000.0
		sup38000 := 38000.0
		escaloes = []escalao{
			{0, &sup3500, 0, 0},          // 0–3.500 isento
			{3500.01, &sup10000, 0.10, 350},
			{10000.01, &sup20000, 0.15, 850},
			{20000.01, &sup38000, 0.20, 1850},
			{38000.01, nil, 0.32, 6410},
		}
	}

	for _, e := range escaloes {
		if salarioBruto <= e.LimiteInf {
			continue
		}
		if e.LimiteSup == nil || salarioBruto <= *e.LimiteSup {
			irps := salarioBruto*e.Taxa - e.ParcelaAbd
			if irps < 0 {
				return 0
			}
			return irps
		}
	}
	return 0
}

// calcularINSS retorna a quota do trabalhador (3%) sobre o salário bruto.
func calcularINSS(salarioBruto float64) float64 {
	return salarioBruto * 0.03
}

// prestacoesPendentes devolve adiantamentos e empréstimos activos do funcionário
// com os valores de prestação e ids, para inserir nos itens do recibo.
func (h *Handler) prestacoesPendentes(ctx context.Context, tx pgx.Tx, funcionarioID int64) (itens []struct {
	tabela string
	id     int64
	nome   string
	valor  float64
}) {
	// Adiantamentos
	rows, err := tx.Query(ctx, `
		SELECT id, COALESCE(descricao,'Adiantamento'), prestacao_valor
		  FROM rh.adiantamentos
		 WHERE funcionario_id=$1 AND estado='ativo'`, funcionarioID)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var id int64
			var nome string
			var valor float64
			if rows.Scan(&id, &nome, &valor) == nil {
				itens = append(itens, struct {
					tabela string
					id     int64
					nome   string
					valor  float64
				}{"adiantamentos", id, nome, valor})
			}
		}
	}

	// Empréstimos
	rows2, err := tx.Query(ctx, `
		SELECT id, COALESCE(descricao,'Empréstimo'), prestacao_valor
		  FROM rh.emprestimos
		 WHERE funcionario_id=$1 AND estado='ativo'`, funcionarioID)
	if err == nil {
		defer rows2.Close()
		for rows2.Next() {
			var id int64
			var nome string
			var valor float64
			if rows2.Scan(&id, &nome, &valor) == nil {
				itens = append(itens, struct {
					tabela string
					id     int64
					nome   string
					valor  float64
				}{"emprestimos", id, nome, valor})
			}
		}
	}
	return
}

// beneficiosAtivos devolve os benefícios atribuídos a um funcionário que estejam
// vigentes no período da folha (mês/ano).
func (h *Handler) beneficiosAtivos(ctx context.Context, tx pgx.Tx, funcionarioID int64, ano, mes int) ([]struct {
	id    int64
	nome  string
	valor float64
}, error) {
	inicioMes := time.Date(ano, time.Month(mes), 1, 0, 0, 0, 0, time.UTC)
	fimMes := inicioMes.AddDate(0, 1, -1)

	rows, err := tx.Query(ctx, `
		SELECT b.id, COALESCE(b.nome,'Benefício'), COALESCE(fb.valor, b.valor_padrao, 0)
		  FROM rh.funcionario_beneficios fb
		  JOIN rh.beneficios b ON b.id = fb.beneficio_id
		 WHERE fb.funcionario_id=$1
		   AND fb.data_inicio <= $2
		   AND (fb.data_fim IS NULL OR fb.data_fim >= $3)
		   AND b.ativo = TRUE`, funcionarioID, fimMes, inicioMes)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var itens []struct {
		id    int64
		nome  string
		valor float64
	}
	for rows.Next() {
		var it struct {
			id    int64
			nome  string
			valor float64
		}
		if rows.Scan(&it.id, &it.nome, &it.valor) == nil {
			itens = append(itens, it)
		}
	}
	return itens, nil
}

// diasUteisNoMes conta dias de segunda a sexta no mês.
func diasUteisNoMes(ano, mes int) int {
	inicio := time.Date(ano, time.Month(mes), 1, 0, 0, 0, 0, time.UTC)
	fim := inicio.AddDate(0, 1, -1)
	dias := 0
	for d := inicio; !d.After(fim); d = d.AddDate(0, 0, 1) {
		wd := d.Weekday()
		if wd != time.Saturday && wd != time.Sunday {
			dias++
		}
	}
	return dias
}

// ausenciasNaoRemuneradas devolve o número de dias úteis de ausência não remunerada
// aprovada/gozada no período da folha.
func (h *Handler) ausenciasNaoRemuneradas(ctx context.Context, tx pgx.Tx, funcionarioID int64, ano, mes int) (dias int, err error) {
	inicioMes := time.Date(ano, time.Month(mes), 1, 0, 0, 0, 0, time.UTC)
	fimMes := inicioMes.AddDate(0, 1, -1)

	rows, err := tx.Query(ctx, `
		SELECT a.data_inicio, a.data_fim
		  FROM rh.ausencias a
		  JOIN rh.tipos_ausencia ta ON ta.id = a.tipo_id
		 WHERE a.funcionario_id=$1
		   AND a.estado IN ('aprovado','gozada')
		   AND ta.remunerada = FALSE
		   AND a.data_inicio <= $2
		   AND a.data_fim >= $3`, funcionarioID, fimMes, inicioMes)
	if err != nil {
		return 0, err
	}
	defer rows.Close()

	total := 0
	for rows.Next() {
		var dataInicio, dataFim time.Time
		if err := rows.Scan(&dataInicio, &dataFim); err != nil {
			continue
		}
		if dataInicio.Before(inicioMes) {
			dataInicio = inicioMes
		}
		if dataFim.After(fimMes) {
			dataFim = fimMes
		}
		for d := dataInicio; !d.After(dataFim); d = d.AddDate(0, 0, 1) {
			wd := d.Weekday()
			if wd != time.Saturday && wd != time.Sunday {
				total++
			}
		}
	}
	return total, nil
}

// presencasNoPeriodo devolve faltas (dias sem registo de entrada/saída) e total de horas extra.
func (h *Handler) presencasNoPeriodo(ctx context.Context, tx pgx.Tx, funcionarioID int64, ano, mes int) (faltas int, horasExtra float64, err error) {
	inicioMes := time.Date(ano, time.Month(mes), 1, 0, 0, 0, 0, time.UTC)
	fimMes := inicioMes.AddDate(0, 1, -1)

	rows, err := tx.Query(ctx, `
		SELECT hora_entrada IS NULL AND hora_saida IS NULL AS falta,
		       COALESCE(horas_extra,0) AS horas_extra
		  FROM rh.presencas
		 WHERE funcionario_id=$1 AND data BETWEEN $2 AND $3`, funcionarioID, inicioMes, fimMes)
	if err != nil {
		return 0, 0, err
	}
	defer rows.Close()

	faltas = 0
	horasExtra = 0
	for rows.Next() {
		var falta bool
		var extra float64
		if rows.Scan(&falta, &extra) == nil {
			if falta {
				faltas++
			}
			horasExtra += extra
		}
	}
	return faltas, horasExtra, nil
}

// ── Folhas de Pagamento (processamento salarial) ────────────────────────────

type folhaPagamentoRow struct {
	ID              int64      `json:"id"`
	Ano             int        `json:"ano"`
	Mes             int        `json:"mes"`
	Estado          string     `json:"estado"`
	NumFuncionarios int        `json:"num_funcionarios"`
	TotalProventos  *float64   `json:"total_proventos"`
	TotalDescontos  *float64   `json:"total_descontos"`
	TotalLiquido    *float64   `json:"total_liquido"`
	ProcessadaEm    *time.Time `json:"processada_em"`
	PagaEm          *time.Time `json:"paga_em"`
	CreatedAt       time.Time  `json:"created_at"`
}

func (h *Handler) ListarFolhasPagamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	rows, err := h.db.Query(r.Context(), `
		SELECT id, ano, mes, estado, num_funcionarios, total_proventos, total_descontos, total_liquido, processada_em, paga_em, created_at
		  FROM rh.folhas_pagamento
		 WHERE tenant_id=$1
		 ORDER BY ano DESC, mes DESC`, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	podeVerSalarios := h.PodeVerSalarios(r)
	data := []folhaPagamentoRow{}
	for rows.Next() {
		var f folhaPagamentoRow
		var totalProventos, totalDescontos, totalLiquido float64
		if rows.Scan(&f.ID, &f.Ano, &f.Mes, &f.Estado, &f.NumFuncionarios, &totalProventos, &totalDescontos, &totalLiquido, &f.ProcessadaEm, &f.PagaEm, &f.CreatedAt) == nil {
			if podeVerSalarios {
				f.TotalProventos = &totalProventos
				f.TotalDescontos = &totalDescontos
				f.TotalLiquido = &totalLiquido
			}
			data = append(data, f)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarFolhaPagamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var body struct {
		Ano int `json:"ano"`
		Mes int `json:"mes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Ano < 2000 || body.Ano > 2100 || body.Mes < 1 || body.Mes > 12 {
		jsonErr(w, "ano e mes são obrigatórios e devem ser válidos", http.StatusBadRequest)
		return
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.folhas_pagamento (tenant_id, ano, mes)
		VALUES ($1,$2,$3) RETURNING id`,
		user.TenantID, body.Ano, body.Mes).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe uma folha de pagamento para este mês/ano", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterFolhaPagamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	podeVerSalarios := h.PodeVerSalarios(r)

	var f folhaPagamentoRow
	var totalProventos, totalDescontos, totalLiquido float64
	var journalEntryID *int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT id, ano, mes, estado, num_funcionarios, total_proventos, total_descontos, total_liquido,
		       processada_em, paga_em, created_at, journal_entry_id
		  FROM rh.folhas_pagamento
		 WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).Scan(
		&f.ID, &f.Ano, &f.Mes, &f.Estado, &f.NumFuncionarios, &totalProventos, &totalDescontos, &totalLiquido,
		&f.ProcessadaEm, &f.PagaEm, &f.CreatedAt, &journalEntryID); err != nil {
		jsonErr(w, "Folha de pagamento não encontrada", http.StatusNotFound)
		return
	}
	if podeVerSalarios {
		f.TotalProventos = &totalProventos
		f.TotalDescontos = &totalDescontos
		f.TotalLiquido = &totalLiquido
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT rv.id, rv.funcionario_id, fu.nome_completo, fu.numero_funcionario, rv.salario_base, rv.total_proventos, rv.total_descontos, rv.salario_liquido, rv.estado
		  FROM rh.recibos_vencimento rv
		  JOIN rh.funcionarios fu ON fu.id = rv.funcionario_id
		 WHERE rv.folha_id=$1 AND rv.tenant_id=$2
		 ORDER BY fu.nome_completo`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type ReciboRow struct {
		ID                int64    `json:"id"`
		FuncionarioID     int64    `json:"funcionario_id"`
		NomeCompleto      string   `json:"nome_completo"`
		NumeroFuncionario *string  `json:"numero_funcionario"`
		SalarioBase       *float64 `json:"salario_base"`
		TotalProventos    *float64 `json:"total_proventos"`
		TotalDescontos    *float64 `json:"total_descontos"`
		SalarioLiquido    *float64 `json:"salario_liquido"`
		Estado            string   `json:"estado"`
	}
	recibos := []ReciboRow{}
	for rows.Next() {
		var rv ReciboRow
		var salarioBase, rvTotalProventos, rvTotalDescontos, salarioLiquido float64
		if rows.Scan(&rv.ID, &rv.FuncionarioID, &rv.NomeCompleto, &rv.NumeroFuncionario, &salarioBase, &rvTotalProventos, &rvTotalDescontos, &salarioLiquido, &rv.Estado) == nil {
			if podeVerSalarios {
				rv.SalarioBase = &salarioBase
				rv.TotalProventos = &rvTotalProventos
				rv.TotalDescontos = &rvTotalDescontos
				rv.SalarioLiquido = &salarioLiquido
			}
			recibos = append(recibos, rv)
		}
	}

	jsonOK(w, map[string]any{"folha": f, "recibos": recibos, "pode_ver_salarios": podeVerSalarios, "journal_entry_id": journalEntryID}, http.StatusOK)
}

func (h *Handler) ProcessarFolhaPagamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var estado string
	var folhaAno, folhaMes int
	if err := tx.QueryRow(r.Context(), `SELECT estado, ano, mes FROM rh.folhas_pagamento WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).Scan(&estado, &folhaAno, &folhaMes); err != nil {
		jsonErr(w, "Folha de pagamento não encontrada", http.StatusNotFound)
		return
	}
	if estado != "aberta" {
		jsonErr(w, "Apenas folhas em estado 'aberta' podem ser processadas", http.StatusConflict)
		return
	}

	funcRows, err := tx.Query(r.Context(), `
		SELECT id, COALESCE(salario_base,0), centro_custo_id FROM rh.funcionarios WHERE tenant_id=$1 AND estado='ativo'`, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	type funcionarioSalario struct {
		ID            int64
		SalarioBase   float64
		CentroCustoID *int64
	}
	funcionarios := []funcionarioSalario{}
	for funcRows.Next() {
		var fs funcionarioSalario
		if funcRows.Scan(&fs.ID, &fs.SalarioBase, &fs.CentroCustoID) == nil {
			funcionarios = append(funcionarios, fs)
		}
	}
	funcRows.Close()

	if _, err := tx.Exec(r.Context(), `DELETE FROM rh.recibos_vencimento WHERE folha_id=$1`, id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	// Remover alocações de centros de custo anteriores desta folha (reprocessamento)
	if _, err := tx.Exec(r.Context(), `
		DELETE FROM centros_custo.cost_center_allocations
		 WHERE source_service='rh' AND source_type='recibo_vencimento'
		   AND referencia_tipo='folha_pagamento' AND referencia_id=$1 AND tenant_id=$2`, id, user.TenantID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	type componenteAtribuido struct {
		ComponenteID int64
		Codigo       string
		Nome         string
		Tipo         string
		FormaCalculo string
		Valor        float64
	}

	var totalProventosFolha, totalDescontosFolha, totalLiquidoFolha float64
	numFuncionarios := 0

	for _, fs := range funcionarios {
		compRows, err := tx.Query(r.Context(), `
			SELECT c.id, c.codigo, c.nome, c.tipo, c.forma_calculo, fc.valor
			  FROM rh.funcionario_componentes_salariais fc
			  JOIN rh.componentes_salariais c ON c.id = fc.componente_id
			 WHERE fc.funcionario_id=$1 AND fc.tenant_id=$2 AND c.ativo`, fs.ID, user.TenantID)
		if err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		componentes := []componenteAtribuido{}
		for compRows.Next() {
			var c componenteAtribuido
			if compRows.Scan(&c.ComponenteID, &c.Codigo, &c.Nome, &c.Tipo, &c.FormaCalculo, &c.Valor) == nil {
				componentes = append(componentes, c)
			}
		}
		compRows.Close()

		var totalProventos, totalDescontos float64
		type itemCalculado struct {
			ComponenteID *int64
			Nome         string
			Tipo         string
			Valor        float64
		}
		itens := []itemCalculado{}
		// Detecta por CÓDIGO se INSS/IRPS já estão atribuídos como componentes manuais
		inssManual, irpsManual := false, false
		for _, c := range componentes {
			valor := c.Valor
			if c.FormaCalculo == "percentual" {
				valor = fs.SalarioBase * c.Valor / 100
			}
			if c.Tipo == "provento" {
				totalProventos += valor
			} else {
				totalDescontos += valor
			}
			cid := c.ComponenteID
			itens = append(itens, itemCalculado{&cid, c.Nome, c.Tipo, valor})
			// Detecção robusta por código (case-insensitive prefix)
			switch {
			case c.Codigo == "INSS" || c.Codigo == "inss":
				inssManual = true
			case c.Codigo == "IRPS" || c.Codigo == "irps":
				irpsManual = true
			}
		}

		// Benefícios ativos no período (convertidos em proventos)
		beneficios, err := h.beneficiosAtivos(r.Context(), tx, fs.ID, folhaAno, folhaMes)
		if err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		for _, b := range beneficios {
			if b.valor > 0 {
				totalProventos += b.valor
				itens = append(itens, itemCalculado{nil, b.nome, "provento", b.valor})
			}
		}

		// Ausências não-remuneradas no período
		diasUteis := diasUteisNoMes(folhaAno, folhaMes)
		if diasUteis > 0 {
			diasAusencia, err := h.ausenciasNaoRemuneradas(r.Context(), tx, fs.ID, folhaAno, folhaMes)
			if err != nil {
				jsonErr(w, "Erro interno", http.StatusInternalServerError)
				return
			}
			if diasAusencia > 0 {
				descontoAusencia := fs.SalarioBase / float64(diasUteis) * float64(diasAusencia)
				totalDescontos += descontoAusencia
				itens = append(itens, itemCalculado{nil, fmt.Sprintf("Ausência não remunerada (%d dias)", diasAusencia), "desconto", descontoAusencia})
			}
		}

		// Presenças: faltas e horas extra
		faltas, horasExtra, err := h.presencasNoPeriodo(r.Context(), tx, fs.ID, folhaAno, folhaMes)
		if err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		if diasUteis > 0 && faltas > 0 {
			descontoFalta := fs.SalarioBase / float64(diasUteis) * float64(faltas)
			totalDescontos += descontoFalta
			itens = append(itens, itemCalculado{nil, fmt.Sprintf("Falta (%d dias)", faltas), "desconto", descontoFalta})
		}
		if diasUteis > 0 && horasExtra > 0 {
			// Valor hora baseado em 8h/dia útil, com factor 1.5x
			valorHora := fs.SalarioBase / (float64(diasUteis) * 8)
			valorHorasExtra := valorHora * horasExtra * 1.5
			if valorHorasExtra > 0 {
				totalProventos += valorHorasExtra
				itens = append(itens, itemCalculado{nil, fmt.Sprintf("Horas extra (%.2f h)", horasExtra), "provento", valorHorasExtra})
			}
		}

		// Salário bruto para cálculo de IRPS e INSS
		salarioBruto := fs.SalarioBase + totalProventos

		// INSS (3% quota trabalhador) — só se não já existe componente com código INSS
		if !inssManual {
			inss := calcularINSS(salarioBruto)
			if inss > 0 {
				totalDescontos += inss
				itens = append(itens, itemCalculado{nil, "INSS (3%)", "desconto", inss})
			}
		}

		// IRPS — só se não já existe componente com código IRPS
		if !irpsManual {
			irps := h.calcularIRPS(r.Context(), user.TenantID, salarioBruto)
			if irps > 0 {
				totalDescontos += irps
				itens = append(itens, itemCalculado{nil, "IRPS", "desconto", irps})
			}
		}

		// Prestações de adiantamentos e empréstimos activos
		for _, prest := range h.prestacoesPendentes(r.Context(), tx, fs.ID) {
			totalDescontos += prest.valor
			itens = append(itens, itemCalculado{nil, prest.nome, "desconto", prest.valor})
		}

		salarioLiquido := fs.SalarioBase + totalProventos - totalDescontos

		var reciboID int64
		if err := tx.QueryRow(r.Context(), `
			INSERT INTO rh.recibos_vencimento (tenant_id, folha_id, funcionario_id, salario_base, total_proventos, total_descontos, salario_liquido, centro_custo_id)
			VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
			user.TenantID, id, fs.ID, fs.SalarioBase, totalProventos, totalDescontos, salarioLiquido, fs.CentroCustoID).Scan(&reciboID); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}

		for _, it := range itens {
			if _, err := tx.Exec(r.Context(), `
				INSERT INTO rh.recibo_vencimento_itens (recibo_id, componente_id, nome, tipo, valor)
				VALUES ($1,$2,$3,$4,$5)`,
				reciboID, it.ComponenteID, it.Nome, it.Tipo, it.Valor); err != nil {
				jsonErr(w, "Erro interno", http.StatusInternalServerError)
				return
			}
		}

		// Alocação automática de centro de custo com base no salário bruto
		if fs.CentroCustoID != nil && *fs.CentroCustoID != 0 && salarioBruto > 0 {
			descricao := fmt.Sprintf("Folha salarial %02d/%04d", folhaMes, folhaAno)
			if _, err := tx.Exec(r.Context(), `
				INSERT INTO centros_custo.cost_center_allocations
				  (tenant_id, cost_center_id, source_service, source_type, source_id, source_line_id,
				   descricao, valor, moeda, allocation_percent, referencia_tipo, referencia_id, created_by)
				VALUES ($1,$2,'rh','recibo_vencimento',$3,NULL,$4,$5,'MZN',100,'folha_pagamento',$6,$7)`,
				user.TenantID, *fs.CentroCustoID, reciboID, descricao, salarioBruto, id, user.ID); err != nil {
				jsonErr(w, "Erro interno", http.StatusInternalServerError)
				return
			}
		}

		// Incrementar prestações pagas para adiantamentos e empréstimos
		for _, prest := range h.prestacoesPendentes(r.Context(), tx, fs.ID) {
			var table string
			switch prest.tabela {
			case "adiantamentos":
				table = "adiantamentos"
			case "emprestimos":
				table = "emprestimos"
			default:
				continue
			}
			tx.Exec(r.Context(),
				`UPDATE `+table+` SET prestacoes_pagas = prestacoes_pagas + 1,
				  estado = CASE WHEN prestacoes_pagas + 1 >= num_prestacoes THEN 'quitado' ELSE estado END
				  WHERE id = $1`, prest.id)
		}

		totalProventosFolha += totalProventos
		totalDescontosFolha += totalDescontos
		totalLiquidoFolha += salarioLiquido
		numFuncionarios++
	}

	if _, err := tx.Exec(r.Context(), `
		UPDATE rh.folhas_pagamento SET
		  estado='processada', num_funcionarios=$1, total_proventos=$2, total_descontos=$3, total_liquido=$4,
		  processada_em=NOW(), processada_por=$5
		WHERE id=$6 AND tenant_id=$7`,
		numFuncionarios, totalProventosFolha, totalDescontosFolha, totalLiquidoFolha, user.ID, id, user.TenantID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// proximoNumeroLancamentoFolha obtém e incrementa a sequência do diário/ano.
func proximoNumeroLancamentoFolha(ctx context.Context, tx pgx.Tx, tenantID, journalID int64, ano int, codigoDiario string) (string, error) {
	_, err := tx.Exec(ctx, `
		INSERT INTO contabilidade.journal_entry_sequences (tenant_id, accounting_journal_id, ano, proxima_sequencia)
		VALUES ($1,$2,$3,1)
		ON CONFLICT (tenant_id, accounting_journal_id, ano) DO NOTHING`,
		tenantID, journalID, ano)
	if err != nil {
		return "", err
	}

	var seq int
	err = tx.QueryRow(ctx, `
		SELECT proxima_sequencia FROM contabilidade.journal_entry_sequences
		 WHERE tenant_id=$1 AND accounting_journal_id=$2 AND ano=$3
		 FOR UPDATE`,
		tenantID, journalID, ano).Scan(&seq)
	if err != nil {
		return "", err
	}

	_, err = tx.Exec(ctx, `
		UPDATE contabilidade.journal_entry_sequences SET proxima_sequencia=proxima_sequencia+1
		 WHERE tenant_id=$1 AND accounting_journal_id=$2 AND ano=$3`,
		tenantID, journalID, ano)
	if err != nil {
		return "", err
	}

	return fmt.Sprintf("%s/%d/%04d", codigoDiario, ano, seq), nil
}

type configContabFolha struct {
	AccountingJournalID  int64
	ContaDespesaSalarios int64
	ContaINSSTrabalhador int64
	ContaIRPS            int64
	ContaSalariosAPagar  int64
	ContaAdiantamentos   *int64
	ContaINSSPatronal    *int64
	TaxaINSSPatronal     float64
}

// configContabilidadeFolha devolve a configuração contabilística activa do tenant.
func (h *Handler) configContabilidadeFolha(ctx context.Context, tx pgx.Tx, tenantID int64) (*configContabFolha, error) {
	var cfg configContabFolha
	var contaAdiantamentos, contaINSSPatronal *int64
	err := tx.QueryRow(ctx, `
		SELECT accounting_journal_id, conta_despesa_salarios, conta_inss_trabalhador,
		       conta_irps, conta_salarios_a_pagar, conta_adiantamentos, conta_inss_patronal,
		       COALESCE(taxa_inss_patronal,0)
		  FROM rh.config_contabilidade_folha
		 WHERE tenant_id=$1 AND ativo=TRUE`, tenantID).Scan(
		&cfg.AccountingJournalID, &cfg.ContaDespesaSalarios, &cfg.ContaINSSTrabalhador,
		&cfg.ContaIRPS, &cfg.ContaSalariosAPagar, &contaAdiantamentos, &contaINSSPatronal,
		&cfg.TaxaINSSPatronal)
	if err != nil {
		return nil, err
	}
	cfg.ContaAdiantamentos = contaAdiantamentos
	cfg.ContaINSSPatronal = contaINSSPatronal
	return &cfg, nil
}

// totaisFolhaParaLancamento agrega os valores necessários ao lançamento contabilístico.
func (h *Handler) totaisFolhaParaLancamento(ctx context.Context, tx pgx.Tx, folhaID int64) (salarioBase, proventos, inss, irps, adiantamentos float64, err error) {
	rows, err := tx.Query(ctx, `
		SELECT nome, valor FROM rh.recibo_vencimento_itens
		 WHERE recibo_id IN (SELECT id FROM rh.recibos_vencimento WHERE folha_id=$1)`, folhaID)
	if err != nil {
		return 0, 0, 0, 0, 0, err
	}
	defer rows.Close()

	for rows.Next() {
		var nome string
		var valor float64
		if err := rows.Scan(&nome, &valor); err != nil {
			continue
		}
		switch {
		case nome == "INSS (3%)":
			inss += valor
		case nome == "IRPS":
			irps += valor
		case nome == "Adiantamento" || nome == "Empréstimo" || len(nome) >= 13 && nome[:13] == "Adiantamento":
			adiantamentos += valor
		}
	}

	var base, prov float64
	err = tx.QueryRow(ctx, `
		SELECT COALESCE(SUM(salario_base),0), COALESCE(SUM(total_proventos),0)
		  FROM rh.recibos_vencimento WHERE folha_id=$1`, folhaID).Scan(&base, &prov)
	if err != nil {
		return 0, 0, 0, 0, 0, err
	}
	return base, prov, inss, irps, adiantamentos, nil
}

// criarLancamentoContabilisticoFolha cria o journal_entry de pagamento de salários.
func (h *Handler) criarLancamentoContabilisticoFolha(ctx context.Context, tx pgx.Tx, tenantID, userID, folhaID int64, ano, mes int, cfg *configContabFolha) (int64, string, error) {
	// Período fiscal aberto
	var periodoID int64
	var periodoStatus string
	err := tx.QueryRow(ctx, `
		SELECT id, status FROM contabilidade.fiscal_periods
		 WHERE tenant_id=$1 AND ano=$2 AND mes=$3`, tenantID, ano, mes).Scan(&periodoID, &periodoStatus)
	if err != nil {
		return 0, "", fmt.Errorf("período fiscal não encontrado")
	}
	if periodoStatus != "aberto" {
		return 0, "", fmt.Errorf("período fiscal não está aberto")
	}

	// Diário
	var codigoDiario string
	err = tx.QueryRow(ctx, `
		SELECT codigo FROM contabilidade.accounting_journals
		 WHERE id=$1 AND tenant_id=$2`, cfg.AccountingJournalID, tenantID).Scan(&codigoDiario)
	if err != nil {
		return 0, "", fmt.Errorf("diário não encontrado")
	}

	salarioBase, proventos, inss, irps, adiantamentos, err := h.totaisFolhaParaLancamento(ctx, tx, folhaID)
	if err != nil {
		return 0, "", err
	}

	totalDespesa := salarioBase + proventos
	inssPatronal := totalDespesa * cfg.TaxaINSSPatronal

	// Linhas do lançamento
	linhas := []struct {
		accountID int64
		debit     float64
		credit    float64
		descricao string
	}{}

	// Débito: despesa salarial
	if totalDespesa > 0 {
		linhas = append(linhas, struct {
			accountID int64
			debit     float64
			credit    float64
			descricao string
		}{cfg.ContaDespesaSalarios, totalDespesa, 0, "Despesa com salários e proventos"})
	}

	// Débito: INSS patronal (se configurado)
	if inssPatronal > 0 && cfg.ContaINSSPatronal != nil {
		linhas = append(linhas, struct {
			accountID int64
			debit     float64
			credit    float64
			descricao string
		}{*cfg.ContaINSSPatronal, inssPatronal, 0, fmt.Sprintf("INSS patronal (%.2f%%)", cfg.TaxaINSSPatronal*100)})
	}

	// Crédito: INSS trabalhador
	if inss > 0 {
		linhas = append(linhas, struct {
			accountID int64
			debit     float64
			credit    float64
			descricao string
		}{cfg.ContaINSSTrabalhador, 0, inss, "INSS trabalhador a reter"})
	}

	// Crédito: IRPS
	if irps > 0 {
		linhas = append(linhas, struct {
			accountID int64
			debit     float64
			credit    float64
			descricao string
		}{cfg.ContaIRPS, 0, irps, "IRPS a reter"})
	}

	// Crédito: adiantamentos/empréstimos
	if adiantamentos > 0 && cfg.ContaAdiantamentos != nil {
		linhas = append(linhas, struct {
			accountID int64
			debit     float64
			credit    float64
			descricao string
		}{*cfg.ContaAdiantamentos, 0, adiantamentos, "Adiantamentos/empréstimos a reter"})
	}

	// Crédito: salários a pagar (valor líquido + INSS patronal)
	salariosAPagar := totalDespesa + inssPatronal - inss - irps - adiantamentos
	if salariosAPagar < 0 {
		salariosAPagar = 0
	}
	if salariosAPagar > 0 {
		linhas = append(linhas, struct {
			accountID int64
			debit     float64
			credit    float64
			descricao string
		}{cfg.ContaSalariosAPagar, 0, salariosAPagar, "Salários líquidos a pagar"})
	}

	if len(linhas) < 2 {
		return 0, "", fmt.Errorf("não há valores suficientes para gerar lançamento contabilístico")
	}

	// Calcular totais e validar balanceamento
	var totalDebito, totalCredito float64
	for _, l := range linhas {
		totalDebito += l.debit
		totalCredito += l.credit
	}
	if math.Abs(totalDebito-totalCredito) > 0.005 {
		return 0, "", fmt.Errorf("lançamento não balanceado")
	}

	// Número sequencial
	numero, err := proximoNumeroLancamentoFolha(ctx, tx, tenantID, cfg.AccountingJournalID, ano, codigoDiario)
	if err != nil {
		return 0, "", err
	}

	entryDate := fmt.Sprintf("%04d-%02d-%02d", ano, mes, 1)
	lastDay := time.Date(ano, time.Month(mes), 1, 0, 0, 0, 0, time.UTC).AddDate(0, 1, -1)
	entryDate = lastDay.Format("2006-01-02")

	descricao := fmt.Sprintf("Folha salarial %02d/%04d", mes, ano)
	refTipo := "folha_pagamento"

	var entryID int64
	err = tx.QueryRow(ctx, `
		INSERT INTO contabilidade.journal_entries
		  (tenant_id, fiscal_period_id, accounting_journal_id, numero, entry_date, descricao,
		   referencia_tipo, referencia_id, status, moeda, total_debito, total_credito,
		   criado_por, publicado_por, publicado_em)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,'publicado','MZN',$9,$10,$11,$11,NOW())
		RETURNING id`,
		tenantID, periodoID, cfg.AccountingJournalID, numero, entryDate, descricao,
		refTipo, folhaID, totalDebito, totalCredito, userID).Scan(&entryID)
	if err != nil {
		return 0, "", err
	}

	for _, l := range linhas {
		if _, err := tx.Exec(ctx, `
			INSERT INTO contabilidade.journal_entry_lines (journal_entry_id, account_id, descricao, debit, credit)
			VALUES ($1,$2,$3,$4,$5)`,
			entryID, l.accountID, l.descricao, l.debit, l.credit); err != nil {
			return 0, "", err
		}
	}

	return entryID, numero, nil
}

// saldoContaOuCaixa devolve o saldo actual e a moeda de uma conta bancária ou caixa.
func (h *Handler) saldoContaOuCaixa(ctx context.Context, tx pgx.Tx, tenantID int64, bankAccountID, cashRegisterID *int64) (saldo float64, moeda string, err error) {
	if bankAccountID != nil {
		err = tx.QueryRow(ctx, `
			SELECT saldo_actual, moeda FROM tesouraria.bank_accounts
			 WHERE id=$1 AND tenant_id=$2 AND activo`, *bankAccountID, tenantID).Scan(&saldo, &moeda)
	} else if cashRegisterID != nil {
		err = tx.QueryRow(ctx, `
			SELECT saldo_actual, moeda FROM tesouraria.cash_registers
			 WHERE id=$1 AND tenant_id=$2 AND activo`, *cashRegisterID, tenantID).Scan(&saldo, &moeda)
	} else {
		err = fmt.Errorf("conta bancária ou caixa não indicada")
	}
	return
}

// criarMovimentoTesourariaFolha cria o pagamento na tesouraria e actualiza o saldo.
func (h *Handler) criarMovimentoTesourariaFolha(ctx context.Context, tx pgx.Tx, tenantID, userID, folhaID int64, ano, mes int, totalLiquido float64, bankAccountID, cashRegisterID *int64) (int64, error) {
	if (bankAccountID == nil) == (cashRegisterID == nil) {
		return 0, fmt.Errorf("indique uma conta bancária ou uma caixa, mas não ambas")
	}

	saldo, moeda, err := h.saldoContaOuCaixa(ctx, tx, tenantID, bankAccountID, cashRegisterID)
	if err != nil {
		return 0, fmt.Errorf("conta/caixa não encontrada ou inativa")
	}
	if saldo < totalLiquido {
		return 0, fmt.Errorf("saldo insuficiente (disponível: %.2f %s, necessário: %.2f %s)", saldo, moeda, totalLiquido, moeda)
	}

	dataMovimento := time.Date(ano, time.Month(mes), 1, 0, 0, 0, 0, time.UTC).AddDate(0, 1, -1)
	referencia := fmt.Sprintf("FOLHA/%02d/%04d", mes, ano)
	descricao := fmt.Sprintf("Pagamento de salários %02d/%04d", mes, ano)
	refTipo := "folha_pagamento"

	var movementID int64
	err = tx.QueryRow(ctx, `
		INSERT INTO tesouraria.movements
		  (tenant_id, bank_account_id, cash_register_id, tipo, valor, moeda, data_movimento,
		   metodo, referencia, descricao, reference_type, reference_id, created_by)
		VALUES ($1,$2,$3,'pagamento',$4,$5,$6,'transferencia',$7,$8,$9,$10,$11)
		RETURNING id`,
		tenantID, bankAccountID, cashRegisterID, totalLiquido, moeda, dataMovimento,
		referencia, descricao, refTipo, folhaID, userID).Scan(&movementID)
	if err != nil {
		return 0, err
	}

	delta := -totalLiquido
	var tag pgconn.CommandTag
	if bankAccountID != nil {
		tag, err = tx.Exec(ctx, `
			UPDATE tesouraria.bank_accounts SET saldo_actual=saldo_actual+$1, updated_at=NOW()
			 WHERE id=$2 AND tenant_id=$3 AND activo`, delta, *bankAccountID, tenantID)
	} else {
		tag, err = tx.Exec(ctx, `
			UPDATE tesouraria.cash_registers SET saldo_actual=saldo_actual+$1, updated_at=NOW()
			 WHERE id=$2 AND tenant_id=$3 AND activo`, delta, *cashRegisterID, tenantID)
	}
	if err != nil || tag.RowsAffected() != 1 {
		return 0, fmt.Errorf("erro ao actualizar saldo")
	}

	return movementID, nil
}

// estornarMovimentoTesourariaFolha reverte o movimento de pagamento criado para a folha.
func (h *Handler) estornarMovimentoTesourariaFolha(ctx context.Context, tx pgx.Tx, tenantID, folhaID int64) error {
	var movementID int64
	var bankAccountID, cashRegisterID *int64
	var valor float64
	err := tx.QueryRow(ctx, `
		SELECT id, bank_account_id, cash_register_id, valor
		  FROM tesouraria.movements
		 WHERE tenant_id=$1 AND reference_type='folha_pagamento' AND reference_id=$2
		 LIMIT 1`, tenantID, folhaID).Scan(&movementID, &bankAccountID, &cashRegisterID, &valor)
	if err != nil {
		return nil // não há movimento para estornar
	}

	delta := valor
	var tag pgconn.CommandTag
	if bankAccountID != nil {
		tag, err = tx.Exec(ctx, `
			UPDATE tesouraria.bank_accounts SET saldo_actual=saldo_actual+$1, updated_at=NOW()
			 WHERE id=$2 AND tenant_id=$3`, delta, *bankAccountID, tenantID)
	} else if cashRegisterID != nil {
		tag, err = tx.Exec(ctx, `
			UPDATE tesouraria.cash_registers SET saldo_actual=saldo_actual+$1, updated_at=NOW()
			 WHERE id=$2 AND tenant_id=$3`, delta, *cashRegisterID, tenantID)
	}
	if err != nil || tag.RowsAffected() != 1 {
		return fmt.Errorf("erro ao reverter saldo")
	}

	_, err = tx.Exec(ctx, `DELETE FROM tesouraria.movements WHERE id=$1 AND tenant_id=$2`, movementID, tenantID)
	return err
}

func (h *Handler) PagarFolhaPagamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		BankAccountID  *int64 `json:"bank_account_id"`
		CashRegisterID *int64 `json:"cash_register_id"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var estado string
	var folhaAno, folhaMes int
	if err := tx.QueryRow(r.Context(), `SELECT estado, ano, mes FROM rh.folhas_pagamento WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).Scan(&estado, &folhaAno, &folhaMes); err != nil {
		jsonErr(w, "Folha de pagamento não encontrada", http.StatusNotFound)
		return
	}
	if estado != "processada" {
		jsonErr(w, "Apenas folhas em estado 'processada' podem ser pagas", http.StatusConflict)
		return
	}

	folhaID, err := strconv.ParseInt(id, 10, 64)
	if err != nil {
		jsonErr(w, "ID da folha inválido", http.StatusBadRequest)
		return
	}

	// Verificar se já existe lançamento contabilístico
	var journalEntryID *int64
	if err := tx.QueryRow(r.Context(), `SELECT journal_entry_id FROM rh.folhas_pagamento WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).Scan(&journalEntryID); err == nil && journalEntryID != nil {
		jsonErr(w, "Esta folha já tem um lançamento contabilístico associado", http.StatusConflict)
		return
	}

	// Configuração contabilística
	cfg, err := h.configContabilidadeFolha(r.Context(), tx, user.TenantID)
	if err != nil {
		jsonErr(w, "Configuração contabilística da folha não encontrada. Configure as contas em Configurações > RH.", http.StatusConflict)
		return
	}

	// Criar lançamento contabilístico
	entryID, entryNumero, err := h.criarLancamentoContabilisticoFolha(r.Context(), tx, user.TenantID, user.ID, folhaID, folhaAno, folhaMes, cfg)
	if err != nil {
		jsonErr(w, err.Error(), http.StatusConflict)
		return
	}

	// Total líquido da folha para movimento de tesouraria
	var totalLiquido float64
	if err := tx.QueryRow(r.Context(), `SELECT COALESCE(total_liquido,0) FROM rh.folhas_pagamento WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).Scan(&totalLiquido); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	// Criar movimento de tesouraria
	movementID, err := h.criarMovimentoTesourariaFolha(r.Context(), tx, user.TenantID, user.ID, folhaID, folhaAno, folhaMes, totalLiquido, body.BankAccountID, body.CashRegisterID)
	if err != nil {
		jsonErr(w, err.Error(), http.StatusConflict)
		return
	}

	if _, err := tx.Exec(r.Context(), `
		UPDATE rh.folhas_pagamento
		   SET estado='paga', paga_em=NOW(), journal_entry_id=$1,
		       bank_account_id=$2, cash_register_id=$3, movement_id=$4
		 WHERE id=$5 AND tenant_id=$6`,
		entryID, body.BankAccountID, body.CashRegisterID, movementID, id, user.TenantID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if _, err := tx.Exec(r.Context(), `UPDATE rh.recibos_vencimento SET estado='pago' WHERE folha_id=$1 AND tenant_id=$2`, id, user.TenantID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{
		"ok": true,
		"journal_entry_id": entryID,
		"journal_entry_numero": entryNumero,
		"movement_id": movementID,
	}, http.StatusOK)
}

func (h *Handler) CancelarFolhaPagamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var estado string
	var folhaID int64
	var journalEntryID, movementID *int64
	if err := tx.QueryRow(r.Context(), `
		SELECT estado, id, journal_entry_id, movement_id
		  FROM rh.folhas_pagamento WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).Scan(
		&estado, &folhaID, &journalEntryID, &movementID); err != nil {
		jsonErr(w, "Folha de pagamento não encontrada", http.StatusNotFound)
		return
	}

	// Cancelamento de folhas abertas/processadas mantém comportamento anterior
	if estado == "aberta" || estado == "processada" {
		if _, err := tx.Exec(r.Context(), `UPDATE rh.folhas_pagamento SET estado='cancelada' WHERE id=$1 AND tenant_id=$2`, id, user.TenantID); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		if err := tx.Commit(r.Context()); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusNoContent)
		return
	}

	if estado != "paga" {
		jsonErr(w, "Apenas folhas 'aberta', 'processada' ou 'paga' podem ser canceladas", http.StatusConflict)
		return
	}

	// Estornar movimento de tesouraria
	if err := h.estornarMovimentoTesourariaFolha(r.Context(), tx, user.TenantID, folhaID); err != nil {
		jsonErr(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Anular lançamento contabilístico
	if journalEntryID != nil {
		if _, err := tx.Exec(r.Context(), `
			UPDATE contabilidade.journal_entries SET status='anulado', updated_at=NOW()
			 WHERE id=$1 AND tenant_id=$2`, *journalEntryID, user.TenantID); err != nil {
			jsonErr(w, "Erro ao anular lançamento contabilístico", http.StatusInternalServerError)
			return
		}
	}

	// Voltar recibos para pendente
	if _, err := tx.Exec(r.Context(), `UPDATE rh.recibos_vencimento SET estado='pendente' WHERE folha_id=$1 AND tenant_id=$2`, id, user.TenantID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	// Cancelar folha
	if _, err := tx.Exec(r.Context(), `
		UPDATE rh.folhas_pagamento
		   SET estado='cancelada', journal_entry_id=NULL, movement_id=NULL,
		       bank_account_id=NULL, cash_register_id=NULL
		 WHERE id=$1 AND tenant_id=$2`, id, user.TenantID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true, "msg": "Folha cancelada. Movimento de tesouraria e lançamento contabilístico foram estornados."}, http.StatusOK)
}

// ── Recibos de Vencimento ────────────────────────────────────────────────────

func (h *Handler) ListarRecibosVencimentoFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	rows, err := h.db.Query(r.Context(), `
		SELECT rv.id, rv.folha_id, fp.ano, fp.mes, fp.estado, rv.salario_base, rv.total_proventos, rv.total_descontos, rv.salario_liquido, rv.estado, rv.created_at
		  FROM rh.recibos_vencimento rv
		  JOIN rh.folhas_pagamento fp ON fp.id = rv.folha_id
		 WHERE rv.funcionario_id=$1 AND rv.tenant_id=$2
		 ORDER BY fp.ano DESC, fp.mes DESC`, funcionarioID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID             int64     `json:"id"`
		FolhaID        int64     `json:"folha_id"`
		Ano            int       `json:"ano"`
		Mes            int       `json:"mes"`
		FolhaEstado    string    `json:"folha_estado"`
		SalarioBase    *float64  `json:"salario_base"`
		TotalProventos *float64  `json:"total_proventos"`
		TotalDescontos *float64  `json:"total_descontos"`
		SalarioLiquido *float64  `json:"salario_liquido"`
		Estado         string    `json:"estado"`
		CreatedAt      time.Time `json:"created_at"`
	}
	podeVerSalarios := h.PodeVerSalarios(r)
	data := []Row{}
	for rows.Next() {
		var rv Row
		var salarioBase, totalProventos, totalDescontos, salarioLiquido float64
		if rows.Scan(&rv.ID, &rv.FolhaID, &rv.Ano, &rv.Mes, &rv.FolhaEstado, &salarioBase, &totalProventos, &totalDescontos, &salarioLiquido, &rv.Estado, &rv.CreatedAt) == nil {
			if podeVerSalarios {
				rv.SalarioBase = &salarioBase
				rv.TotalProventos = &totalProventos
				rv.TotalDescontos = &totalDescontos
				rv.SalarioLiquido = &salarioLiquido
			}
			data = append(data, rv)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) ObterReciboVencimento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var rv struct {
		ID                int64     `json:"id"`
		FolhaID           int64     `json:"folha_id"`
		Ano               int       `json:"ano"`
		Mes               int       `json:"mes"`
		FuncionarioID     int64     `json:"funcionario_id"`
		NomeCompleto      string    `json:"nome_completo"`
		NumeroFuncionario *string   `json:"numero_funcionario"`
		SalarioBase       *float64  `json:"salario_base"`
		TotalProventos    *float64  `json:"total_proventos"`
		TotalDescontos    *float64  `json:"total_descontos"`
		SalarioLiquido    *float64  `json:"salario_liquido"`
		Estado            string    `json:"estado"`
		CreatedAt         time.Time `json:"created_at"`
	}
	var salarioBase, totalProventos, totalDescontos, salarioLiquido float64
	if err := h.db.QueryRow(r.Context(), `
		SELECT rv.id, rv.folha_id, fp.ano, fp.mes, rv.funcionario_id, fu.nome_completo, fu.numero_funcionario,
		       rv.salario_base, rv.total_proventos, rv.total_descontos, rv.salario_liquido, rv.estado, rv.created_at
		  FROM rh.recibos_vencimento rv
		  JOIN rh.folhas_pagamento fp ON fp.id = rv.folha_id
		  JOIN rh.funcionarios fu ON fu.id = rv.funcionario_id
		 WHERE rv.id=$1 AND rv.tenant_id=$2`, id, user.TenantID).Scan(
		&rv.ID, &rv.FolhaID, &rv.Ano, &rv.Mes, &rv.FuncionarioID, &rv.NomeCompleto, &rv.NumeroFuncionario,
		&salarioBase, &totalProventos, &totalDescontos, &salarioLiquido, &rv.Estado, &rv.CreatedAt); err != nil {
		jsonErr(w, "Recibo de vencimento não encontrado", http.StatusNotFound)
		return
	}

	podeVerSalarios := h.PodeVerSalarios(r)
	if podeVerSalarios {
		rv.SalarioBase = &salarioBase
		rv.TotalProventos = &totalProventos
		rv.TotalDescontos = &totalDescontos
		rv.SalarioLiquido = &salarioLiquido
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT id, componente_id, nome, tipo, valor FROM rh.recibo_vencimento_itens WHERE recibo_id=$1 ORDER BY tipo, nome`, id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type ItemRow struct {
		ID           int64    `json:"id"`
		ComponenteID *int64   `json:"componente_id"`
		Nome         string   `json:"nome"`
		Tipo         string   `json:"tipo"`
		Valor        *float64 `json:"valor"`
	}
	itens := []ItemRow{}
	for rows.Next() {
		var it ItemRow
		var valor float64
		if rows.Scan(&it.ID, &it.ComponenteID, &it.Nome, &it.Tipo, &valor) == nil {
			if podeVerSalarios {
				it.Valor = &valor
			}
			itens = append(itens, it)
		}
	}

	jsonOK(w, map[string]any{"recibo": rv, "itens": itens, "pode_ver_salarios": podeVerSalarios}, http.StatusOK)
}
