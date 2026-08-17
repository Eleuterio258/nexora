<?php
declare(strict_types=1);

/**
 * Catálogo POS — Portal Admin
 */

$erro = null;
$catalogo = [];
try {
    $catalogo = $app->pos->listCatalogo();
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

$pageTitle  = 'Catálogo POS';
$activePage = 'pos_admin_catalog';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/pos/gerente/dashboard'], ['Catálogo', '']];

include dirname(__DIR__, 2) . '/layouts/top.php';
?>

<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h1 class="h3 mb-0"><i class="bi bi-box-seam"></i> Catálogo POS</h1>
        <span class="badge bg-secondary">Portal Admin</span>
    </div>

    <?php if ($erro): ?>
    <div class="alert alert-danger"><?= htmlspecialchars($erro) ?></div>
    <?php endif; ?>

    <div class="card">
        <div class="card-body">
            <div class="table-responsive">
                <table class="table table-striped">
                    <thead>
                        <tr><th>Produto</th><th>Preço</th><th>Categoria</th><th>Acções</th></tr>
                    </thead>
                    <tbody>
                    <?php if (empty($catalogo)): ?>
                        <tr><td colspan="4" class="text-muted text-center">Catálogo vazio.</td></tr>
                    <?php else: ?>
                        <?php foreach ($catalogo as $item): ?>
                        <tr>
                            <td><?= htmlspecialchars($item['product_name'] ?? ('#' . ($item['product_id'] ?? ''))) ?></td>
                            <td><?= number_format((float) ($item['preco_venda'] ?? 0), 2) ?> MZN</td>
                            <td><?= htmlspecialchars($item['categoria'] ?? '—') ?></td>
                            <td>
                                <button type="button" class="btn btn-sm btn-outline-danger" onclick="removerItem(<?= (int) ($item['id'] ?? 0) ?>)">Remover</button>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<script>
async function removerItem(id) {
    if (!confirm('Remover item do catálogo POS?')) return;
    try {
        const res = await fetch('/nexora/api/pos_catalogo_remover?id=' + id, { method: 'POST' });
        const data = await res.json();
        if (data.ok) location.reload();
        else alert(data.erro || 'Erro');
    } catch { alert('Erro de ligação'); }
}
</script>

<?php include dirname(__DIR__, 2) . '/layouts/bottom.php'; ?>
