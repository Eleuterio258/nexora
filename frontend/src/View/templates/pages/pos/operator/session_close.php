<?php
declare(strict_types=1);

/**
 * Fechar Sessão de Caixa — Portal Operador
 */

$erro = null;
$sucesso = null;
$sessaoId = (int) ($_GET['id'] ?? 0);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');
        $app->pos->closeSession($sessaoId, [
            'closing_amount_declared' => (float) ($_POST['closing_amount'] ?? 0),
            'observations'            => trim($_POST['observations'] ?? ''),
        ]);
        header('Location: ' . $app->routes->path('pos_operator_terminal'));
        exit;
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

$sessao = null;
if ($sessaoId > 0) {
    try {
        $sessao = $app->pos->getSessao($sessaoId);
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Fechar Sessão de Caixa';
$activePage = 'pos_operator_session_close';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/pos/gerente/dashboard'], ['Fechar Sessão', '']];

include dirname(__DIR__, 2) . '/layouts/top.php';
?>

<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h1 class="h3 mb-0"><i class="bi bi-door-closed"></i> Fechar Sessão de Caixa</h1>
        <span class="badge bg-primary">Portal Operador</span>
    </div>

    <?php if ($erro): ?>
    <div class="alert alert-danger"><?= htmlspecialchars($erro) ?></div>
    <?php endif; ?>

    <div class="card">
        <div class="card-body">
            <?php if (!$sessao): ?>
            <div class="alert alert-warning">Sessão não encontrada.</div>
            <?php else: ?>
            <p class="text-muted">Sessão #<?= (int) $sessao['id'] ?> — Terminal: <?= htmlspecialchars($sessao['terminal_nome'] ?? ('#' . $sessao['terminal_id'])) ?></p>
            <form method="post">
                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
                <div class="mb-3">
                    <label for="closing_amount" class="form-label">Saldo Final (MZN) <span class="text-danger">*</span></label>
                    <input type="number" step="0.01" min="0" class="form-control" id="closing_amount" name="closing_amount" value="<?= number_format((float) ($sessao['opening_amount'] ?? 0), 2, '.', '') ?>" required>
                </div>
                <div class="mb-3">
                    <label for="observations" class="form-label">Observações</label>
                    <textarea class="form-control" id="observations" name="observations" rows="3"></textarea>
                </div>
                <button type="submit" class="btn btn-danger">Fechar Sessão</button>
                <a href="<?= htmlspecialchars($app->routes->path('pos_operator_terminal')) ?>" class="btn btn-secondary">Voltar</a>
            </form>
            <?php endif; ?>
        </div>
    </div>
</div>

<?php include dirname(__DIR__, 2) . '/layouts/bottom.php'; ?>
