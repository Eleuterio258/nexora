-- Views do modulo de Contabilidade

-- Balancete: debito, credito e saldo por conta
CREATE OR REPLACE VIEW vw_balancete AS
SELECT
    c.id AS conta_id,
    c.tenant_id,
    c.codigo,
    c.nome,
    at.natureza,
    COALESCE(SUM(l.debito),  0) AS total_debito,
    COALESCE(SUM(l.credito), 0) AS total_credito,
    COALESCE(SUM(l.debito - l.credito), 0) AS saldo
FROM chart_of_accounts c
JOIN account_types at ON at.id = c.account_type_id
LEFT JOIN journal_entry_lines l ON l.chart_account_id = c.id
GROUP BY c.id, c.tenant_id, c.codigo, c.nome, at.natureza;

-- Balancete por periodo fiscal
CREATE OR REPLACE VIEW vw_balancete_periodo AS
SELECT
    c.tenant_id,
    je.fiscal_period_id,
    c.id AS conta_id,
    c.codigo,
    c.nome,
    at.natureza,
    COALESCE(SUM(l.debito),  0) AS total_debito,
    COALESCE(SUM(l.credito), 0) AS total_credito,
    COALESCE(SUM(l.debito - l.credito), 0) AS saldo
FROM chart_of_accounts c
JOIN account_types at ON at.id = c.account_type_id
JOIN journal_entry_lines l ON l.chart_account_id = c.id
JOIN journal_entries je ON je.id = l.journal_entry_id
GROUP BY c.tenant_id, je.fiscal_period_id, c.id, c.codigo, c.nome, at.natureza;

-- Demonstracao de Resultados: receitas vs. despesas por periodo
CREATE OR REPLACE VIEW vw_demonstracao_resultados AS
SELECT
    c.tenant_id,
    je.fiscal_period_id,
    at.nome AS tipo_conta,
    at.natureza,
    COALESCE(SUM(l.credito - l.debito), 0) AS resultado
FROM chart_of_accounts c
JOIN account_types at ON at.id = c.account_type_id
JOIN journal_entry_lines l ON l.chart_account_id = c.id
JOIN journal_entries je ON je.id = l.journal_entry_id
WHERE at.natureza IN ('credito')
GROUP BY c.tenant_id, je.fiscal_period_id, at.nome, at.natureza;

-- Razao geral: todos os lancamentos por conta
CREATE OR REPLACE VIEW vw_razao_geral AS
SELECT
    c.tenant_id,
    c.codigo AS conta_codigo,
    c.nome AS conta_nome,
    je.numero AS lancamento_numero,
    je.entry_date,
    je.fiscal_period_id,
    je.origem_tipo,
    je.origem_id,
    l.debito,
    l.credito,
    l.descricao
FROM journal_entry_lines l
JOIN chart_of_accounts c ON c.id = l.chart_account_id
JOIN journal_entries je ON je.id = l.journal_entry_id
ORDER BY c.codigo, je.entry_date;

-- Estado dos activos fixos com valor contabilistico actual
CREATE OR REPLACE VIEW vw_fixed_assets_estado AS
SELECT
    fa.id AS asset_id,
    fa.tenant_id,
    fa.codigo,
    fa.nome,
    fa.data_aquisicao,
    fa.valor_aquisicao,
    fa.valor_residual,
    fa.vida_util_meses,
    fa.metodo_amortizacao,
    fa.estado,
    COALESCE(ds.valor_acumulado, 0) AS amortizacao_acumulada,
    COALESCE(ds.valor_contabilistico, fa.valor_aquisicao) AS valor_contabilistico
FROM fixed_assets fa
LEFT JOIN LATERAL (
    SELECT valor_acumulado, valor_contabilistico
    FROM depreciation_schedules
    WHERE fixed_asset_id = fa.id AND status = 'lancado'
    ORDER BY fiscal_period_id DESC
    LIMIT 1
) ds ON TRUE;

-- Plano de amortizacao por activo
CREATE OR REPLACE VIEW vw_plano_amortizacao AS
SELECT
    fa.tenant_id,
    fa.codigo AS asset_codigo,
    fa.nome AS asset_nome,
    fp.codigo AS periodo,
    fp.data_inicio,
    fp.data_fim,
    ds.valor_amortizacao,
    ds.valor_acumulado,
    ds.valor_contabilistico,
    ds.status
FROM depreciation_schedules ds
JOIN fixed_assets fa ON fa.id = ds.fixed_asset_id
JOIN fiscal_periods fp ON fp.id = ds.fiscal_period_id
ORDER BY fa.codigo, fp.data_inicio;

-- Orcamento vs. realizado por conta e ano fiscal
CREATE OR REPLACE VIEW vw_budget_vs_realizado AS
SELECT
    ba.tenant_id,
    ba.fiscal_year_id,
    c.codigo AS conta_codigo,
    c.nome AS conta_nome,
    ba.valor_orcamentado,
    COALESCE(SUM(l.debito - l.credito), 0) AS valor_realizado,
    ba.valor_orcamentado - COALESCE(SUM(l.debito - l.credito), 0) AS desvio
FROM budget_accounts ba
JOIN chart_of_accounts c ON c.id = ba.chart_account_id
LEFT JOIN journal_entry_lines l ON l.chart_account_id = ba.chart_account_id
LEFT JOIN journal_entries je ON je.id = l.journal_entry_id
LEFT JOIN fiscal_periods fp ON fp.id = je.fiscal_period_id AND fp.fiscal_year_id = ba.fiscal_year_id
GROUP BY ba.tenant_id, ba.fiscal_year_id, c.codigo, c.nome, ba.valor_orcamentado;

-- Verificacoes de encerramento de periodo
CREATE OR REPLACE VIEW vw_period_closing_checks AS
SELECT
    pc.tenant_id,
    pc.fiscal_period_id,
    fp.codigo AS periodo,
    pc.status AS fecho_status,
    pc.verificacoes_ok,
    cc.verificacao,
    cc.status AS check_status,
    cc.detalhe,
    cc.verificado_em
FROM period_closings pc
JOIN fiscal_periods fp ON fp.id = pc.fiscal_period_id
LEFT JOIN closing_checks cc ON cc.period_closing_id = pc.id
ORDER BY pc.fiscal_period_id, cc.verificacao;
