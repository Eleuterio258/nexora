<?php

declare(strict_types=1);

if (!$app->session->canModule('stock')) {
    header('Location: /nexora');
    exit;
}

$id = $_GET['id'] ?? '';
if ($id === '') {
    header('Location: ' . $app->routes->path('produtos'));
    exit;
}

$erro = null;
$sucesso = null;
$produto = null;
$logs = [];
$categorias = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');

        if (isset($_POST['ajuste_stock'])) {
            $app->payCoreStockAdjustment->adjust($id, [
                'quantity' => (int) ($_POST['quantity'] ?? 0),
                'type' => $_POST['type'] ?? 'MANUAL_ADJUSTMENT',
                'reason' => $_POST['reason'] ?? '',
                'reference_number' => $_POST['reference_number'] ?? null,
            ]);
            $sucesso = 'Stock ajustado com sucesso.';
        } elseif (isset($_POST['actualizar_produto'])) {
            $app->payCoreStockProduct->update($id, [
                'name' => $_POST['name'] ?? '',
                'description' => $_POST['description'] ?? null,
                'category_id' => $_POST['category_id'] ?? null,
                'price' => (float) ($_POST['price'] ?? 0),
                'cost_price' => $_POST['cost_price'] !== '' ? (float) $_POST['cost_price'] : null,
                'barcode' => $_POST['barcode'] ?? null,
                'sku' => $_POST['sku'] ?? null,
                'unit' => $_POST['unit'] ?? null,
                'min_stock' => (int) ($_POST['min_stock'] ?? 0),
                'active' => isset($_POST['active']),
            ]);
            $sucesso = 'Produto actualizado com sucesso.';
        }
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

