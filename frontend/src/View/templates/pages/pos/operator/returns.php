<?php
declare(strict_types=1);

/**
 * Devoluções — Portal Operador
 */

$erro = null;
$sucesso = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');
        $saleId = (int) ($_POST['sale_id'] ?? 0);
        if ($saleId <= 0) {
            throw new \RuntimeException('ID da venda inválido.');
        }
        $payload = [
            'pos_sale_id'  => $saleId,
            'reason'       => trim($_POST['reason'] ?? ''),
            'items'        => array_map(static fn ($id) => ['pos_sale_item_id' => (int) $id], array_keys($_POST['items'] ?? [])),
        ];
        $app->nexora->call('POST', '/api/pos/returns', $payload);
        $sucesso = 'Devolução registada com sucesso.';
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

$saleId = (int) ($_GET['sale_id'] ?? 0);
$sale = null;
if ($saleId > 0) {
    try {
        $sale = $app->pos->getVenda($saleId);
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Devoluções';
$activePage = 'pos_operator_returns';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/pos/gerente/dashboard'], ['Devoluções', '']];

include dirname(__DIR__, 2) . '/layouts/top.php';
?>

<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h1 class="h3 mb-0"><i class="bi bi-arrow-return-left"></i> Devoluções</h1>
        <span class="badge bg-primary">Portal Operador</span>
    </div>

    <?php if ($erro): ?>
    <div class="alert alert-danger"><?= htmlspecialchars($erro) ?></div>
    <?php endif; ?>
    <?php if ($sucesso): ?>
    <div class="alert alert-success"><?= htmlspecialchars($sucesso) ?></div>
    <?php endif; ?>

    <div class="card">
        <div class="card-body">
            <?php if (!$sale): ?>
            <form method="get" class="mb-4">
                <div class="input-group">
                    <input type="number" class="form-control" name="sale_id" placeholder="ID da venda" required>
                    <button type="submit" class="btn btn-primary">Carregar Venda</button>
                </div>
            </form>
            <p class="text-muted">Introduza o ID da venda para registar uma devolução.</p>
            <?php else: ?>
            <h5>Venda #<?= (int) $sale['id'] ?> — <?= htmlspecialchars($sale['numero'] ?? '') ?></h5>
            <p class="text-muted">Total: <?= number_format((float) ($sale['total'] ?? 0), 2) ?> MZN</p>

            <form method="post">
                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
                <input type="hidden" name="sale_id" value="<?= (int) $sale['id'] ?>">
                <div class="mb-3">
                    <label for="reason" class="form-label">Motivo <span class="text-danger">*</span></label>
                    <textarea class="form-control" id="reason" name="reason" rows="3" required></textarea>
                </div>
                <?php if (!empty($sale['itens']) && is_array($sale['itens'])): ?>
                <div class="mb-3">
                    <label class="form-label">Itens a devolver</label>
                    <?php foreach ($sale['itens'] as $i => $item): ?>
                    <div class="form-check">
                        <input class="form-check-input" type="checkbox" name="items[<?= (int) $item['id'] ?>]" id="item_<?= (int) $item['id'] ?>" value="1">
                        <label class="form-check-label" for="item_<?= (int) $item['id'] ?>">
                            <?= htmlspecialchars($item['nome'] ?? ('#' . $item['id'])) ?> — <?= number_format((float) ($item['total'] ?? 0), 2) ?> MZN
                        </label>
                    </div>
                    <?php endforeach; ?>
                </div>
                <?php endif; ?>
                <button type="submit" class="btn btn-primary">Registar Devolução</button>
                <a href="<?= htmlspecialchars($app->routes->path('pos_operator_returns')) ?>" class="btn btn-secondary">Voltar</a>
            </form>
            <?php endif; ?>
        </div>
    </div>
</div>

<?php include dirname(__DIR__, 2) . '/layouts/bottom.php'; ?>
