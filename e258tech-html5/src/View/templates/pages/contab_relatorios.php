<?php

    $tiposRelatorio = [
        'trial_balance'        => 'Balancete Geral',
        'balance_sheet'        => 'Balanço',
        'income_statement'     => 'Demonstração de Resultados',
        'general_ledger'       => 'Razão Geral',
        'depreciation_summary' => 'Resumo de Amortizações',
        'budget_execution'     => 'Execução Orçamental',
    ];

    $mesesLabels = [
        1 => 'Janeiro', 2 => 'Fevereiro', 3 => 'Março', 4 => 'Abril',
        5 => 'Maio', 6 => 'Junho', 7 => 'Julho', 8 => 'Agosto',
        9 => 'Setembro', 10 => 'Outubro', 11 => 'Novembro', 12 => 'Dezembro',
    ];

    $classeLabels = [
        'ativo' => 'Ativo', 'passivo' => 'Passivo', 'capital' => 'Capital',
        'rendimento' => 'Rendimento', 'gasto' => 'Gasto',
    ];

    $depStatusLabels = [
        'pendente'   => ['Pendente', 'yellow'],
        'processado' => ['Processado', 'green'],
        'cancelado'  => ['Cancelado', 'gray'],
    ];

    $tipo = $app->request->queryEnum('tipo', array_keys($tiposRelatorio), 'trial_balance');

    $anosFiscais = $app->nexora->call('GET', '/api/contabilidade/fiscal-years')['body'] ?? [];
    $periodos    = $app->nexora->call('GET', '/api/contabilidade/fiscal-periods')['body'] ?? [];
    $contas      = $app->nexora->call('GET', '/api/contabilidade/accounts', null, ['aceita_lancamento' => 'true'])['body'] ?? [];

    $fiscalPeriodId = $app->request->queryInt('fiscal_period_id', 0) ?: 0;
    $fiscalYearId   = $app->request->queryInt('fiscal_year_id', 0) ?: 0;
    $chartAccountId = $app->request->queryInt('chart_account_id', 0) ?: 0;
    $dataInicio     = $app->request->queryString('data_inicio');
    $dataFim        = $app->request->queryString('data_fim');
    $data           = $app->request->queryString('data');

    $parametros  = [];
    $reportData  = null;
    $reportError = null;
    $result      = null;

    switch ($tipo) {
        case 'trial_balance':
            if ($fiscalPeriodId > 0) {
                $parametros['fiscal_period_id'] = $fiscalPeriodId;
            } elseif ($dataInicio !== '' && $dataFim !== '') {
                $parametros['data_inicio'] = $dataInicio;
                $parametros['data_fim']    = $dataFim;
            }
            $result = $app->nexora->call('GET', '/api/contabilidade/reports/trial-balance', null, $parametros);
            break;

        case 'balance_sheet':
            if ($data !== '') {
                $parametros['data'] = $data;
            }
            $result = $app->nexora->call('GET', '/api/contabilidade/reports/balance-sheet', null, $parametros);
            break;

        case 'income_statement':
            if ($dataInicio !== '' && $dataFim !== '') {
                $parametros = ['data_inicio' => $dataInicio, 'data_fim' => $dataFim];
                $result     = $app->nexora->call('GET', '/api/contabilidade/reports/income-statement', null, $parametros);
            }
            break;

        case 'general_ledger':
            if ($chartAccountId > 0) {
                $parametros['chart_account_id'] = $chartAccountId;
                if ($fiscalPeriodId > 0) {
                    $parametros['fiscal_period_id'] = $fiscalPeriodId;
                } else {
                    if ($dataInicio !== '') {
                        $parametros['data_inicio'] = $dataInicio;
                    }
                    if ($dataFim !== '') {
                        $parametros['data_fim'] = $dataFim;
                    }
                }
                $result = $app->nexora->call('GET', '/api/contabilidade/reports/general-ledger', null, $parametros);
            }
            break;

        case 'depreciation_summary':
            if ($fiscalPeriodId > 0) {
                $parametros['fiscal_period_id'] = $fiscalPeriodId;
                $result                          = $app->nexora->call('GET', '/api/contabilidade/reports/depreciation-summary', null, $parametros);
            } elseif ($fiscalYearId > 0) {
                $parametros['fiscal_year_id'] = $fiscalYearId;
                $result                       = $app->nexora->call('GET', '/api/contabilidade/reports/depreciation-summary', null, $parametros);
            }
            break;

        case 'budget_execution':
            if ($fiscalYearId > 0) {
                $parametros['fiscal_year_id'] = $fiscalYearId;
                $result                       = $app->nexora->call('GET', '/api/contabilidade/reports/budget-execution', null, $parametros);
            }
            break;
    }

    if ($result !== null) {
        if (($result['status'] ?? 0) === 200) {
            $reportData = $result['body'];
        } else {
            $reportError = $result['body']['erro'] ?? 'Erro ao gerar o relatório.';
        }
    }

    $historico = $app->nexora->call('GET', '/api/contabilidade/reports', null, ['tipo' => $tipo])['body'] ?? [];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Relatórios Contabilísticos';
    $activePage = 'contab_relatorios';
    $breadcrumb = [['Admin', '/nexora/'], ['Contabilidade', ''], ['Relatórios', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Relatórios Contabilísticos</h1>
</div>

<div id="formMsg"></div>

<?php if ($reportError !== null): ?>
<div class="adm-card adm-mb-6" style="border-color:var(--adm-red)">
    <p style="color:var(--adm-red)"><?php echo htmlspecialchars($reportError) ?></p>
</div>
<?php endif; ?>

<div class="adm-card adm-mb-6">
    <div class="adm-form-row">
        <div class="adm-form-group">
            <label class="adm-label" for="rel-tipo">Tipo de Relatório</label>
            <select class="adm-select" id="rel-tipo" onchange="mudarTipo()">
                <?php foreach ($tiposRelatorio as $key => $label): ?>
                <option value="<?php echo $key ?>" <?php echo $tipo === $key ? 'selected' : '' ?>><?php echo $label ?></option>
                <?php endforeach; ?>
            </select>
        </div>

        <?php if (in_array($tipo, ['trial_balance', 'general_ledger', 'depreciation_summary'], true)): ?>
        <div class="adm-form-group">
            <label class="adm-label" for="rel-periodo">Período Fiscal</label>
            <select class="adm-select" id="rel-periodo">
                <option value="0">— Nenhum —</option>
                <?php foreach ($periodos as $p): ?>
                <option value="<?php echo (int) $p['id'] ?>" <?php echo $fiscalPeriodId === (int) $p['id'] ? 'selected' : '' ?>>
                    <?php echo htmlspecialchars(($mesesLabels[(int) $p['mes']] ?? (string) $p['mes']) . '/' . $p['ano']) ?>
                </option>
                <?php endforeach; ?>
            </select>
        </div>
        <?php endif; ?>

        <?php if (in_array($tipo, ['depreciation_summary', 'budget_execution'], true)): ?>
        <div class="adm-form-group">
            <label class="adm-label" for="rel-ano">Ano Fiscal</label>
            <select class="adm-select" id="rel-ano">
                <option value="0">— Nenhum —</option>
                <?php foreach ($anosFiscais as $a): ?>
                <option value="<?php echo (int) $a['id'] ?>" <?php echo $fiscalYearId === (int) $a['id'] ? 'selected' : '' ?>>Ano Fiscal <?php echo (int) $a['ano'] ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <?php endif; ?>

        <?php if (in_array($tipo, ['trial_balance', 'income_statement', 'general_ledger'], true)): ?>
        <div class="adm-form-group">
            <label class="adm-label" for="rel-data-inicio">Data Início<?php echo $tipo === 'income_statement' ? ' *' : '' ?></label>
            <input class="adm-input" type="date" id="rel-data-inicio" value="<?php echo htmlspecialchars($dataInicio) ?>">
        </div>
        <div class="adm-form-group">
            <label class="adm-label" for="rel-data-fim">Data Fim<?php echo $tipo === 'income_statement' ? ' *' : '' ?></label>
            <input class="adm-input" type="date" id="rel-data-fim" value="<?php echo htmlspecialchars($dataFim) ?>">
        </div>
        <?php endif; ?>

        <?php if ($tipo === 'balance_sheet'): ?>
        <div class="adm-form-group">
            <label class="adm-label" for="rel-data">Data</label>
            <input class="adm-input" type="date" id="rel-data" value="<?php echo htmlspecialchars($data ?: date('Y-m-d')) ?>">
        </div>
        <?php endif; ?>

        <?php if ($tipo === 'general_ledger'): ?>
        <div class="adm-form-group">
            <label class="adm-label" for="rel-conta">Conta <span style="color:var(--adm-red)">*</span></label>
            <select class="adm-select" id="rel-conta">
                <option value="">Selecione uma conta</option>
                <?php foreach ($contas as $c): ?>
                <option value="<?php echo (int) $c['id'] ?>" <?php echo $chartAccountId === (int) $c['id'] ? 'selected' : '' ?>><?php echo htmlspecialchars($c['codigo'] . ' - ' . $c['nome']) ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <?php endif; ?>
    </div>
    <div style="display:flex;gap:var(--adm-sp-3)">
        <button class="adm-btn adm-btn-primary" type="button" onclick="gerarRelatorio()">Gerar Relatório</button>
        <?php if ($reportData !== null): ?>
        <button class="adm-btn adm-btn-outline" type="button" onclick="guardarRelatorio()">Guardar Relatório</button>
        <?php endif; ?>
    </div>
</div>

<?php if ($tipo === 'trial_balance' && $reportData !== null): ?>
<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Balancete Geral</h2></div>
    <div class="adm-card-body">
        <?php if ($reportData['contas']): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Código</th><th>Conta</th><th>Classe</th><th>Débito</th><th>Crédito</th><th>Saldo Devedor</th><th>Saldo Credor</th></tr>
                </thead>
                <tbody>
                <?php foreach ($reportData['contas'] as $c): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($c['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($c['nome']) ?></td>
                    <td><?php echo htmlspecialchars($classeLabels[$c['classe']] ?? $c['classe']) ?></td>
                    <td><?php echo number_format((float) $c['total_debito'], 2, ',', '.') ?></td>
                    <td><?php echo number_format((float) $c['total_credito'], 2, ',', '.') ?></td>
                    <td><?php echo number_format((float) $c['saldo_devedor'], 2, ',', '.') ?></td>
                    <td><?php echo number_format((float) $c['saldo_credor'], 2, ',', '.') ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
                <tfoot>
                <tr class="adm-fw-600">
                    <td colspan="3">Totais</td>
                    <td><?php echo number_format((float) $reportData['totais']['total_debito'], 2, ',', '.') ?></td>
                    <td><?php echo number_format((float) $reportData['totais']['total_credito'], 2, ',', '.') ?></td>
                    <td><?php echo number_format((float) $reportData['totais']['saldo_devedor'], 2, ',', '.') ?></td>
                    <td><?php echo number_format((float) $reportData['totais']['saldo_credor'], 2, ',', '.') ?></td>
                </tr>
                </tfoot>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty"><p class="adm-empty-title">Sem movimentos para os critérios selecionados</p></div>
        <?php endif; ?>
    </div>
</div>
<?php endif; ?>

<?php if ($tipo === 'balance_sheet' && $reportData !== null): ?>
<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Balanço em <?php echo date('d/m/Y', strtotime($reportData['data'])) ?></h2></div>
    <div class="adm-card-body">
        <?php foreach (['ativo' => 'Ativo', 'passivo' => 'Passivo', 'capital' => 'Capital Próprio'] as $grupoKey => $grupoLabel): ?>
        <h3 class="adm-mt-6 adm-mb-4"><?php echo $grupoLabel ?></h3>
        <?php if ($reportData[$grupoKey]): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr><th>Código</th><th>Conta</th><th>Saldo</th></tr></thead>
                <tbody>
                <?php foreach ($reportData[$grupoKey] as $c): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($c['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($c['nome']) ?></td>
                    <td><?php echo number_format((float) $c['saldo'], 2, ',', '.') ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty"><p class="adm-empty-title">Sem contas nesta classe</p></div>
        <?php endif; ?>
        <?php endforeach; ?>

        <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:var(--adm-sp-5)" class="adm-mt-6">
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Total Ativo</span>
                <span class="adm-detail-pair-value adm-fw-600"><?php echo number_format((float) $reportData['total_ativo'], 2, ',', '.') ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Total Passivo + Capital</span>
                <span class="adm-detail-pair-value adm-fw-600"><?php echo number_format((float) $reportData['total_passivo_capital'], 2, ',', '.') ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Diferença</span>
                <span class="adm-detail-pair-value adm-fw-600" style="color:<?php echo abs((float) $reportData['diferenca']) < 0.01 ? 'var(--adm-green)' : 'var(--adm-red)' ?>">
                    <?php echo number_format((float) $reportData['diferenca'], 2, ',', '.') ?>
                </span>
            </div>
        </div>
    </div>
</div>
<?php endif; ?>

<?php if ($tipo === 'income_statement' && $reportData !== null): ?>
<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Demonstração de Resultados</h2></div>
    <div class="adm-card-body">
        <?php foreach (['rendimento' => 'Rendimentos', 'gasto' => 'Gastos'] as $grupoKey => $grupoLabel): ?>
        <h3 class="adm-mt-6 adm-mb-4"><?php echo $grupoLabel ?></h3>
        <?php if ($reportData[$grupoKey]): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr><th>Código</th><th>Conta</th><th>Valor</th></tr></thead>
                <tbody>
                <?php foreach ($reportData[$grupoKey] as $c): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($c['codigo']) ?></td>
                    <td><?php echo htmlspecialchars($c['nome']) ?></td>
                    <td><?php echo number_format((float) $c['saldo'], 2, ',', '.') ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty"><p class="adm-empty-title">Sem movimentos nesta classe</p></div>
        <?php endif; ?>
        <?php endforeach; ?>

        <div class="adm-detail-pair adm-mt-6">
            <span class="adm-detail-pair-label"><?php echo (float) $reportData['resultado'] >= 0 ? 'Resultado (Lucro)' : 'Resultado (Prejuízo)' ?></span>
            <span class="adm-detail-pair-value adm-fw-600" style="color:<?php echo (float) $reportData['resultado'] >= 0 ? 'var(--adm-green)' : 'var(--adm-red)' ?>">
                <?php echo number_format((float) $reportData['resultado'], 2, ',', '.') ?>
            </span>
        </div>
    </div>
</div>
<?php endif; ?>

<?php if ($tipo === 'general_ledger' && $reportData !== null): ?>
<div class="adm-card adm-mb-6">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Razão Geral — <?php echo htmlspecialchars($reportData['conta']['codigo'] . ' - ' . $reportData['conta']['nome']) ?></h2>
    </div>
    <div class="adm-card-body">
        <div class="adm-detail-pair adm-mb-6">
            <span class="adm-detail-pair-label">Saldo Inicial</span>
            <span class="adm-detail-pair-value adm-fw-600"><?php echo number_format((float) $reportData['saldo_inicial'], 2, ',', '.') ?></span>
        </div>
        <?php if ($reportData['movimentos']): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr><th>Data</th><th>Número</th><th>Descrição</th><th>Débito</th><th>Crédito</th><th>Saldo</th></tr></thead>
                <tbody>
                <?php foreach ($reportData['movimentos'] as $m): ?>
                <tr>
                    <td><?php echo date('d/m/Y', strtotime($m['entry_date'])) ?></td>
                    <td><?php echo htmlspecialchars($m['numero']) ?></td>
                    <td><?php echo htmlspecialchars($m['descricao']) ?></td>
                    <td><?php echo number_format((float) $m['debit'], 2, ',', '.') ?></td>
                    <td><?php echo number_format((float) $m['credit'], 2, ',', '.') ?></td>
                    <td><?php echo number_format((float) $m['saldo'], 2, ',', '.') ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty"><p class="adm-empty-title">Sem movimentos para os critérios selecionados</p></div>
        <?php endif; ?>
        <div class="adm-detail-pair adm-mt-6">
            <span class="adm-detail-pair-label">Saldo Final</span>
            <span class="adm-detail-pair-value adm-fw-600"><?php echo number_format((float) $reportData['saldo_final'], 2, ',', '.') ?></span>
        </div>
    </div>
</div>
<?php endif; ?>

<?php if ($tipo === 'depreciation_summary' && $reportData !== null): ?>
<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Resumo de Amortizações</h2></div>
    <div class="adm-card-body">
        <?php if (isset($reportData['ativos'])): ?>
        <?php if ($reportData['ativos']): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr><th>Ativo</th><th>Parcela</th><th>Valor</th><th>Estado</th></tr></thead>
                <tbody>
                <?php foreach ($reportData['ativos'] as $a): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($a['codigo'] . ' - ' . $a['nome']) ?></td>
                    <td><?php echo (int) $a['numero_parcela'] ?></td>
                    <td><?php echo number_format((float) $a['valor_amortizacao'], 2, ',', '.') ?></td>
                    <td><span class="adm-badge adm-badge--<?php echo $depStatusLabels[$a['status']][1] ?? 'gray' ?>"><?php echo $depStatusLabels[$a['status']][0] ?? $a['status'] ?></span></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty"><p class="adm-empty-title">Sem amortizações para este período</p></div>
        <?php endif; ?>
        <?php else: ?>
        <?php if ($reportData['periodos']): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr><th>Período</th><th>Total Amortização</th><th>Nº Ativos</th></tr></thead>
                <tbody>
                <?php foreach ($reportData['periodos'] as $p): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars(($mesesLabels[(int) $p['mes']] ?? (string) $p['mes']) . '/' . $p['ano']) ?></td>
                    <td><?php echo number_format((float) $p['total_amortizacao'], 2, ',', '.') ?></td>
                    <td><?php echo (int) $p['num_ativos'] ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty"><p class="adm-empty-title">Sem amortizações para este ano fiscal</p></div>
        <?php endif; ?>
        <?php endif; ?>
        <div class="adm-detail-pair adm-mt-6">
            <span class="adm-detail-pair-label">Total Amortização</span>
            <span class="adm-detail-pair-value adm-fw-600"><?php echo number_format((float) $reportData['total_amortizacao'], 2, ',', '.') ?></span>
        </div>
    </div>
</div>
<?php endif; ?>

<?php if ($tipo === 'budget_execution' && $reportData !== null): ?>
<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Execução Orçamental</h2></div>
    <div class="adm-card-body">
        <?php if ($reportData['contas']): ?>
        <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:var(--adm-sp-5)" class="adm-mb-6">
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Total Orçado</span>
                <span class="adm-detail-pair-value adm-fw-600"><?php echo number_format((float) $reportData['totais']['valor_orcamentado'], 2, ',', '.') ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Total Realizado</span>
                <span class="adm-detail-pair-value adm-fw-600"><?php echo number_format((float) $reportData['totais']['valor_realizado'], 2, ',', '.') ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Variação Total</span>
                <span class="adm-detail-pair-value adm-fw-600" style="color:<?php echo (float) $reportData['totais']['variacao'] >= 0 ? 'var(--adm-green)' : 'var(--adm-red)' ?>">
                    <?php echo number_format((float) $reportData['totais']['variacao'], 2, ',', '.') ?>
                </span>
            </div>
        </div>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr><th>Conta</th><th>Orçado</th><th>Realizado</th><th>Variação</th><th>Variação %</th></tr></thead>
                <tbody>
                <?php foreach ($reportData['contas'] as $c): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($c['codigo'] . ' - ' . $c['nome']) ?></td>
                    <td><?php echo number_format((float) $c['valor_orcamentado'], 2, ',', '.') ?></td>
                    <td><?php echo number_format((float) $c['valor_realizado'], 2, ',', '.') ?></td>
                    <td style="color:<?php echo (float) $c['variacao'] >= 0 ? 'var(--adm-green)' : 'var(--adm-red)' ?>">
                        <?php echo number_format((float) $c['variacao'], 2, ',', '.') ?>
                    </td>
                    <td style="color:<?php echo (float) $c['variacao'] >= 0 ? 'var(--adm-green)' : 'var(--adm-red)' ?>">
                        <?php echo $c['variacao_pct'] !== null ? number_format((float) $c['variacao_pct'], 1, ',', '.') . '%' : '—' ?>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty"><p class="adm-empty-title">Sem orçamentos para este ano fiscal</p></div>
        <?php endif; ?>
    </div>
</div>
<?php endif; ?>

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Histórico de Relatórios Guardados</h2></div>
    <div class="adm-card-body">
        <?php if ($historico): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr><th>Tipo</th><th>Gerado em</th></tr></thead>
                <tbody>
                <?php foreach ($historico as $h): ?>
                <tr>
                    <td><?php echo htmlspecialchars($tiposRelatorio[$h['tipo']] ?? $h['tipo']) ?></td>
                    <td><?php echo date('d/m/Y H:i', strtotime($h['gerado_em'])) ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty"><p class="adm-empty-title">Nenhum relatório guardado deste tipo</p></div>
        <?php endif; ?>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';
const PARAMETROS_TIPO = '<?php echo $tipo ?>';
const PARAMETROS_ATUAIS = <?php echo json_encode($parametros) ?>;

function mudarTipo() {
    const tipo = document.getElementById('rel-tipo').value;
    location.href = '?tipo=' + tipo;
}

async function postJSON(url, payload) {
    try {
        const res  = await fetch(url, {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Guardado com sucesso.');
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

function gerarRelatorio() {
    const tipo = document.getElementById('rel-tipo').value;
    const params = new URLSearchParams();
    params.set('tipo', tipo);

    const periodoEl = document.getElementById('rel-periodo');
    const anoEl     = document.getElementById('rel-ano');
    const inicioEl  = document.getElementById('rel-data-inicio');
    const fimEl     = document.getElementById('rel-data-fim');
    const dataEl    = document.getElementById('rel-data');
    const contaEl   = document.getElementById('rel-conta');

    if (tipo === 'general_ledger') {
        if (!contaEl || !contaEl.value) {
            showToast('Selecione uma conta.', 'error');
            return;
        }
        params.set('chart_account_id', contaEl.value);
    }

    if (tipo === 'income_statement') {
        if (!inicioEl.value || !fimEl.value) {
            showToast('Indique o intervalo de datas.', 'error');
            return;
        }
        params.set('data_inicio', inicioEl.value);
        params.set('data_fim', fimEl.value);
    }

    if (tipo === 'trial_balance' || tipo === 'general_ledger') {
        if (periodoEl && periodoEl.value !== '0') {
            params.set('fiscal_period_id', periodoEl.value);
        } else {
            if (inicioEl && inicioEl.value) params.set('data_inicio', inicioEl.value);
            if (fimEl && fimEl.value) params.set('data_fim', fimEl.value);
        }
    }

    if (tipo === 'depreciation_summary') {
        if (periodoEl && periodoEl.value !== '0') {
            params.set('fiscal_period_id', periodoEl.value);
        } else if (anoEl && anoEl.value !== '0') {
            params.set('fiscal_year_id', anoEl.value);
        } else {
            showToast('Selecione o período ou o ano fiscal.', 'error');
            return;
        }
    }

    if (tipo === 'balance_sheet' && dataEl && dataEl.value) {
        params.set('data', dataEl.value);
    }

    if (tipo === 'budget_execution') {
        if (!anoEl || anoEl.value === '0') {
            showToast('Selecione o ano fiscal.', 'error');
            return;
        }
        params.set('fiscal_year_id', anoEl.value);
    }

    location.href = '?' + params.toString();
}

function guardarRelatorio() {
    postJSON('/nexora/api/contab_relatorio_gerar', { tipo: PARAMETROS_TIPO, parametros: PARAMETROS_ATUAIS, csrf: CSRF });
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
