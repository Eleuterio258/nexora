<?php

    // ── Funil por estado + KPIs (dashboard) ─────────────────────────
    $dash = $app->nexora->call('GET', '/api/recrutamento/dashboard')['body'] ?? [];

    $funnelData = array_fill_keys(['recebida', 'em_analise', 'entrevista', 'aprovada', 'rejeitada'], 0);
    foreach ($dash['funil'] ?? [] as $k => $n) {
    if (isset($funnelData[$k])) {
        $funnelData[$k] = (int) $n;
    }

    }
    $totalCandid = array_sum($funnelData);
    $maxFunnel   = $totalCandid ?: 1;

    $taxaAprovacao = $dash['taxa_aprovacao'] ?? 0;

    $taxaEntrevista = $totalCandid > 0
    ? round(($funnelData['entrevista'] + $funnelData['aprovada']) / $totalCandid * 100, 1)
    : 0;

    // ── Carregar candidaturas (até 1000, para os agregados abaixo) ──
    $hoje            = strtotime('today');
    $allCandidaturas = [];
    $page            = 1;
    do {
    $resp            = $app->nexora->call('GET', '/api/recrutamento/candidaturas', null, ['limit' => 100, 'page' => $page]);
    $data            = $resp['body']['data'] ?? [];
    $total           = $resp['body']['meta']['total'] ?? 0;
    $allCandidaturas = array_merge($allCandidaturas, $data);
    $page++;
    } while ($data && count($allCandidaturas) < $total && count($allCandidaturas) < 1000);

    // Tempo médio no processo (estimativa via created_at)
    $diasSomados  = 0;
    $diasContados = 0;
    foreach ($allCandidaturas as $c) {
    if (in_array($c['estado'], ['em_analise', 'entrevista', 'aprovada'], true)) {
        $diasSomados += (int) (($hoje - strtotime(date('Y-m-d', strtotime($c['created_at'])))) / 86400);
        $diasContados++;
    }
    }
    $avgDias = $diasContados > 0 ? $diasSomados / $diasContados : 0;

    // ── Vagas ranking ────────────────────────────────────────────────
    $vagasResp = $app->nexora->call('GET', '/api/recrutamento/vagas', null, ['limit' => 100]);
    $vagasList = $vagasResp['body']['data'] ?? [];

    $porVaga = [];
    foreach ($allCandidaturas as $c) {
    $vid = $c['vaga_id'];
    if ($vid === null) {
        continue;
    }

    $porVaga[$vid]['aprovadas']  = ($porVaga[$vid]['aprovadas'] ?? 0) + ($c['estado'] === 'aprovada' ? 1 : 0);
    $porVaga[$vid]['rejeitadas'] = ($porVaga[$vid]['rejeitadas'] ?? 0) + ($c['estado'] === 'rejeitada' ? 1 : 0);
    $porVaga[$vid]['pendentes']  = ($porVaga[$vid]['pendentes'] ?? 0) + ($c['estado'] === 'recebida' ? 1 : 0);
    if (($c['score'] ?? 0) > 0) {
        $porVaga[$vid]['score_sum'] = ($porVaga[$vid]['score_sum'] ?? 0) + $c['score'];
        $porVaga[$vid]['score_n']   = ($porVaga[$vid]['score_n'] ?? 0) + 1;
    }
    }

    $vagasRank = array_map(function ($v) use ($porVaga) {
    $agg = $porVaga[$v['id']] ?? [];
    return [
        'titulo'     => $v['titulo'],
        'area'       => $v['area'],
        'total'      => (int) ($v['total_candidaturas'] ?? 0),
        'aprovadas'  => $agg['aprovadas'] ?? 0,
        'rejeitadas' => $agg['rejeitadas'] ?? 0,
        'pendentes'  => $agg['pendentes'] ?? 0,
    ];
    }, $vagasList);
    usort($vagasRank, fn($a, $b) => $b['total'] <=> $a['total']);
    $vagasRank = array_slice($vagasRank, 0, 10);

    // ── Candidaturas por dia (últimos 30 dias) ──────────────────────
    $sparkDays = 30;
    $cutoff    = strtotime('-' . ($sparkDays - 1) . ' days', $hoje);
    $sparkMap  = [];
    foreach ($allCandidaturas as $c) {
    $dia = date('Y-m-d', strtotime($c['created_at']));
    if (strtotime($dia) >= $cutoff) {
        $sparkMap[$dia] = ($sparkMap[$dia] ?? 0) + 1;
    }
    }
    $sparkData = [];
    for ($i = $sparkDays - 1; $i >= 0; $i--) {
    $d           = date('Y-m-d', strtotime("-{$i} days"));
    $sparkData[] = (int) ($sparkMap[$d] ?? 0);
    }
    $sparkMax = max(max($sparkData), 1);

    // ── Score médio por vaga ─────────────────────────────────────────
    $vagaTitulos = array_column($vagasList, 'titulo', 'id');
    $scoreVagas  = [];
    foreach ($porVaga as $vid => $agg) {
    if (empty($agg['score_n'])) {
        continue;
    }

    $scoreVagas[] = [
        'titulo'    => $vagaTitulos[$vid] ?? '—',
        'avg_score' => round($agg['score_sum'] / $agg['score_n'], 1),
        'total'     => $agg['score_n'],
    ];
    }
    usort($scoreVagas, fn($a, $b) => $b['avg_score'] <=> $a['avg_score']);
    $scoreVagas = array_slice($scoreVagas, 0, 5);

    $pageTitle  = 'Relatórios';
    $activePage = 'relatorios';
    $breadcrumb = [['Admin', '/nexora/'], ['Relatórios', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Relatórios de Recrutamento</h1>
</div>

<!-- KPIs -->
<div class="kpi-chips">
    <div class="kpi-chip">
        <div class="kpi-chip-val"><?php echo $totalCandid ?></div>
        <div class="kpi-chip-label">Total Candidatos</div>
    </div>
    <div class="kpi-chip">
        <div class="kpi-chip-val"><?php echo $taxaAprovacao ?>%</div>
        <div class="kpi-chip-label">Taxa de Aprovação</div>
        <div class="kpi-chip-sub"><?php echo $funnelData['aprovada'] ?> aprovados</div>
    </div>
    <div class="kpi-chip">
        <div class="kpi-chip-val"><?php echo $taxaEntrevista ?>%</div>
        <div class="kpi-chip-label">Taxa para Entrevista</div>
        <div class="kpi-chip-sub"><?php echo $funnelData['entrevista'] + $funnelData['aprovada'] ?> convocados</div>
    </div>
    <div class="kpi-chip">
        <div class="kpi-chip-val"><?php echo round($avgDias, 0) ?>d</div>
        <div class="kpi-chip-label">Tempo Médio no Processo</div>
        <div class="kpi-chip-sub">desde candidatura</div>
    </div>
    <div class="kpi-chip">
        <div class="kpi-chip-val"><?php echo $funnelData['recebida'] ?></div>
        <div class="kpi-chip-label">Pendentes de Triagem</div>
        <?php if ($funnelData['recebida'] > 0): ?>
        <div class="kpi-chip-sub" style="color:var(--adm-yellow)">requerem atenção</div>
        <?php endif; ?>
    </div>
</div>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--adm-sp-6);margin-bottom:var(--adm-sp-6)">

    <!-- Funil de Recrutamento -->
    <div class="adm-section">
        <div class="adm-section-header"><h2 class="adm-section-title">Funil de Recrutamento</h2></div>
            <?php
                $funnelLabels = ['recebida' => 'Recebida', 'em_analise' => 'Em Análise', 'entrevista' => 'Entrevista', 'aprovada' => 'Aprovada', 'rejeitada' => 'Rejeitada'];
                foreach ($funnelLabels as $key => $label):
                    $n    = $funnelData[$key];
                    $pct  = $totalCandid > 0 ? round($n / $totalCandid * 100) : 0;
                    $barW = $totalCandid > 0 ? round($n / $maxFunnel * 100) : 0;
            ?>
            <div class="funnel-row">
                <span class="funnel-label"><?php echo $label ?></span>
                <div class="funnel-bar-wrap">
                    <div class="funnel-bar" style="width:<?php echo max($barW,2) ?>%">
                        <?php echo $n > 0 ? $n : '' ?>
                    </div>
                </div>
                <span class="funnel-count"><?php echo $n ?></span>
                <span class="funnel-pct"><?php echo $pct ?>%</span>
            </div>
            <?php endforeach; ?>

            <?php if ($totalCandid === 0): ?>
            <p class="adm-text-muted" style="text-align:center;padding:var(--adm-sp-4) 0">Sem dados ainda.</p>
            <?php endif; ?>
    </div>

    <!-- Actividade — últimos 30 dias -->
    <div class="adm-section">
        <div class="adm-section-header">
            <h2 class="adm-section-title">Candidaturas — últimos 30 dias</h2>
        </div>
            <!-- Sparkline SVG -->
            <?php
                $w      = 340;
                $h      = 120;
                $pad    = 10;
                $n      = count($sparkData);
                $stepX  = ($w - $pad * 2) / max($n - 1, 1);
                $points = [];
                foreach ($sparkData as $i => $v) {
                    $x        = $pad + $i * $stepX;
                    $y        = $h - $pad - ($v / $sparkMax) * ($h - $pad * 2);
                    $points[] = "$x,$y";
                }
                $polyline = implode(' ', $points);
                // Fill polygon
                $first    = $points[0];
                $last     = $points[count($points) - 1];
                [$lx]     = explode(',', $last);
                [$fx]     = explode(',', $first);
                $fillPoly = $polyline . " $lx," . ($h - $pad) . " $fx," . ($h - $pad);
            ?>
            <svg viewBox="0 0 <?php echo $w ?> <?php echo $h ?>" style="width:100%;height:120px;display:block">
                <defs>
                    <linearGradient id="sg" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%"   stop-color="#10b981" stop-opacity=".25"/>
                        <stop offset="100%" stop-color="#10b981" stop-opacity="0"/>
                    </linearGradient>
                </defs>
                <polygon points="<?php echo htmlspecialchars($fillPoly) ?>" fill="url(#sg)"/>
                <polyline points="<?php echo htmlspecialchars($polyline) ?>" fill="none" stroke="#10b981" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>
            </svg>
            <div style="display:flex;justify-content:space-between;margin-top:var(--adm-sp-2)">
                <span class="adm-text-xs adm-text-muted"><?php echo date('d/m', strtotime('-29 days')) ?></span>
                <span class="adm-text-xs adm-text-muted">Hoje</span>
            </div>
            <div style="margin-top:var(--adm-sp-4);padding-top:var(--adm-sp-4);border-top:1px solid var(--adm-gray-100)">
                <span class="adm-text-sm adm-fw-700"><?php echo array_sum($sparkData) ?></span>
                <span class="adm-text-sm adm-text-muted"> candidaturas nos últimos 30 dias</span>
            </div>
    </div>

</div>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--adm-sp-6)">

    <!-- Vagas com mais candidaturas -->
    <div class="adm-section">
        <div class="adm-section-header"><h2 class="adm-section-title">Vagas por Candidaturas</h2></div>
        <?php if ($vagasRank): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr><th>Vaga</th><th>Total</th><th>Aprovados</th><th>Pendentes</th></tr></thead>
                <tbody>
                <?php foreach ($vagasRank as $v): ?>
                <tr>
                    <td>
                        <div class="adm-fw-600"><?php echo htmlspecialchars($v['titulo']) ?></div>
                        <div class="adm-text-xs adm-text-muted"><?php echo htmlspecialchars($v['area']) ?></div>
                    </td>
                    <td class="adm-fw-600"><?php echo $v['total'] ?></td>
                    <td><?php if ($v['aprovadas'] > 0): ?><span class="adm-badge adm-badge--green"><?php echo $v['aprovadas'] ?></span><?php else: ?><span class="adm-text-muted">0</span><?php endif; ?></td>
                    <td><?php if ($v['pendentes'] > 0): ?><span class="adm-badge adm-badge--yellow"><?php echo $v['pendentes'] ?></span><?php else: ?><span class="adm-text-muted">0</span><?php endif; ?></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty"><p class="adm-empty-title">Sem dados</p></div>
        <?php endif; ?>
    </div>

    <!-- Score médio por vaga -->
    <div class="adm-section">
        <div class="adm-section-header"><h2 class="adm-section-title">Score Médio dos Candidatos</h2></div>
        <?php if ($scoreVagas): ?>
            <?php foreach ($scoreVagas as $sv): ?>
            <div style="display:flex;align-items:center;gap:var(--adm-sp-4);margin-bottom:var(--adm-sp-4)">
                <div style="flex:1;min-width:0">
                    <div class="adm-fw-600 adm-truncate"><?php echo htmlspecialchars($sv['titulo']) ?></div>
                    <div class="adm-text-xs adm-text-muted"><?php echo $sv['total'] ?> candidatos avaliados</div>
                </div>
                <div class="star-rating readonly" style="pointer-events:none">
                    <?php for ($i = 1; $i <= 5; $i++): ?>
                    <span class="star <?php echo $i <= round($sv['avg_score']) ? 'filled' : '' ?>" style="font-size:1rem">★</span>
                    <?php endfor; ?>
                </div>
                <span style="font-weight:700;font-size:.9rem;color:#92400e;min-width:28px;text-align:right"><?php echo $sv['avg_score'] ?></span>
            </div>
            <?php endforeach; ?>
        <?php else: ?>
        <div class="adm-empty">
            <p class="adm-empty-title">Sem avaliações ainda</p>
            <p class="adm-empty-sub adm-text-xs">Avalia candidatos na vista de detalhe.</p>
        </div>
        <?php endif; ?>
    </div>

</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
