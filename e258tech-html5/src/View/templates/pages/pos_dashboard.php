<?php

// ── Dados do dashboard POS ─────────────────────────────────────────────────
$hoje = date('Y-m-d');
$ontem = date('Y-m-d', strtotime('-1 day'));

$vendasResp = $app->nexora->call('GET', '/api/pos/sales', null, ['data_inicio' => $hoje, 'data_fim' => $hoje]);
$vendas = ($vendasResp['status'] === 200 && is_array($vendasResp['body']) && array_is_list($vendasResp['body'])) ? $vendasResp['body'] : [];

$sessaoResp = $app->nexora->call('GET', '/api/pos/sessoes/atual');
$sessaoAtual = ($sessaoResp['status'] === 200) ? $sessaoResp['body'] : null;

$termResp  = $app->nexora->call('GET', '/api/pos/terminais');
$terminais = ($termResp['status'] === 200 && is_array($termResp['body'])) ? $termResp['body'] : [];
$totalTerminais = count($terminais);

// Calcular KPIs das vendas do dia
$totalVendido  = array_sum(array_column($vendas, 'total'));
$numVendas     = count($vendas);
$ticketMedio   = $numVendas > 0 ? $totalVendido / $numVendas : 0;

// Métodos de pagamento
$metodosCount = [];
foreach ($vendas as $v) {
    $mp = $v['metodo_pagamento'] ?? 'Outro';
    $metodosCount[$mp] = ($metodosCount[$mp] ?? 0) + ($v['total'] ?? 0);
}
arsort($metodosCount);

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Dashboard POS';
$activePage = 'pos_dashboard';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/nexora/pos'], ['Dashboard', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Dashboard POS</h1>
    <div class="adm-page-header-actions">
        <span class="adm-text-sm adm-text-muted">
            <i class="fa-solid fa-calendar"></i>
            <?= date('d/m/Y') ?> — Resultados do dia
        </span>
        <a href="<?= htmlspecialchars($app->routes->path('pos')) ?>" class="adm-btn adm-btn-primary">
            <i class="fa-solid fa-cash-register"></i> Ir para PDV
        </a>
    </div>
</div>

<!-- ── KPI Cards ────────────────────────────────────────────────────────────── -->
<div class="adm-stats-grid" style="margin-bottom:var(--adm-sp-6)">
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--green">
            <i class="fa-solid fa-money-bill-wave" style="font-size:1.1rem"></i>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= number_format($totalVendido, 2, ',', '.') ?> MT</div>
            <div class="adm-stat-label">Total Vendido Hoje</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue">
            <i class="fa-solid fa-receipt" style="font-size:1.1rem"></i>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= $numVendas ?></div>
            <div class="adm-stat-label">Número de Vendas</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--yellow">
            <i class="fa-solid fa-chart-line" style="font-size:1.1rem"></i>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= number_format($ticketMedio, 2, ',', '.') ?> MT</div>
            <div class="adm-stat-label">Ticket Médio</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon <?= $sessaoAtual ? 'adm-stat-icon--green' : 'adm-stat-icon--red' ?>">
            <i class="fa-solid fa-cash-register" style="font-size:1.1rem"></i>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= $sessaoAtual ? 'Aberta' : 'Fechada' ?></div>
            <div class="adm-stat-label">Caixa Actual</div>
        </div>
    </div>
</div>