try {
    $produto = $app->payCoreStockProduct->get($id);
    $categorias = $app->payCoreStockCategory->list(true);
    $logs = $app->payCoreStockAdjustment->logs($id);
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

if ($produto === null) {
    header('Location: ' . $app->routes->path('produtos'));
    exit;
}

$pageTitle  = 'Detalhe do Produto';
$activePage = 'produtos';
$breadcrumb = [['Admin', '/nexora/'], ['Produtos', '/nexora/produtos'], ['Detalhe', '']];
$csrf       = $app->security->csrfToken();

$categoriaNomes = array_column($categorias, 'name', 'id');
$stock = (int) ($produto['stock'] ?? 0);
$minStock = (int) ($produto['min_stock'] ?? 0);
$stockBaixo = $minStock > 0 && $stock <= $minStock;

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Detalhe do Produto</h1>
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

<div style="display:grid;grid-template-columns:1fr 360px;gap:var(--adm-sp-6);align-items:start;margin-bottom:var(--adm-sp-6)">
    <div class="adm-card">
        <div class="adm-card-header">
            <h2 class="adm-card-title">Informações gerais</h2>
        </div>
        <div class="adm-card-body">
            <form method="post" action="">
                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
                <input type="hidden" name="actualizar_produto" value="1">

                <div class="adm-form-row" style="grid-template-columns:1fr 1fr">
                    <div class="adm-form-group">
                        <label class="adm-label" for="name">Nome</label>
                        <input type="text" id="name" name="name" class="adm-input" value="<?= htmlspecialchars($produto['name'] ?? '') ?>" required>
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="category_id">Categoria</label>
                        <select id="category_id" name="category_id" class="adm-select">
                            <option value="">—</option>
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
                    <textarea id="description" name="description" class="adm-textarea" rows="2"><?= htmlspecialchars($produto['description'] ?? '') ?></textarea>
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
                        <label class="adm-label" for="price">Preço de venda (MZN)</label>
                        <input type="number" id="price" name="price" class="adm-input" step="0.01" min="0" value="<?= number_format((float) ($produto['price'] ?? 0), 2) ?>" required>
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="cost_price">Custo (MZN)</label>
                        <input type="number" id="cost_price" name="cost_price" class="adm-input" step="0.01" min="0" value="<?= isset($produto['cost_price']) ? number_format((float) $produto['cost_price'], 2) : '' ?>">
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="min_stock">Stock mínimo</label>
                        <input type="number" id="min_stock" name="min_stock" class="adm-input" min="0" value="<?= (int) ($produto['min_stock'] ?? 0) ?>">
                    </div>
                </div>

                <div class="adm-form-group">
                    <label class="adm-label" style="display:flex;align-items:center;gap:var(--adm-sp-2)">
                        <input type="checkbox" name="active" id="active" <?= ($produto['active'] ?? false) ? 'checked' : '' ?>>
                        Activo
                    </label>
                </div>

                <div class="adm-flex-end">
                    <button type="submit" class="adm-btn adm-btn-primary">
                        <i class="fa-solid fa-save"></i> Guardar alterações
                    </button>
                </div>
            </form>
        </div>
    </div>

    <div>
        <div class="adm-card" style="margin-bottom:var(--adm-sp-6)">
            <div class="adm-card-header">
                <h2 class="adm-card-title">Stock actual</h2>
            </div>
            <div class="adm-card-body" style="text-align:center">
                <div style="font-size:2.5rem;font-weight:800;color:<?= $stockBaixo ? 'var(--adm-red)' : 'var(--adm-green)' ?>"><?= $stock ?></div>
                <div class="adm-text-sm adm-text-muted">Unidades em stock</div>
                <?php if ($stockBaixo): ?>
                <div class="adm-alert adm-alert--error" style="margin-top:var(--adm-sp-4);text-align:left">
                    <i class="fa-solid fa-triangle-exclamation"></i>
                    <span>Stock abaixo do mínimo (<?= $minStock ?>)</span>
                </div>
                <?php endif; ?>
            </div>
        </div>

        <div class="adm-card">
            <div class="adm-card-header">
                <h2 class="adm-card-title">Ajustar stock</h2>
            </div>
            <div class="adm-card-body">
                <form method="post" action="">
                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
                    <input type="hidden" name="ajuste_stock" value="1">

                    <div class="adm-form-group">
                        <label class="adm-label" for="quantity">Quantidade (+/-)</label>
                        <input type="number" id="quantity" name="quantity" class="adm-input" step="1" required>
                        <p class="adm-input-hint">Use valor positivo para entrada e negativo para saída.</p>
                    </div>

                    <div class="adm-form-group">
                        <label class="adm-label" for="type">Tipo</label>
                        <select id="type" name="type" class="adm-select" required>
                            <option value="MANUAL_ADJUSTMENT">Ajuste manual</option>
                            <option value="PURCHASE">Compra</option>
                            <option value="SALE">Venda</option>
                            <option value="LOSS">Perda / Quebra</option>
                            <option value="TRANSFER">Transferência</option>
                            <option value="REVERSAL">Estorno</option>
                        </select>
                    </div>

                    <div class="adm-form-group">
                        <label class="adm-label" for="reason">Motivo</label>
                        <textarea id="reason" name="reason" class="adm-textarea" rows="2" required></textarea>
                    </div>

                    <div class="adm-form-group">
                        <label class="adm-label" for="reference_number">Referência (opcional)</label>
                        <input type="text" id="reference_number" name="reference_number" class="adm-input">
                    </div>

                    <div class="adm-flex-end">
                        <button type="submit" class="adm-btn adm-btn-primary">
                            <i class="fa-solid fa-sliders"></i> Ajustar
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<div class="adm-card">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Histórico de movimentos</h2>
    </div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($logs)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Data</th>
                        <th>Tipo</th>
                        <th>Quantidade</th>
                        <th>Motivo</th>
                        <th>Referência</th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($logs as $log): ?>
                    <tr>
                        <td class="adm-text-muted"><?= !empty($log['timestamp']) ? date('d/m/Y H:i', strtotime($log['timestamp'])) : '—' ?></td>
                        <td><span class="adm-badge adm-badge--gray"><?= htmlspecialchars($log['type'] ?? '—') ?></span></td>
                        <td class="adm-fw-600 <?= ($log['adjustment'] ?? 0) < 0 ? 'adm-text-red' : 'adm-text-green' ?>">
                            <?= ($log['adjustment'] ?? 0) > 0 ? '+' : '' ?><?= (int) ($log['adjustment'] ?? 0) ?>
                        </td>
                        <td><?= htmlspecialchars($log['reason'] ?? '—') ?></td>
                        <td class="adm-text-muted"><?= htmlspecialchars($log['referenceNumber'] ?? '—') ?></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-8)">
            <p class="adm-empty-title">Sem movimentos registados</p>
            <p class="adm-empty-sub">O histórico de ajustes será mostrado aqui.</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
