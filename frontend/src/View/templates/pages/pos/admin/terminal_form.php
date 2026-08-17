<?php
declare(strict_types=1);

/**
 * Formulário de Terminal — Portal Admin
 */

$erro = null;
$sucesso = null;
$terminalId = (int) ($_GET['id'] ?? 0);
$terminal = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');
        $payload = [
            'nome'         => trim($_POST['nome'] ?? ''),
            'warehouse_id' => !empty($_POST['warehouse_id']) ? (int) $_POST['warehouse_id'] : null,
            'caixa_id'     => !empty($_POST['caixa_id']) ? (int) $_POST['caixa_id'] : null,
        ];

        if ($terminalId > 0) {
            $app->pos->updateTerminal($terminalId, $payload);
            header('Location: ' . $app->routes->path('pos_admin_terminals') . '?msg=' . urlencode('Terminal actualizado.'));
            exit;
        }

        $payload['codigo'] = trim($_POST['codigo'] ?? '');
        $payload['activation_code'] = trim($_POST['activation_code'] ?? '') ?: null;
        $result = $app->pos->createTerminal($payload);
        header('Location: ' . $app->routes->path('pos_admin_terminals') . '?msg=' . urlencode('Terminal criado. Código: ' . ($result['activation_code'] ?? '')));
        exit;
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

if ($terminalId > 0) {
    try {
        $terminal = $app->pos->getTerminal($terminalId);
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

$whResp = $app->nexora->call('GET', '/api/stock/warehouses');
$warehouses = is_array($whResp['body'] ?? null)
    ? array_values(array_filter($whResp['body'], 'is_array'))
    : [];
$warehousesAtivos = array_filter($warehouses, static fn ($w) => (bool) ($w['ativo'] ?? false));

$csrf       = $app->security->csrfToken();
$pageTitle  = $terminalId > 0 ? 'Editar Terminal' : 'Novo Terminal';
$activePage = 'pos_admin_terminal_form';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/pos/gerente/dashboard'], ['Terminais', '/pos/admin/terminais'], [$pageTitle, '']];

include dirname(__DIR__, 2) . '/layouts/top.php';
?>

<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h1 class="h3 mb-0"><i class="bi bi-pc-display"></i> <?= htmlspecialchars($pageTitle) ?></h1>
        <span class="badge bg-secondary">Portal Admin</span>
    </div>

    <?php if ($erro): ?>
    <div class="alert alert-danger"><?= htmlspecialchars($erro) ?></div>
    <?php endif; ?>

    <div class="card">
        <div class="card-body">
            <form method="post">
                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">

                <?php if ($terminalId === 0): ?>
                <div class="mb-3">
                    <label for="codigo" class="form-label">Código <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" id="codigo" name="codigo" value="<?= htmlspecialchars($_POST['codigo'] ?? '') ?>" required>
                </div>
                <?php endif; ?>

                <div class="mb-3">
                    <label for="nome" class="form-label">Nome <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" id="nome" name="nome" value="<?= htmlspecialchars($_POST['nome'] ?? ($terminal['nome'] ?? '')) ?>" required>
                </div>
                <div class="mb-3">
                    <label for="warehouse_id" class="form-label">Armazém</label>
                    <select class="form-select" id="warehouse_id" name="warehouse_id">
                        <option value="">— Seleccionar —</option>
                        <?php foreach ($warehousesAtivos as $w): ?>
                        <option value="<?= (int) $w['id'] ?>" <?= (int) ($terminal['warehouse_id'] ?? ($_POST['warehouse_id'] ?? 0)) === (int) $w['id'] ? 'selected' : '' ?>>
                            <?= htmlspecialchars($w['codigo'] . ' - ' . $w['nome']) ?>
                        </option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="mb-3">
                    <label for="caixa_id" class="form-label">Caixa (Tesouraria)</label>
                    <input type="number" class="form-control" id="caixa_id" name="caixa_id" value="<?= htmlspecialchars($_POST['caixa_id'] ?? ($terminal['caixa_id'] ?? '')) ?>">
                </div>

                <?php if ($terminalId === 0): ?>
                <div class="mb-3">
                    <label for="activation_code" class="form-label">Código de activação</label>
                    <input type="text" class="form-control" id="activation_code" name="activation_code" placeholder="Deixe vazio para gerar automaticamente">
                    <div class="form-text">Só é mostrado uma vez após a criação.</div>
                </div>
                <?php endif; ?>

                <button type="submit" class="btn btn-primary">Guardar</button>
                <a href="<?= htmlspecialchars($app->routes->path('pos_admin_terminals')) ?>" class="btn btn-secondary">Voltar</a>
            </form>
        </div>
    </div>
</div>

<?php include dirname(__DIR__, 2) . '/layouts/bottom.php'; ?>
