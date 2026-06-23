<?php

    $rel = $app->nexora->call('GET', '/api/rh/relatorios')['body'] ?? [];

    $totalFuncionarios      = (int) ($rel['total_funcionarios'] ?? 0);
    $porEstado              = $rel['por_estado'] ?? [];
    $porUnidade             = $rel['por_unidade'] ?? [];
    $porCargo               = $rel['por_cargo'] ?? [];
    $massaSalarial          = $rel['massa_salarial'] ?? [];
    $absentismo             = $rel['absentismo'] ?? [];
    $processosDisciplinares = $rel['processos_disciplinares'] ?? [];
    $avaliacoes             = $rel['avaliacoes'] ?? [];
    $formacoes              = $rel['formacoes'] ?? [];

    // RNF02 — confidencialidade salarial: valores são devolvidos como null pelo
    // backend quando o utilizador não tem permissão (recursos-humanos, gerir).
    $podeVerSalarios = $app->session->can('recursos-humanos', 'processar_salarios');
    function rhValorSalarial(?float $valor, bool $podeVer): string
    {
        if (!$podeVer) {
            return '<span class="adm-text-muted">Confidencial</span>';
        }
        return $valor !== null ? number_format($valor, 2, ',', '.') : '—';
    }

    $mesesLabels = [
        1 => 'Janeiro', 2 => 'Fevereiro', 3 => 'Março', 4 => 'Abril', 5 => 'Maio', 6 => 'Junho',
        7 => 'Julho', 8 => 'Agosto', 9 => 'Setembro', 10 => 'Outubro', 11 => 'Novembro', 12 => 'Dezembro',
    ];

    $badgeColors = [
        'adm-badge--green'  => 'var(--adm-green)',
        'adm-badge--yellow' => 'var(--adm-yellow)',
        'adm-badge--blue'   => 'var(--adm-blue)',
        'adm-badge--red'    => 'var(--adm-red)',
        'adm-badge--gray'   => 'var(--adm-gray-400)',
    ];

    $estadoBadges = [
        'ativo'     => ['adm-badge--green',  'Ativo'],
        'suspenso'  => ['adm-badge--yellow', 'Suspenso'],
        'licenca'   => ['adm-badge--blue',   'Licença'],
        'desligado' => ['adm-badge--gray',   'Desligado'],
    ];

    $ausenciaTipoLabels = [
        'ferias'              => 'Férias',
        'doenca'              => 'Doença',
        'licenca_maternidade' => 'Licença de Maternidade',
        'licenca_paternidade' => 'Licença de Paternidade',
        'luto'                => 'Luto',
        'injustificada'       => 'Injustificada',
        'outro'               => 'Outro',
    ];

    $processoDisciplinarEstadoBadges = [
        'aberto'     => ['adm-badge--yellow', 'Aberto'],
        'em_analise' => ['adm-badge--blue',   'Em Análise'],
        'decidido'   => ['adm-badge--green',  'Decidido'],
        'arquivado'  => ['adm-badge--gray',   'Arquivado'],
    ];

    $formacaoEstadoBadges = [
        'planeada'  => ['adm-badge--gray',  'Planeada'],
        'em_curso'  => ['adm-badge--blue',  'Em Curso'],
        'concluida' => ['adm-badge--green', 'Concluída'],
        'cancelada' => ['adm-badge--red',   'Cancelada'],
    ];

    $folhaPagamentoEstadoBadges = [
        'aberta'     => ['adm-badge--gray',   'Aberta'],
        'processada' => ['adm-badge--blue',   'Processada'],
        'paga'       => ['adm-badge--green',  'Paga'],
        'cancelada'  => ['adm-badge--red',    'Cancelada'],
    ];

    $totalAtivos    = 0;
    $totalPorEstado = 0;
    foreach ($porEstado as $pe) {
        $totalPorEstado += (int) $pe['total'];
        if ($pe['estado'] === 'ativo') {
            $totalAtivos = (int) $pe['total'];
        }
    }
    $totalPorEstado = $totalPorEstado ?: 1;

    $ultimaFolha          = $massaSalarial ? $massaSalarial[count($massaSalarial) - 1] : null;
    $massaSalarialLiquida = ($ultimaFolha && $ultimaFolha['total_liquido'] !== null) ? (float) $ultimaFolha['total_liquido'] : null;

    $maxAbsentismoDias = 1;
    foreach ($absentismo as $ab) {
        $maxAbsentismoDias = max($maxAbsentismoDias, (float) $ab['dias']);
    }

    $totalProcessosDisciplinares = array_sum($processosDisciplinares);
    $totalFormacoes              = array_sum($formacoes);

    $pageTitle  = 'Relatórios de RH';
    $activePage = 'rh_relatorios';
    $breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Relatórios', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Relatórios de RH</h1>
</div>

