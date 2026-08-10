<?php

declare(strict_types=1);

if (!$app->session->canModule('stock')) {
    header('Location: /nexora');
    exit;
}

$erro = null;
$sucesso = null;
$produtos = [];
$categorias = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['acao']) && $_POST['acao'] === 'eliminar') {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');
        $app->payCoreStockProduct->delete($_POST['id'] ?? '');
        $sucesso = 'Produto removido com sucesso.';
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

$filtroCategoria = $_GET['categoria'] ?? '';
$filtroSearch = trim($_GET['q'] ?? '');
$filtroAtivo = $_GET['ativo'] ?? '';

try {
    $query = [];
    if ($filtroCategoria !== '') {
        $query['categoryId'] = $filtroCategoria;
    }
    if ($filtroAtivo !== '') {
        $query['active'] = $filtroAtivo;
    }

    $produtos = $app->payCoreStockProduct->list($query);
    if ($filtroSearch !== '') {
        $q = strtolower($filtroSearch);
        $produtos = array_filter($produtos, static fn(array $p): bool =>
            str_contains(strtolower($p['name'] ?? ''), $q) ||
            str_contains(strtolower($p['sku'] ?? ''), $q) ||
            str_contains(strtolower($p['barcode'] ?? ''), $q)
        );
    }

    $categorias = $app->payCoreStockCategory->list(true);
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

$categoriaNomes = array_column($categorias, 'name', 'id');

$pageTitle  = 'Produtos';
$activePage = 'produtos';
$breadcrumb = [['Admin', '/nexora/'], ['Produtos', '']];
$csrf       = $app->security->csrfToken();

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Produtos</h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('produto_categorias')) ?>" class="adm-btn adm-btn-outline">
            <i class="fa-solid fa-tags"></i> Categorias
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

<?php if ($sucesso): ?>
<div class="adm-alert adm-alert--success" style="margin-bottom:var(--adm-sp-5)">
    <i class="fa-solid fa-check-circle"></i>
    <span><?= htmlspecialchars($sucesso) ?></span>
</div>
<?php endif; ?>

<div class="adm-card" style="margin-bottom:var(--adm-sp-6)">
    <div class="adm-card-body">
        <form method="get" action="" class="adm-filter-bar" style="padding:0;background:none;border:none">
            <div class="adm-form-row" style="gap:var(--adm-sp-3);margin:0;align-items:end">
                <div class="adm-form-group" style="margin-bottom:0">
                    <label class="adm-label" for="q">Pesquisar</label>
                    <input type="text" id="q" name="q" class="adm-input" value="<?= htmlspecialchars($filtroSearch) ?>" placeholder="Nome, SKU ou codigo de barras">
                </div>
                <div class="adm-form-group" style="margin-bottom:0">
                    <label class="adm-label" for="categoria">Categoria</label>
                    <select id="categoria" name="categoria" class="adm-select">
                        <option value="">Todas</option>
                        <?php foreach ($categorias as $c): ?>
                        <option value="<?= htmlspecialchars($c['id']) ?>" <?= $filtroCategoria === $c['id'] ? 'selected' : '' ?>>
                            <?= htmlspecialchars($c['name']) ?>
                        </option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group" style="margin-bottom:0">
                    <label class="adm-label" for="ativo">Estado</label>
                    <select id="ativo" name="ativo" class="adm-select">
                        <option value="">Todos</option>
                        <option value="true" <?= $filtroAtivo === 'true' ? 'selected' : '' ?>>Activo</option>
                        <option value="false" <?= $filtroAtivo === 'false' ? 'selected' : '' ?>>Inactivo</option>
                    </select>
                </div>
                <button type="submit" class="adm-btn adm-btn-primary">
                    <i class="fa-solid fa-filter"></i> Filtrar
                </button>
                <a href="<?= htmlspecialchars($app->routes->path('produtos')) ?>" class="adm-btn adm-btn-outline">
                    <i class="fa-solid fa-rotate-right"></i>
                </a>
            </div>
        </form>
    </div>
</div>

<div class="adm-card">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Lista de produtos</h2>
    </div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($produtos)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th style="width:50px"></th>
                        <th>Produto</th>
                        <th>SKU</th>
                        <th>Categoria</th>
                        <th>Preço</th>
                        <th>Stock</th>
                        <th>Min.</th>
                        <th>Estado</th>
                        <th style="width:120px"></th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($produtos as $p):
                    $stock = (int) ($p['stock'] ?? 0);
                    $minStock = (int) ($p['min_stock'] ?? 0);
                    $stockBaixo = $minStock > 0 && $stock <= $minStock;
                ?>
                    <tr>
                        <td>
                            <div style="width:36px;height:36px;background:#f3f4f6;border-radius:6px;overflow:hidden;display:flex;align-items:center;justify-content:center">
                                <?php if (!empty($p['image_url'])): ?>
                                <img src="<?= htmlspecialchars($p['image_url']) ?>" style="width:100%;height:100%;object-fit:cover">
                                <?php else: ?>
                                <i class="fa-solid fa-box" style="color:#9ca3af;font-size:14px"></i>
                                <?php endif; ?>
                            </div>
                        </td>
                        <td>
                            <div class="adm-fw-600"><?= htmlspecialchars($p['name'] ?? '—') ?></div>
                            <?php if (!empty($p['barcode'])): ?>
                            <div class="adm-text-xs adm-text-muted"><?= htmlspecialchars($p['barcode']) ?></div>
                            <?php endif; ?>
                        </td>
                        <td class="adm-text-muted"><?= htmlspecialchars($p['sku'] ?? '—') ?></td>
                        <td class="adm-text-muted"><?= htmlspecialchars($categoriaNomes[$p['category_id'] ?? ''] ?? '—') ?></td>
                        <td class="adm-fw-600"><?= number_format((float) ($p['price'] ?? 0), 2) ?> MZN</td>
                        <td>
                            <span class="adm-badge <?= $stockBaixo ? 'adm-badge--red' : 'adm-badge--green' ?>">
                                <?= $stock ?>
                            </span>
                        </td>
                        <td class="adm-text-muted"><?= $minStock ?></td>
                        <td>
                            <?php if (($p['active'] ?? false)): ?>
                            <span class="adm-badge adm-badge--green">Activo</span>
                            <?php else: ?>
                            <span class="adm-badge adm-badge--gray">Inactivo</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <div class="adm-actions">
                                <a href="<?= htmlspecialchars($app->routes->path('produto_form', ['id' => $p['id'] ?? ''])) ?>" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Editar">
                                    <i class="fa-solid fa-pen"></i>
                                </a>
                                <a href="<?= htmlspecialchars($app->routes->path('produto_detalhe', ['id' => $p['id'] ?? ''])) ?>" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Detalhes e stock">
                                    <i class="fa-solid fa-eye"></i>
                                </a>
                                <form method="post" action="" style="display:inline" onsubmit="return confirm('Remover este produto?')">
                                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
                                    <input type="hidden" name="acao" value="eliminar">
                                    <input type="hidden" name="id" value="<?= htmlspecialchars($p['id'] ?? '') ?>">
                                    <button type="submit" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Remover">
                                        <i class="fa-solid fa-trash"></i>
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-12)">
            <i class="fa-solid fa-boxes-stacked" style="font-size:2rem;opacity:.2"></i>
            <p class="adm-empty-title">Sem produtos registados</p>
            <p class="adm-empty-sub">Crie o primeiro produto para comecar a gerir o stock.</p>
            <a href="<?= htmlspecialchars($app->routes->path('produto_form')) ?>" class="adm-btn adm-btn-primary">
                <i class="fa-solid fa-plus"></i> Novo Produto
            </a>
        </div>
        <?php endif; ?>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
