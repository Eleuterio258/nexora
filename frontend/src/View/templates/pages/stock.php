<?php

declare(strict_types=1);

if (!$app->session->canModule('stock')) {
    header('Location: /nexora');
    exit;
}

$erro = null;
$totalProdutos = 0;
$alertas = [];
$produtos = [];

try {
    $produtos = $app->payCoreStockProduct->list();
    $totalProdutos = count($produtos);
    $alertas = $app->payCoreStockProduct->lowStock();
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

$pageTitle  = 'Gestão de Stock';
$activePage = 'stock';
$breadcrumb = [['Admin', '/nexora/'], ['Gestão de Stock', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Gestão de Stock</h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('produtos')) ?>" class="adm-btn adm-btn-outline">
            <i class="fa-solid fa-boxes-stacked"></i> Produtos
        </a>
        <a href="<?= htmlspecialchars($app->routes->path('produto_form')) ?>" class="adm-btn adm-btn-primary">
            <i class="fa-solid fa-plus"></i> Novo Produto
        </a>
    </div>
</div>

<?php if ($erro): ?>
<div class="adm-alert adm-alert--error" style="margin-bottom:var(--adm-sp-5)">
    <i class="fa-solid fa-circle-exclamation"></i>
    <span><?= htmlspecialchars($erro) ?></span>
</div>
<?php endif; ?>

<div class="adm-stats-grid" style="margin-bottom:var(--adm-sp-6)">
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue"><i class="fa-solid fa-boxes-stacked" style="font-size:1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= $totalProdutos ?></div>
            <div class="adm-stat-label">Produtos</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--red"><i class="fa-solid fa-triangle-exclamation" style="font-size:1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= count($alertas) ?></div>
            <div class="adm-stat-label">Alertas de stock</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--green"><i class="fa-solid fa-check-circle" style="font-size:1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= count(array_filter($produtos, static fn(array $p): bool => ($p['active'] ?? false))) ?></div>
            <div class="adm-stat-label">Produtos activos</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--yellow"><i class="fa-solid fa-rotate" style="font-size:1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= count(array_filter($produtos, static fn(array $p): bool => ($p['stock'] ?? 0) === 0)) ?></div>
            <div class="adm-stat-label">Sem stock</div>
        </div>
    </div>
</div>

<div class="adm-card" style="margin-bottom:var(--adm-sp-6)">
    <div class="adm-card-header" style="justify-content:space-between">
        <h2 class="adm-card-title">Alertas de stock baixo</h2>
        <a href="<?= htmlspecialchars($app->routes->path('stock_alertas')) ?>" class="adm-btn adm-btn-outline adm-btn-sm">Ver todos</a>
    </div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($alertas)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Produto</th>
                        <th>SKU</th>
                        <th>Stock actual</th>
                        <th>Stock mínimo</th>
                        <th>Diferença</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach (array_slice($alertas, 0, 10) as $a):
                    $diff = (int) ($a['stock'] ?? 0) - (int) ($a['min_stock'] ?? 0);
                ?>
                    <tr>
                        <td><?= htmlspecialchars($a['name'] ?? '—') ?></td>
                        <td class="adm-text-muted"><?= htmlspecialchars($a['sku'] ?? '—') ?></td>
                        <td><span class="adm-badge adm-badge--red"><?= (int) ($a['stock'] ?? 0) ?></span></td>
                        <td class="adm-text-muted"><?= (int) ($a['min_stock'] ?? 0) ?></td>
                        <td class="adm-text-red adm-fw-600"><?= $diff ?></td>
                        <td>
                            <a href="<?= htmlspecialchars($app->routes->path('produto_detalhe', ['id' => $a['id'] ?? ''])) ?>" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Ajustar stock">
                                <i class="fa-solid fa-sliders"></i>
                            </a>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-8)">
            <i class="fa-solid fa-check-circle" style="font-size:2rem;opacity:.2"></i>
            <p class="adm-empty-title">Sem alertas de stock</p>
            <p class="adm-empty-sub">Todos os produtos estão acima do stock mínimo.</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<div class="adm-card">
    <div class="adm-card-header" style="justify-content:space-between">
        <h2 class="adm-card-title">Atalhos</h2>
    </div>
    <div class="adm-card-body">
        <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:var(--adm-sp-4)">
            <a href="<?= htmlspecialchars($app->routes->path('produtos')) ?>" class="adm-module-card" style="--adm-module-color:#10b98140">
                <div class="adm-module-card-icon" style="background:#10b98118">
                    <i class="fa-solid fa-boxes-stacked" style="font-size:1.05rem;color:#10b981"></i>
                </div>
                <span class="adm-module-card-label">Produtos</span>
            </a>
            <a href="<?= htmlspecialchars($app->routes->path('produto_categorias')) ?>" class="adm-module-card" style="--adm-module-color:#3b82f640">
                <div class="adm-module-card-icon" style="background:#3b82f618">
                    <i class="fa-solid fa-tags" style="font-size:1.05rem;color:#3b82f6"></i>
                </div>
                <span class="adm-module-card-label">Categorias</span>
            </a>
            <a href="<?= htmlspecialchars($app->routes->path('stock_alertas')) ?>" class="adm-module-card" style="--adm-module-color:#ef444440">
                <div class="adm-module-card-icon" style="background:#ef444418">
                    <i class="fa-solid fa-triangle-exclamation" style="font-size:1.05rem;color:#ef4444"></i>
                </div>
                <span class="adm-module-card-label">Alertas</span>
            </a>
        </div>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
