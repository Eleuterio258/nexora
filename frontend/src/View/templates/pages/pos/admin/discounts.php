<?php
declare(strict_types=1);

/**
 * Descontos POS — Portal Admin
 */

$erro = null;
$descontos = [];
try {
    $descontos = $app->pos->listDescontos();
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

$pageTitle  = 'Descontos POS';
$activePage = 'pos_admin_discounts';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/pos/gerente/dashboard'], ['Descontos', '']];

include dirname(__DIR__, 2) . '/layouts/top.php';
?>

<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h1 class="h3 mb-0"><i class="bi bi-percent"></i> Descontos POS</h1>
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
                        <tr><th>Nome</th><th>Tipo</th><th>Valor</th><th>Activo</th><th>Acções</th></tr>
                    </thead>
                    <tbody>
                    <?php if (empty($descontos)): ?>
                        <tr><td colspan="5" class="text-muted text-center">Sem descontos configurados.</td></tr>
                    <?php else: ?>
                        <?php foreach ($descontos as $d): ?>
                        <tr>
                            <td><?= htmlspecialchars($d['nome'] ?? '—') ?></td>
                            <td><?= htmlspecialchars($d['tipo'] ?? '—') ?></td>
                            <td><?= number_format((float) ($d['valor'] ?? 0), 2) ?><?= ($d['tipo'] ?? '') === 'percentagem' ? '%' : ' MZN' ?></td>
                            <td>
                                <span class="badge <?= !empty($d['activo']) ? 'bg-success' : 'bg-secondary' ?>">
                                    <?= !empty($d['activo']) ? 'Sim' : 'Não' ?>
                                </span>
                            </td>
                            <td>
                                <button type="button" class="btn btn-sm btn-outline-primary">Editar</button>
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

<?php include dirname(__DIR__, 2) . '/layouts/bottom.php'; ?>