<!-- KPIs -->
<div class="kpi-chips">
    <div class="kpi-chip">
        <div class="kpi-chip-val"><?php echo $totalFuncionarios ?></div>
        <div class="kpi-chip-label">Total de Funcionários</div>
    </div>
    <div class="kpi-chip">
        <div class="kpi-chip-val"><?php echo $totalAtivos ?></div>
        <div class="kpi-chip-label">Funcionários Ativos</div>
    </div>
    <div class="kpi-chip">
        <div class="kpi-chip-val"><?php echo rhValorSalarial($massaSalarialLiquida, $podeVerSalarios) ?></div>
        <div class="kpi-chip-label">Massa Salarial Líquida</div>
        <?php if ($ultimaFolha): ?>
        <div class="kpi-chip-sub"><?php echo ($mesesLabels[$ultimaFolha['mes']] ?? (string) $ultimaFolha['mes']) . ' de ' . (int) $ultimaFolha['ano'] ?></div>
        <?php endif; ?>
    </div>
    <div class="kpi-chip">
        <div class="kpi-chip-val"><?php echo (int) ($processosDisciplinares['aberto'] ?? 0) ?></div>
        <div class="kpi-chip-label">Processos Disciplinares Abertos</div>
        <?php if (($processosDisciplinares['aberto'] ?? 0) > 0): ?>
        <div class="kpi-chip-sub" style="color:var(--adm-yellow)">requerem atenção</div>
        <?php endif; ?>
    </div>
</div>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--adm-sp-6);margin-bottom:var(--adm-sp-6)">

    <!-- Funcionários por Estado -->
    <div class="adm-section">
        <div class="adm-section-header"><h2 class="adm-section-title">Funcionários por Estado</h2></div>
        <?php if ($porEstado): ?>
            <?php foreach ($porEstado as $pe):
                $badge = $estadoBadges[$pe['estado']] ?? ['adm-badge--gray', $pe['estado']];
                $n     = (int) $pe['total'];
                $pct   = round($n / $totalPorEstado * 100);
            ?>
            <div class="funnel-row">
                <span class="funnel-label"><?php echo $badge[1] ?></span>
                <div class="funnel-bar-wrap">
                    <div class="funnel-bar" style="width:<?php echo max($pct, 2) ?>%;background:<?php echo $badgeColors[$badge[0]] ?? 'var(--adm-green)' ?>">
                        <?php echo $n > 0 ? $n : '' ?>
                    </div>
                </div>
                <span class="funnel-count"><?php echo $n ?></span>
                <span class="funnel-pct"><?php echo $pct ?>%</span>
            </div>
            <?php endforeach; ?>
        <?php else: ?>
        <p class="adm-text-muted" style="text-align:center;padding:var(--adm-sp-4) 0">Sem dados ainda.</p>
        <?php endif; ?>
    </div>

    <!-- Funcionários por Unidade -->
    <div class="adm-section">
        <div class="adm-section-header"><h2 class="adm-section-title">Funcionários por Unidade</h2></div>
        <?php if ($porUnidade): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr><th>Unidade</th><th>Nº Funcionários</th></tr></thead>
                <tbody>
                <?php foreach ($porUnidade as $u): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($u['nome']) ?></td>
                    <td class="adm-text-muted"><?php echo (int) $u['total'] ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty"><p class="adm-empty-title">Sem dados</p></div>
        <?php endif; ?>
    </div>

</div>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--adm-sp-6);margin-bottom:var(--adm-sp-6)">

    <!-- Funcionários por Cargo -->
    <div class="adm-section">
        <div class="adm-section-header"><h2 class="adm-section-title">Funcionários por Cargo</h2></div>
        <?php if ($porCargo): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr><th>Cargo</th><th>Nº Funcionários</th></tr></thead>
                <tbody>
                <?php foreach ($porCargo as $c): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($c['nome']) ?></td>
                    <td class="adm-text-muted"><?php echo (int) $c['total'] ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty"><p class="adm-empty-title">Sem dados</p></div>
        <?php endif; ?>
    </div>

    <!-- Massa Salarial — últimos 12 meses -->
    <div class="adm-section">
        <div class="adm-section-header"><h2 class="adm-section-title">Massa Salarial — Últimos 12 Meses</h2></div>
        <?php if ($massaSalarial): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr><th>Período</th><th>Proventos</th><th>Descontos</th><th>Líquido</th><th>Estado</th></tr></thead>
                <tbody>
                <?php foreach ($massaSalarial as $f):
                    $fBadge = $folhaPagamentoEstadoBadges[$f['estado']] ?? ['adm-badge--gray', $f['estado']];
                ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($mesesLabels[$f['mes']] ?? (string) $f['mes']) ?> de <?php echo (int) $f['ano'] ?></td>
                    <td class="adm-text-muted"><?php echo rhValorSalarial($f['total_proventos'] !== null ? (float) $f['total_proventos'] : null, $podeVerSalarios) ?></td>
                    <td class="adm-text-muted"><?php echo rhValorSalarial($f['total_descontos'] !== null ? (float) $f['total_descontos'] : null, $podeVerSalarios) ?></td>
                    <td class="adm-fw-600"><?php echo rhValorSalarial($f['total_liquido'] !== null ? (float) $f['total_liquido'] : null, $podeVerSalarios) ?></td>
                    <td><span class="adm-badge <?php echo $fBadge[0] ?>"><?php echo $fBadge[1] ?></span></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty"><p class="adm-empty-title">Sem folhas de pagamento processadas</p></div>
        <?php endif; ?>
    </div>

