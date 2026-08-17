<?php
declare(strict_types=1);

/**
 * Abrir Sessão de Caixa — Portal Operador
 */

$erro = null;
$sucesso = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');
        $app->pos->openSession([
            'terminal_id'    => (int) ($_POST['terminal_id'] ?? 0),
            'opening_amount' => (float) ($_POST['opening_amount'] ?? 0),
            'observations'   => trim($_POST['observations'] ?? ''),
        ]);
        header('Location: ' . $app->routes->path('pos_operator_terminal'));
        exit;
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

$terminaisResp = $app->nexora->call('GET', '/api/pos/terminais', null, ['ativo' => 'true']);
$terminais = ($terminaisResp['status'] === 200 && is_array($terminaisResp['body'])) ? $terminaisResp['body'] : [];
$terminaisAtivos = array_filter($terminais, static fn ($t) => (bool) ($t['activo'] ?? false));

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Abrir Sessão de Caixa';
$activePage = 'pos_operator_session_open';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/pos/gerente/dashboard'], ['Abrir Sessão', '']];

include dirname(__DIR__, 2) . '/layouts/top.php';
?>

<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h1 class="h3 mb-0"><i class="bi bi-door-open"></i> Abrir Sessão de Caixa</h1>
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
            <?php if (empty($terminaisAtivos)): ?>
            <div class="alert alert-warning">
                Nenhum terminal activo. <a href="<?= htmlspecialchars($app->routes->path('pos_admin_terminals')) ?>">Criar terminal →</a>
            </div>
            <?php else: ?>
            <form method="post">
                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
                <div class="mb-3">
                    <label for="terminal_id" class="form-label">Terminal <span class="text-danger">*</span></label>
                    <select class="form-select" id="terminal_id" name="terminal_id" required>
                        <option value="">— Seleccionar —</option>
                        <?php foreach ($terminaisAtivos as $t): ?>
                        <option value="<?= (int) $t['id'] ?>"><?= htmlspecialchars($t['codigo'] . ' — ' . $t['nome']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="mb-3">
                    <label for="opening_amount" class="form-label">Saldo Inicial (MZN) <span class="text-danger">*</span></label>
                    <input type="number" step="0.01" min="0" class="form-control" id="opening_amount" name="opening_amount" value="0.00" required>
                </div>
                <div class="mb-3">
                    <label for="observations" class="form-label">Observações</label>
                    <textarea class="form-control" id="observations" name="observations" rows="3"></textarea>
                </div>
                <button type="submit" class="btn btn-primary">Abrir Sessão</button>
                <a href="<?= htmlspecialchars($app->routes->path('pos_operator_terminal')) ?>" class="btn btn-secondary">Voltar</a>
            </form>
            <?php endif; ?>
        </div>
    </div>
</div>

<?php include dirname(__DIR__, 2) . '/layouts/bottom.php'; ?>
