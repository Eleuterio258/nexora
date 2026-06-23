<?php

// ── Filtros ────────────────────────────────────────────────────────────────
$dataInicio = $app->request->queryString('data_inicio', date('Y-m-d', strtotime('-30 days')));
$dataFim    = $app->request->queryString('data_fim',    date('Y-m-d'));
$metodo     = $app->request->queryString('metodo',      '');

$query = ['data_inicio' => $dataInicio, 'data_fim' => $dataFim];
if ($metodo !== '') $query['metodo_pagamento'] = $metodo;

$vendasResp = $app->nexora->call('GET', '/api/pos/sales', null, $query);
$vendas = ($vendasResp['status'] === 200 && is_array($vendasResp['body']) && array_is_list($vendasResp['body']))
    ? $vendasResp['body'] : [];

// ── KPIs ────────────────────────────────────────────────────────────────────
$totalVendas     = count($vendas);
$totalAmount     = array_sum(array_column($vendas, 'total'));
$ticketMedio     = $totalVendas > 0 ? $totalAmount / $totalVendas : 0;
$totalDesconto   = array_sum(array_column($vendas, 'desconto_total'));

// Agrupamento por método de pagamento
$porMetodo = [];
foreach ($vendas as $v) {
    $mp = $v['metodo_pagamento'] ?? 'Outro';
    if (!isset($porMetodo[$mp])) $porMetodo[$mp] = ['total' => 0, 'count' => 0];
    $porMetodo[$mp]['total'] += (float)($v['total'] ?? 0);
    $porMetodo[$mp]['count']++;
}
arsort($porMetodo);

$pageTitle  = 'Relatórios de Vendas POS';
$activePage = 'pos_relatorios';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/nexora/pos'], ['Relatórios', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Relatórios de Vendas</h1>
    <div class="adm-page-header-actions">
        <button class="adm-btn adm-btn-outline" onclick="window.print()">
            <i class="fa-solid fa-file-pdf"></i> Exportar PDF
        </button>
    </div>
</div>

<!-- Filtros -->
<form method="GET" class="adm-card adm-mb-6">
    <div class="adm-card-body">
        <div style="display:flex;gap:var(--adm-sp-4);flex-wrap:wrap;align-items:flex-end">
            <div class="adm-form-group" style="margin-bottom:0">
                <label class="adm-label">Data Início</label>
                <input type="date" class="adm-input" name="data_inicio" value="<?= htmlspecialchars($dataInicio) ?>">
            </div>
            <div class="adm-form-group" style="margin-bottom:0">
                <label class="adm-label">Data Fim</label>
                <input type="date" class="adm-input" name="data_fim" value="<?= htmlspecialchars($dataFim) ?>">
            </div>
            <div class="adm-form-group" style="margin-bottom:0">
                <label class="adm-label">Método de Pagamento</label>
                <select class="adm-select" name="metodo">
                    <option value="">Todos</option>
                    <option value="Dinheiro"     <?= $metodo === 'Dinheiro'     ? 'selected' : '' ?>>Dinheiro</option>
                    <option value="Cartão"       <?= $metodo === 'Cartão'       ? 'selected' : '' ?>>Cartão</option>
                    <option value="M-Pesa"       <?= $metodo === 'M-Pesa'       ? 'selected' : '' ?>>M-Pesa</option>
                    <option value="E-Mola"       <?= $metodo === 'E-Mola'       ? 'selected' : '' ?>>E-Mola</option>
                    <option value="Transferência" <?= $metodo === 'Transferência' ? 'selected' : '' ?>>Transferência</option>
                </select>
            </div>
            <button type="submit" class="adm-btn adm-btn-primary">
                <i class="fa-solid fa-filter"></i> Filtrar
            </button>
        </div>
    </div>
</form>

