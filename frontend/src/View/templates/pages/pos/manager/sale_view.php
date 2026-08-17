<?php
declare(strict_types=1);

/**
 * Detalhe da Venda — Portal Gerente
 */

$saleId = (int) ($_GET['id'] ?? 0);
$erro = null;
$sale = null;

if ($saleId > 0) {
    try {
        $sale = $app->pos->getVenda($saleId);
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

$pageTitle  = 'Detalhe da Venda';
$activePage = 'pos_manager_sale_view';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/pos/gerente/dashboard'], ['Vendas', '/pos/gerente/vendas'], ['Detalhe', '']];

include dirname(__DIR__, 2) . '/layouts/top.php';
?>

<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h1 class="h3 mb-0"><i class="bi bi-receipt"></i> Venda #<?= $saleId ?></h1>
        <span class="badge bg-info text-dark">Portal Gerente</span>
    </div>

    <?php if ($erro): ?>
    <div class="alert alert-danger"><?= htmlspecialchars($erro) ?></div>
    <?php endif; ?>

    <?php if ($sale): ?>
    <div class="card mb-3">
        <div class="card-body">
            <p><strong>Número:</strong> <?= htmlspecialchars($sale['numero'] ?? '—') ?></p>
            <p><strong>Data:</strong> <?= !empty($sale['sold_at']) ? date('d/m/Y H:i', strtotime($sale['sold_at'])) : (!empty($sale['created_at']) ? date('d/m/Y H:i', strtotime($sale['created_at'])) : '—') ?></p>
            <p><strong>Terminal:</strong> <?= htmlspecialchars($sale['terminal_nome'] ?? ($sale['terminal_id'] ? '#' . $sale['terminal_id'] : '—')) ?></p>
            <p><strong>Operador:</strong> <?= htmlspecialchars($sale['operador_nome'] ?? ($sale['created_by'] ? '#' . $sale['created_by'] : '—')) ?></p>
            <p><strong>Total:</strong> <?= number_format((float) ($sale['total'] ?? 0), 2) ?> MZN</p>
            <p><strong>Estado:</strong>
                <span class="badge <?= ($sale['status'] ?? 'concluida') === 'cancelada' ? 'bg-danger' : 'bg-success' ?>">
                    <?= ucfirst($sale['status'] ?? 'concluida') ?>
                </span>
            </p>
        </div>
    </div>

    <div class="card">
        <div class="card-header"><strong>Itens</strong></div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-striped mb-0">
                    <thead>
                        <tr><th>Produto</th><th>Qtd</th><th>Preço</th><th>Total</th></tr>
                    </thead>
                    <tbody>
                    <?php if (empty($sale['itens'])): ?>
                        <tr><td colspan="4" class="text-muted text-center">Sem itens.</td></tr>
                    <?php else: ?>
                        <?php foreach ($sale['itens'] as $item): ?>
                        <tr>
                            <td><?= htmlspecialchars($item['nome'] ?? ('#' . ($item['id'] ?? ''))) ?></td>
                            <td><?= (float) ($item['quantidade'] ?? 0) ?></td>
                            <td><?= number_format((float) ($item['preco_unitario'] ?? 0), 2) ?> MZN</td>
                            <td><?= number_format((float) ($item['total'] ?? 0), 2) ?> MZN</td>
                        </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    <?php endif; ?>

    <a href="<?= htmlspecialchars($app->routes->path('pos_manager_sales')) ?>" class="btn btn-secondary mt-3">Voltar</a>
</div>

<?php include dirname(__DIR__, 2) . '/layouts/bottom.php'; ?>