<!-- ── Linha 2: Métodos de Pagamento + Últimas Vendas ─────────────────────── -->
<div style="display:grid;grid-template-columns:300px 1fr;gap:var(--adm-sp-6);margin-bottom:var(--adm-sp-6)">

    <!-- Métodos de pagamento -->
    <div class="adm-card">
        <div class="adm-card-header">
            <h2 class="adm-card-title">Formas de Pagamento</h2>
        </div>
        <div class="adm-card-body">
            <?php if (empty($metodosCount)): ?>
            <p class="adm-text-sm adm-text-muted">Sem vendas hoje.</p>
            <?php else: $totalMetodos = array_sum($metodosCount); ?>
            <?php foreach ($metodosCount as $metodo => $valor): ?>
            <?php $pct = $totalMetodos > 0 ? round($valor / $totalMetodos * 100) : 0; ?>
            <div style="margin-bottom:var(--adm-sp-4)">
                <div style="display:flex;justify-content:space-between;margin-bottom:var(--adm-sp-1)">
                    <span class="adm-text-sm adm-fw-600"><?= htmlspecialchars($metodo) ?></span>
                    <span class="adm-text-sm adm-text-muted"><?= $pct ?>%</span>
                </div>
                <div style="background:var(--adm-gray-100);border-radius:99px;height:8px">
                    <div style="background:var(--adm-green);border-radius:99px;height:8px;width:<?= $pct ?>%;transition:width .4s"></div>
                </div>
                <div class="adm-text-xs adm-text-muted" style="margin-top:var(--adm-sp-1)">
                    <?= number_format($valor, 2, ',', '.') ?> MT
                </div>
            </div>
            <?php endforeach; ?>
            <?php endif; ?>
        </div>
    </div>

    <!-- Últimas vendas -->
    <div class="adm-card">
        <div class="adm-card-header">
            <h2 class="adm-card-title">Últimas Vendas</h2>
            <div class="adm-card-actions">
                <a href="<?= htmlspecialchars($app->routes->path('pos_vendas')) ?>" class="adm-btn adm-btn-ghost adm-btn-sm">Ver todas</a>
            </div>
        </div>
        <?php if (empty($vendas)): ?>
        <div class="adm-empty"><p class="adm-empty-title">Sem vendas hoje</p></div>
        <?php else: ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Ref.</th>
                        <th>Hora</th>
                        <th>Método</th>
                        <th>Items</th>
                        <th>Total</th>
                        <th>Estado</th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach (array_slice(array_reverse($vendas), 0, 8) as $v):
                    $estado = $v['estado'] ?? 'concluida';
                    $estadoBadge = match($estado) {
                        'concluida'  => ['adm-badge--green', 'Concluída'],
                        'cancelada'  => ['adm-badge--red',   'Cancelada'],
                        'pendente'   => ['adm-badge--yellow','Pendente'],
                        default      => ['adm-badge--gray',  ucfirst($estado)],
                    };
                ?>
                <tr>
                    <td class="adm-fw-600 adm-text-xs"><?= htmlspecialchars($v['referencia'] ?? '#' . $v['id']) ?></td>
                    <td class="adm-text-muted"><?= !empty($v['criada_em']) ? date('H:i', strtotime($v['criada_em'])) : '—' ?></td>
                    <td><?= htmlspecialchars($v['metodo_pagamento'] ?? '—') ?></td>
                    <td class="adm-text-muted"><?= (int)($v['num_itens'] ?? 0) ?></td>
                    <td class="adm-fw-600"><?= number_format((float)($v['total'] ?? 0), 2, ',', '.') ?> MT</td>
                    <td><span class="adm-badge <?= $estadoBadge[0] ?>"><?= $estadoBadge[1] ?></span></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php endif; ?>
    </div>
</div>

<!-- ── Terminais ─────────────────────────────────────────────────────────────── -->
<div class="adm-card">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Terminais</h2>
        <div class="adm-card-actions">
            <a href="<?= htmlspecialchars($app->routes->path('pos_terminais')) ?>" class="adm-btn adm-btn-ghost adm-btn-sm">Gerir terminais</a>
        </div>
    </div>
    <?php if (empty($terminais)): ?>
    <div class="adm-empty"><p class="adm-empty-title">Sem terminais configurados</p></div>
    <?php else: ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead><tr><th>Terminal</th><th>Localização</th><th>Estado</th><th>Ações</th></tr></thead>
            <tbody>
            <?php foreach ($terminais as $t):
                $ativo = !empty($t['activo']);
            ?>
            <tr>
                <td class="adm-fw-600"><?= htmlspecialchars($t['nome'] ?? '—') ?></td>
                <td class="adm-text-muted"><?= htmlspecialchars($t['localizacao'] ?? '—') ?></td>
                <td>
                    <span class="adm-badge <?= $ativo ? 'adm-badge--green' : 'adm-badge--gray' ?>">
                        <?= $ativo ? 'Activo' : 'Inactivo' ?>
                    </span>
                </td>
                <td>
                    <a href="<?= htmlspecialchars($app->routes->path('pos')) ?>" class="adm-btn adm-btn-ghost adm-btn-sm">
                        <i class="fa-solid fa-cash-register"></i> Abrir PDV
                    </a>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php endif; ?>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