<!-- KPIs -->
<div class="adm-stats-grid" style="margin-bottom:var(--adm-sp-6)">
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--green"><i class="fa-solid fa-money-bill-wave" style="font-size:1.1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= number_format($totalAmount, 2, ',', '.') ?> MT</div>
            <div class="adm-stat-label">Total Vendido</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue"><i class="fa-solid fa-receipt" style="font-size:1.1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= $totalVendas ?></div>
            <div class="adm-stat-label">Nº de Transações</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--yellow"><i class="fa-solid fa-chart-bar" style="font-size:1.1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= number_format($ticketMedio, 2, ',', '.') ?> MT</div>
            <div class="adm-stat-label">Ticket Médio</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--red"><i class="fa-solid fa-tag" style="font-size:1.1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= number_format($totalDesconto, 2, ',', '.') ?> MT</div>
            <div class="adm-stat-label">Total Descontos</div>
        </div>
    </div>
</div>

<div style="display:grid;grid-template-columns:280px 1fr;gap:var(--adm-sp-6)">

    <!-- Métodos de pagamento -->
    <div class="adm-card">
        <div class="adm-card-header"><h2 class="adm-card-title">Por Método</h2></div>
        <div class="adm-card-body">
            <?php if (empty($porMetodo)): ?>
            <p class="adm-text-sm adm-text-muted">Sem dados.</p>
            <?php else: $totalM = array_sum(array_column($porMetodo, 'total')); ?>
            <?php foreach ($porMetodo as $mp => $dados): $pct = $totalM > 0 ? round($dados['total'] / $totalM * 100) : 0; ?>
            <div style="margin-bottom:var(--adm-sp-4)">
                <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:var(--adm-sp-1)">
                    <span class="adm-fw-600 adm-text-sm"><?= htmlspecialchars($mp) ?></span>
                    <span class="adm-badge adm-badge--gray"><?= $dados['count'] ?> vend.</span>
                </div>
                <div style="background:var(--adm-gray-100);border-radius:99px;height:8px">
                    <div style="background:var(--adm-green);border-radius:99px;height:8px;width:<?= $pct ?>%"></div>
                </div>
                <div style="display:flex;justify-content:space-between;margin-top:var(--adm-sp-1)">
                    <span class="adm-text-xs adm-text-muted"><?= number_format($dados['total'], 2, ',', '.') ?> MT</span>
                    <span class="adm-text-xs adm-text-muted"><?= $pct ?>%</span>
                </div>
            </div>
            <?php endforeach; ?>
            <?php endif; ?>
        </div>
    </div>

    <!-- Tabela de transações -->
    <div class="adm-card">
        <div class="adm-card-header">
            <h2 class="adm-card-title">Transações (<?= $totalVendas ?>)</h2>
        </div>
        <?php if (empty($vendas)): ?>
        <div class="adm-empty"><p class="adm-empty-title">Sem vendas no período</p></div>
        <?php else: ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Ref.</th>
                        <th>Data / Hora</th>
                        <th>Método</th>
                        <th>Items</th>
                        <th>Desconto</th>
                        <th>Total</th>
                        <th>Estado</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach (array_reverse($vendas) as $v):
                    $estado = $v['estado'] ?? 'concluida';
                    $badge  = match($estado) {
                        'concluida' => ['adm-badge--green', 'Concluída'],
                        'cancelada' => ['adm-badge--red',   'Cancelada'],
                        default     => ['adm-badge--yellow', ucfirst($estado)],
                    };
                ?>
                <tr>
                    <td class="adm-fw-600 adm-text-xs"><?= htmlspecialchars($v['referencia'] ?? '#' . $v['id']) ?></td>
                    <td class="adm-text-muted" style="white-space:nowrap">
                        <?= !empty($v['criada_em']) ? date('d/m/Y H:i', strtotime($v['criada_em'])) : '—' ?>
                    </td>
                    <td><?= htmlspecialchars($v['metodo_pagamento'] ?? '—') ?></td>
                    <td><?= (int)($v['num_itens'] ?? 0) ?></td>
                    <td class="adm-text-muted"><?= number_format((float)($v['desconto_total'] ?? 0), 2, ',', '.') ?> MT</td>
                    <td class="adm-fw-600"><?= number_format((float)($v['total'] ?? 0), 2, ',', '.') ?> MT</td>
                    <td><span class="adm-badge <?= $badge[0] ?>"><?= $badge[1] ?></span></td>
                    <td>
                        <a href="<?= htmlspecialchars($app->routes->path('pos_venda_ver', ['id' => $v['id']])) ?>"
                           class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon">
                            <i class="fa-solid fa-eye"></i>
                        </a>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php endif; ?>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
