<?php

declare(strict_types=1);

if (!$app->session->canModule('stock')) {
    header('Location: /nexora');
    exit;
}

$id = $_GET['id'] ?? '';
$isEdit = $id !== '';
$produto = null;
$erro = null;
$sucesso = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');

        $imageUrl = $_POST['image_url'] ?? null;
        if (!empty($_FILES['image_file']['tmp_name'])) {
            $imageUrl = $app->payCoreFileUpload->uploadSingle($_FILES['image_file']);
        }

        $data = [
            'name' => $_POST['name'] ?? '',
            'description' => $_POST['description'] ?? null,
            'category_id' => $_POST['category_id'] ?? null,
            'price' => (float) ($_POST['price'] ?? 0),
            'cost_price' => $_POST['cost_price'] !== '' ? (float) $_POST['cost_price'] : null,
            'barcode' => $_POST['barcode'] ?? null,
            'sku' => $_POST['sku'] ?? null,
            'image_url' => $imageUrl,
            'unit' => $_POST['unit'] ?? null,
            'stock' => (int) ($_POST['stock'] ?? 0),
            'min_stock' => (int) ($_POST['min_stock'] ?? 0),
            'active' => isset($_POST['active']),
        ];

        if ($isEdit) {
            $app->payCoreStockProduct->update($id, $data);
            $sucesso = 'Produto actualizado com sucesso.';
        } else {
            $novo = $app->payCoreStockProduct->create($data);
            $id = $novo['id'] ?? '';
            $isEdit = $id !== '';
            $sucesso = 'Produto criado com sucesso.';
        }
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

try {
    if ($isEdit) {
        $produto = $app->payCoreStockProduct->get($id);
    }
    $categorias = $app->payCoreStockCategory->list(true);
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

if ($isEdit && $produto === null) {
    header('Location: ' . $app->routes->path('produtos'));
    exit;
}

$pageTitle  = $isEdit ? 'Editar Produto' : 'Novo Produto';
$activePage = 'produtos';
$breadcrumb = [['Admin', '/nexora/'], ['Produtos', '/nexora/produtos'], [$pageTitle, '']];
$csrf       = $app->security->csrfToken();

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title"><?= $pageTitle ?></h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('produtos')) ?>" class="adm-btn adm-btn-outline">
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

<?php if ($sucesso): ?>
<div class="adm-alert adm-alert--success" style="margin-bottom:var(--adm-sp-5)">
    <i class="fa-solid fa-check-circle"></i>
    <span><?= htmlspecialchars($sucesso) ?></span>
</div>
<?php endif; ?>

<div class="adm-card">
    <div class="adm-card-body">
        <form method="post" action="" enctype="multipart/form-data">
            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">

            <div class="adm-form-row" style="grid-template-columns:1fr 1fr">
                <div class="adm-form-group">
                    <label class="adm-label" for="name">Nome <span class="adm-text-red">*</span></label>
                    <input type="text" id="name" name="name" class="adm-input" value="<?= htmlspecialchars($produto['name'] ?? '') ?>" required>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="category_id">Categoria</label>
                    <select id="category_id" name="category_id" class="adm-select">
                        <option value="">— Seleccionar —</option>
                        <?php foreach ($categorias as $c): ?>
                        <option value="<?= htmlspecialchars($c['id']) ?>" <?= ($produto['category_id'] ?? '') === $c['id'] ? 'selected' : '' ?>>
                            <?= htmlspecialchars($c['name']) ?>
                        </option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>

            <div class="adm-form-group">
                <label class="adm-label" for="description">Descrição</label>
                <textarea id="description" name="description" class="adm-textarea" rows="3"><?= htmlspecialchars($produto['description'] ?? '') ?></textarea>
            </div>

            <div class="adm-form-row" style="grid-template-columns:1fr 1fr 1fr">
                <div class="adm-form-group">
                    <label class="adm-label" for="sku">SKU</label>
                    <input type="text" id="sku" name="sku" class="adm-input" value="<?= htmlspecialchars($produto['sku'] ?? '') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="barcode">Código de barras</label>
                    <input type="text" id="barcode" name="barcode" class="adm-input" value="<?= htmlspecialchars($produto['barcode'] ?? '') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="unit">Unidade</label>
                    <input type="text" id="unit" name="unit" class="adm-input" value="<?= htmlspecialchars($produto['unit'] ?? '') ?>" placeholder="UN, KG, LT…">
                </div>
            </div>

            <div class="adm-form-row" style="grid-template-columns:1fr 1fr 1fr">
                <div class="adm-form-group">
                    <label class="adm-label" for="price">Preço de venda (MZN) <span class="adm-text-red">*</span></label>
                    <input type="number" id="price" name="price" class="adm-input" step="0.01" min="0" value="<?= isset($produto['price']) ? number_format((float) $produto['price'], 2) : '0.00' ?>" required>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="cost_price">Preço de custo (MZN)</label>
                    <input type="number" id="cost_price" name="cost_price" class="adm-input" step="0.01" min="0" value="<?= isset($produto['cost_price']) ? number_format((float) $produto['cost_price'], 2) : '' ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="image_file">Imagem do produto</label>
                    <?php if (!empty($produto['image_url'])): ?>
                    <div style="margin-bottom:var(--adm-sp-2)">
                        <img src="<?= htmlspecialchars($produto['image_url']) ?>" style="max-height:80px;border-radius:6px;border:1px solid var(--adm-gray-200)">
                    </div>
                    <?php endif; ?>
                    <input type="file" id="image_file" name="image_file" class="adm-input" accept="image/*">
                    <p class="adm-input-hint">Ou introduza um URL externo abaixo.</p>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="image_url">URL da imagem</label>
                    <input type="url" id="image_url" name="image_url" class="adm-input" value="<?= htmlspecialchars($produto['image_url'] ?? '') ?>">
                </div>
            </div>

            <div class="adm-form-row" style="grid-template-columns:1fr 1fr 1fr">
                <div class="adm-form-group">
                    <label class="adm-label" for="stock">Stock inicial</label>
                    <input type="number" id="stock" name="stock" class="adm-input" min="0" value="<?= (int) ($produto['stock'] ?? 0) ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="min_stock">Stock mínimo</label>
                    <input type="number" id="min_stock" name="min_stock" class="adm-input" min="0" value="<?= (int) ($produto['min_stock'] ?? 0) ?>">
                </div>
                <div class="adm-form-group" style="display:flex;align-items:flex-end;gap:var(--adm-sp-2);padding-bottom:8px">
                    <label class="adm-label" style="display:flex;align-items:center;gap:var(--adm-sp-2);margin:0">
                        <input type="checkbox" name="active" id="active" <?= ($isEdit ? ($produto['active'] ?? false) : true) ? 'checked' : '' ?>>
                        Activo
                    </label>
                </div>
            </div>

            <div class="adm-flex-end" style="margin-top:var(--adm-sp-4)">
                <a href="<?= htmlspecialchars($app->routes->path('produtos')) ?>" class="adm-btn adm-btn-outline">Cancelar</a>
                <button type="submit" class="adm-btn adm-btn-primary">
                    <i class="fa-solid fa-save"></i> Guardar
                </button>
            </div>
        </form>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
