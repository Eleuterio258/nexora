<?php
declare(strict_types=1);

/**
 * Histórico de Vendas — Portal Gerente
 */

$filtros = [
    'page'  => max(1, (int) ($_GET['page'] ?? 1)),
    'limit' => 20,
];
if (!empty($_GET['q'])) {
    $filtros['q'] = $_GET['q'];
}
if (!empty($_GET['data_inicio'])) {
    $filtros['data_inicio'] = $_GET['data_inicio'];
}
if (!empty($_GET['data_fim'])) {
    $filtros['data_fim'] = $_GET['data_fim'];
}
if (isset($_GET['status']) && $_GET['status'] !== '') {
    $filtros['status'] = $_GET['status'];
}

$erro = null;
$vendas = [];
try {
    $vendas = $app->pos->listVendas($filtros);
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Histórico de Vendas';
$activePage = 'pos_manager_sales';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/pos/gerente/dashboard'], ['Vendas', '']];

include dirname(__DIR__, 2) . '/layouts/top.php';
?>

<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h1 class="h3 mb-0"><i class="bi bi-receipt"></i> Histórico de Vendas</h1>
        <span class="badge bg-info text-dark">Portal Gerente</span>
    </div>

    <?php if ($erro): ?>
    <div class="alert alert-danger"><?= htmlspecialchars($erro) ?></div>
    <?php endif; ?>

    <div class="card mb-3">
        <div class="card-body">
            <form method="get" class="row g-3 align-items-end">
                <div class="col-md-3">
                    <label for="q" class="form-label">Pesquisa</label>
                    <input type="text" class="form-control" id="q" name="q" value="<?= htmlspecialchars($_GET['q'] ?? '') ?>" placeholder="Nº ou referência">
                </div>
                <div class="col-md-2">
                    <label for="status" class="form-label">Estado</label>
                    <select class="form-select" id="status" name="status">
                        <option value="">Todos</option>
                        <option value="concluida" <?= ($_GET['status'] ?? '') === 'concluida' ? 'selected' : '' ?>>Concluída</option>
                        <option value="cancelada" <?= ($_GET['status'] ?? '') === 'cancelada' ? 'selected' : '' ?>>Cancelada</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <label for="data_inicio" class="form-label">De</label>
                    <input type="date" class="form-control" id="data_inicio" name="data_inicio" value="<?= htmlspecialchars($_GET['data_inicio'] ?? '') ?>">
                </div>
                <div class="col-md-2">
                    <label for="data_fim" class="form-label">Até</label>
                    <input type="date" class="form-control" id="data_fim" name="data_fim" value="<?= htmlspecialchars($_GET['data_fim'] ?? '') ?>">
                </div>
                <div class="col-md-3">
                    <button type="submit" class="btn btn-primary">Filtrar</button>
                    <a href="<?= htmlspecialchars($app->routes->path('pos_manager_sales')) ?>" class="btn btn-secondary">Limpar</a>
                </div>
            </form>
        </div>
    </div>

    <div class="card">
        <div class="card-body">
            <div class="table-responsive">
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th>Nº</th>
                            <th>Data</th>
                            <th>Terminal</th>
                            <th>Operador</th>
                            <th>Total</th>
                            <th>Estado</th>
                            <th>Acções</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php if (empty($vendas)): ?>
                        <tr><td colspan="7" class="text-muted text-center">Nenhuma venda encontrada.</td></tr>
                    <?php else: ?>
                        <?php foreach ($vendas as $v): ?>
                        <tr>
                            <td class="fw-bold"><?= htmlspecialchars($v['numero'] ?? ('#' . $v['id'])) ?></td>
                            <td><?= !empty($v['sold_at']) ? date('d/m/Y H:i', strtotime($v['sold_at'])) : (!empty($v['created_at']) ? date('d/m/Y H:i', strtotime($v['created_at'])) : '—') ?></td>
                            <td><?= htmlspecialchars($v['terminal_nome'] ?? ($v['terminal_id'] ? '#' . $v['terminal_id'] : '—')) ?></td>
                            <td><?= htmlspecialchars($v['operador_nome'] ?? ($v['created_by'] ? '#' . $v['created_by'] : '—')) ?></td>
                            <td><?= number_format((float) ($v['total'] ?? 0), 2) ?> MZN</td>
                            <td>
                                <?php $estado = $v['status'] ?? 'concluida'; ?>
                                <span class="badge <?= $estado === 'cancelada' ? 'bg-danger' : ($estado === 'concluida' ? 'bg-success' : 'bg-warning text-dark') ?>">
                                    <?= ucfirst($estado) ?>
                                </span>
                            </td>
                            <td>
                                <a href="<?= htmlspecialchars($app->routes->path('pos_manager_sale_view', ['id' => $v['id']])) ?>" class="btn btn-sm btn-outline-primary">Ver</a>
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
