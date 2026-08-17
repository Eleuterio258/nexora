<?php
declare(strict_types=1);

/**
 * Fecho de Caixa — Portal Gerente
 */

$sessionId = (int) ($_GET['id'] ?? 0);
$erro = null;
$fecho = null;

if ($sessionId > 0) {
    try {
        $fecho = $app->pos->getFechoSessao($sessionId);
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

$pageTitle  = 'Fecho de Caixa';
$activePage = 'pos_manager_cash_closing';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/pos/gerente/dashboard'], ['Relatórios', '/pos/gerente/relatorios'], ['Fecho', '']];

include dirname(__DIR__, 2) . '/layouts/top.php';
?>

<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h1 class="h3 mb-0"><i class="bi bi-cash-stack"></i> Fecho de Caixa</h1>
        <span class="badge bg-info text-dark">Portal Gerente</span>
    </div>

    <?php if ($erro): ?>
    <div class="alert alert-danger"><?= htmlspecialchars($erro) ?></div>
    <?php endif; ?>

    <div class="card">
        <div class="card-body">
            <form method="get" class="row g-3 align-items-end mb-4">
                <div class="col-md-4">
                    <label for="id" class="form-label">Sessão</label>
                    <input type="number" class="form-control" id="id" name="id" value="<?= $sessionId ?>" placeholder="ID da sessão" required>
                </div>
                <div class="col-md-2">
                    <button type="submit" class="btn btn-primary">Ver Resumo</button>
                </div>
            </form>

            <?php if ($fecho): ?>
            <hr>
            <h5>Resumo da Sessão #<?= $sessionId ?></h5>
            <div class="row">
                <div class="col-md-4"><strong>Valor esperado:</strong> <?= number_format((float) ($fecho['valor_esperado'] ?? 0), 2) ?> MZN</div>
                <div class="col-md-4"><strong>Valor declarado:</strong> <?= number_format((float) ($fecho['valor_declarado'] ?? 0), 2) ?> MZN</div>
                <div class="col-md-4"><strong>Diferença:</strong> <?= number_format((float) ($fecho['diferenca'] ?? 0), 2) ?> MZN</div>
            </div>
            <?php endif; ?>
        </div>
    </div>

    <a href="<?= htmlspecialchars($app->routes->path('pos_manager_reports')) ?>" class="btn btn-secondary mt-3">Voltar</a>
</div>

<?php include dirname(__DIR__, 2) . '/layouts/bottom.php'; ?>
