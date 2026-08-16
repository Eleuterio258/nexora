<?php

$statusFiltro = $app->request->queryString('status');

$query = array_filter(['status' => $statusFiltro ?: null, 'limit' => 100]);
$resp  = $app->nexora->call('GET', '/api/faturacao/quotes', null, $query);
$orcamentos = $resp['body'] ?? [];

$clientesResp = $app->nexora->call('GET', '/api/clientes', null, ['limit' => 200]);
$clientesPorId = [];
foreach (($clientesResp['body']['data'] ?? []) as $c) {
    $clientesPorId[(int) $c['id']] = $c['nome'] ?? ('#' . $c['id']);
}

$statusBadges = [
    'rascunho'   => ['adm-badge--gray',   'Rascunho'],
    'enviado'    => ['adm-badge--blue',   'Enviado'],
    'aprovado'   => ['adm-badge--green',  'Aprovado'],
    'rejeitado'  => ['adm-badge--red',    'Rejeitado'],
    'convertido' => ['adm-badge--indigo', 'Convertido'],
    'expirado'   => ['adm-badge--yellow', 'Expirado'],
];

$pageTitle  = 'Orçamentos';
$activePage = 'orcamentos';
$breadcrumb = [['Admin', '/nexora/'], ['Faturação', ''], ['Orçamentos', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Orçamentos</h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('orcamento_form')) ?>" class="adm-btn adm-btn-primary">
            <i class="fa-solid fa-plus"></i> Novo Orçamento
        </a>
    </div>
</div>

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Lista de orçamentos</h2></div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($orcamentos)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Número</th><th>Cliente</th><th>Validade</th><th>Estado</th><th style="text-align:right">Total</th><th></th></tr>
                </thead>
                <tbody>
                <?php foreach ($orcamentos as $o):
                    $badge = $statusBadges[$o['status']] ?? ['adm-badge--gray', $o['status']];
                ?>
                    <tr>
                        <td class="adm-fw-600"><?= htmlspecialchars($o['numero']) ?></td>
                        <td><?= htmlspecialchars($clientesPorId[(int) $o['customer_id']] ?? ('#' . $o['customer_id'])) ?></td>
                        <td class="adm-text-muted"><?= !empty($o['validade']) ? date('d/m/Y', strtotime($o['validade'])) : '—' ?></td>
                        <td><span class="adm-badge <?= $badge[0] ?>"><?= $badge[1] ?></span></td>
                        <td style="text-align:right" class="adm-fw-600"><?= number_format((float) $o['total'], 2, ',', '.') ?> <?= htmlspecialchars($o['moeda']) ?></td>
                        <td>
                            <a href="<?= htmlspecialchars($app->routes->path('orcamento_form', ['id' => $o['id']])) ?>" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Ver / editar">
                                <i class="fa-solid fa-eye"></i>
                            </a>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-12)">
            <i class="fa-solid fa-file-lines" style="font-size:2rem;opacity:.2"></i>
            <p class="adm-empty-title">Sem orçamentos</p>
            <p class="adm-empty-sub">Crie o primeiro orçamento para começar.</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