</div>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--adm-sp-6);margin-bottom:var(--adm-sp-6)">

    <!-- Absentismo por Tipo -->
    <div class="adm-section">
        <div class="adm-section-header"><h2 class="adm-section-title">Absentismo por Tipo</h2></div>
        <?php if ($absentismo): ?>
            <?php foreach ($absentismo as $ab):
                $label = $ausenciaTipoLabels[$ab['tipo']] ?? $ab['tipo'];
                $dias  = (float) $ab['dias'];
                $pct   = round($dias / $maxAbsentismoDias * 100);
            ?>
            <div class="funnel-row">
                <span class="funnel-label"><?php echo htmlspecialchars($label) ?></span>
                <div class="funnel-bar-wrap">
                    <div class="funnel-bar" style="width:<?php echo max($pct, 2) ?>%;background:var(--adm-yellow)">
                        <?php echo $dias > 0 ? number_format($dias, 1, ',', '.') : '' ?>
                    </div>
                </div>
                <span class="funnel-count"><?php echo (int) $ab['total'] ?></span>
                <span class="funnel-pct"><?php echo number_format($dias, 1, ',', '.') ?>d</span>
            </div>
            <?php endforeach; ?>
        <?php else: ?>
        <p class="adm-text-muted" style="text-align:center;padding:var(--adm-sp-4) 0">Sem ausências registadas.</p>
        <?php endif; ?>
    </div>

    <!-- Avaliações por Período -->
    <div class="adm-section">
        <div class="adm-section-header"><h2 class="adm-section-title">Avaliações por Período</h2></div>
        <?php if ($avaliacoes): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr><th>Período</th><th>Nº Avaliações</th><th>Pontuação Média</th></tr></thead>
                <tbody>
                <?php foreach ($avaliacoes as $av): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($av['periodo']) ?></td>
                    <td class="adm-text-muted"><?php echo (int) $av['total'] ?></td>
                    <td class="adm-fw-600"><?php echo number_format((float) $av['media_pontuacao'], 2, ',', '.') ?> / 20</td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Sem avaliações ainda</p>
            <p class="adm-empty-sub adm-text-xs">Os resultados aparecem aqui após a criação de períodos de avaliação.</p>
        </div>
        <?php endif; ?>
    </div>

</div>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--adm-sp-6)">

    <!-- Processos Disciplinares -->
    <div class="adm-section">
        <div class="adm-section-header"><h2 class="adm-section-title">Processos Disciplinares por Estado</h2></div>
        <?php if ($totalProcessosDisciplinares > 0): ?>
            <?php foreach ($processoDisciplinarEstadoBadges as $key => $badge):
                $n   = (int) ($processosDisciplinares[$key] ?? 0);
                $pct = round($n / $totalProcessosDisciplinares * 100);
            ?>
            <div class="funnel-row">
                <span class="funnel-label"><?php echo $badge[1] ?></span>
                <div class="funnel-bar-wrap">
                    <div class="funnel-bar" style="width:<?php echo max($pct, 2) ?>%;background:<?php echo $badgeColors[$badge[0]] ?? 'var(--adm-green)' ?>">
                        <?php echo $n > 0 ? $n : '' ?>
                    </div>
                </div>
                <span class="funnel-count"><?php echo $n ?></span>
                <span class="funnel-pct"><?php echo $pct ?>%</span>
            </div>
            <?php endforeach; ?>
        <?php else: ?>
        <p class="adm-text-muted" style="text-align:center;padding:var(--adm-sp-4) 0">Sem processos disciplinares registados.</p>
        <?php endif; ?>
    </div>

    <!-- Formações -->
    <div class="adm-section">
        <div class="adm-section-header"><h2 class="adm-section-title">Formações por Estado</h2></div>
        <?php if ($totalFormacoes > 0): ?>
            <?php foreach ($formacaoEstadoBadges as $key => $badge):
                $n   = (int) ($formacoes[$key] ?? 0);
                $pct = round($n / $totalFormacoes * 100);
            ?>
            <div class="funnel-row">
                <span class="funnel-label"><?php echo $badge[1] ?></span>
                <div class="funnel-bar-wrap">
                    <div class="funnel-bar" style="width:<?php echo max($pct, 2) ?>%;background:<?php echo $badgeColors[$badge[0]] ?? 'var(--adm-green)' ?>">
                        <?php echo $n > 0 ? $n : '' ?>
                    </div>
                </div>
                <span class="funnel-count"><?php echo $n ?></span>
                <span class="funnel-pct"><?php echo $pct ?>%</span>
            </div>
            <?php endforeach; ?>
        <?php else: ?>
        <p class="adm-text-muted" style="text-align:center;padding:var(--adm-sp-4) 0">Sem formações registadas.</p>
        <?php endif; ?>
    </div>

</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
