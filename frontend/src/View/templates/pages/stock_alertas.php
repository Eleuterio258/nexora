<?php

declare(strict_types=1);

if (!$app->session->canModule('stock')) {
    header('Location: /nexora');
    exit;
}

$erro = null;
$alertas = [];

try {
    $alertas = $app->payCoreStockProduct->lowStock();
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

$pageTitle  = 'Alertas de Stock';
$activePage = 'stock_alertas';
$breadcrumb = [['Admin', '/nexora/'], ['Stock', '/nexora/stock'], ['Alertas', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Alertas de Stock Baixo</h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('stock')) ?>" class="adm-btn adm-btn-outline">
            <i class="fa-solid fa-arrow-left"></i> Voltar
        </a>
    </div>
</div>

<?php if ($erro): ?>
<div class="adm-alert adm-alert--error" style="margin-bottom:var(--adm-sp-5)">
    <i class="fa-solid fa-circle-exclamation"></i>
    <span><?= htmlspecialchars($erro) ?></span>
</div>
<?php endif; ?>

<div class="adm-card">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Produtos abaixo do stock mínimo</h2>
    </div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($alertas)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Produto</th>
                        <th>SKU</th>
                        <th>Código de barras</th>
                        <th>Stock actual</th>
                        <th>Stock mínimo</th>
                        <th>Diferença</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($alertas as $a):
                    $diff = (int) ($a['stock'] ?? 0) - (int) ($a['min_stock'] ?? 0);
                ?>
                    <tr>
                        <td>
                            <div class="adm-fw-600"><?= htmlspecialchars($a['name'] ?? '—') ?></div>
                        </td>
                        <td class="adm-text-muted"><?= htmlspecialchars($a['sku'] ?? '—') ?></td>
                        <td class="adm-text-muted"><?= htmlspecialchars($a['barcode'] ?? '—') ?></td>
                        <td><span class="adm-badge adm-badge--red"><?= (int) ($a['stock'] ?? 0) ?></span></td>
                        <td class="adm-text-muted"><?= (int) ($a['min_stock'] ?? 0) ?></td>
                        <td class="adm-text-red adm-fw-600"><?= $diff ?></td>
                        <td>
                            <a href="<?= htmlspecialchars($app->routes->path('produto_detalhe', ['id' => $a['id'] ?? ''])) ?>" class="adm-btn adm-btn-primary adm-btn-sm">
                                <i class="fa-solid fa-sliders"></i> Ajustar
                            </a>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-12)">
            <i class="fa-solid fa-check-circle" style="font-size:2rem;opacity:.2"></i>
            <p class="adm-empty-title">Sem alertas de stock</p>
            <p class="adm-empty-sub">Todos os produtos estão acima do stock mínimo.</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
