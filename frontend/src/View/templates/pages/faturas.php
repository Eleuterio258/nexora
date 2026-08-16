<?php

$statusFiltro = $app->request->queryString('status');
$tipoFiltro   = $app->request->queryString('tipo');

$query = array_filter(['status' => $statusFiltro ?: null, 'limit' => 100]);
$resp  = $app->nexora->call('GET', '/api/faturacao/invoices', null, $query);
$faturas = $resp['body']['data'] ?? [];
if ($tipoFiltro !== '') {
    $faturas = array_values(array_filter($faturas, static fn($f) => ($f['tipo'] ?? '') === $tipoFiltro));
}

$clientesResp = $app->nexora->call('GET', '/api/clientes', null, ['limit' => 200]);
$clientesPorId = [];
foreach (($clientesResp['body']['data'] ?? []) as $c) {
    $clientesPorId[(int) $c['id']] = $c['nome'] ?? ('#' . $c['id']);
}

$statusBadges = [
    'rascunho'          => ['adm-badge--gray',   'Rascunho'],
    'emitida'           => ['adm-badge--blue',   'Emitida'],
    'parcialmente_paga' => ['adm-badge--yellow', 'Parcialmente Paga'],
    'paga'              => ['adm-badge--green',  'Paga'],
    'cancelada'         => ['adm-badge--red',    'Cancelada'],
    'vencida'           => ['adm-badge--indigo', 'Vencida'],
];
$tipoLabels = ['normal' => 'Fatura', 'FR' => 'Fatura-recibo', 'VD' => 'Venda a Dinheiro', 'proforma' => 'Pró-forma'];

$pageTitle  = 'Faturas';
$activePage = 'faturas';
$breadcrumb = [['Admin', '/nexora/'], ['Faturação', ''], ['Faturas', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Faturas</h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('fatura_form')) ?>" class="adm-btn adm-btn-primary">
            <i class="fa-solid fa-plus"></i> Nova Fatura
        </a>
    </div>
</div>

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Lista de faturas</h2></div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($faturas)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Número</th><th>Cliente</th><th>Tipo</th><th>Emissão</th><th>Vencimento</th><th>Estado</th><th style="text-align:right">Total</th><th></th></tr>
                </thead>
                <tbody>
                <?php foreach ($faturas as $f):
                    $badge = $statusBadges[$f['status']] ?? ['adm-badge--gray', $f['status']];
                ?>
                    <tr>
                        <td class="adm-fw-600"><?= htmlspecialchars($f['numero']) ?></td>
                        <td><?= htmlspecialchars($clientesPorId[(int) $f['customer_id']] ?? ('#' . $f['customer_id'])) ?></td>
                        <td class="adm-text-muted"><?= htmlspecialchars($tipoLabels[$f['tipo']] ?? $f['tipo']) ?></td>
                        <td class="adm-text-muted"><?= date('d/m/Y', strtotime($f['invoice_date'])) ?></td>
                        <td class="adm-text-muted"><?= !empty($f['due_date']) ? date('d/m/Y', strtotime($f['due_date'])) : '—' ?></td>
                        <td><span class="adm-badge <?= $badge[0] ?>"><?= $badge[1] ?></span></td>
                        <td style="text-align:right" class="adm-fw-600"><?= number_format((float) $f['total'], 2, ',', '.') ?> <?= htmlspecialchars($f['moeda']) ?></td>
                        <td>
                            <a href="<?= htmlspecialchars($app->routes->path('fatura_detalhe', ['id' => $f['id']])) ?>" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Ver">
                                <i class="fa-solid fa-eye"></i>
                            </a>
                            <?php if ($f['status'] === 'rascunho'): ?>
                            <a href="<?= htmlspecialchars($app->routes->path('fatura_form', ['id' => $f['id']])) ?>" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Editar">
                                <i class="fa-solid fa-pen"></i>
                            </a>
                            <?php endif; ?>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-12)">
            <i class="fa-solid fa-file-invoice-dollar" style="font-size:2rem;opacity:.2"></i>
            <p class="adm-empty-title">Sem faturas</p>
            <p class="adm-empty-sub">Crie a primeira fatura para começar.</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
