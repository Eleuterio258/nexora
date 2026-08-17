<?php
declare(strict_types=1);

/**
 * Detalhe da Sessão de Caixa — Portal Gerente
 */

$sessionId = (int) ($_GET['id'] ?? 0);
$erro = null;
$sessao = null;
$movimentos = [];

if ($sessionId > 0) {
    try {
        $sessao = $app->pos->getSessao($sessionId);
        $movResp = $app->nexora->call('GET', "/api/pos/sessoes/$sessionId/movimentacoes");
        $movimentos = ($movResp['status'] === 200 && is_array($movResp['body'])) ? $movResp['body'] : [];
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

$pageTitle  = 'Detalhe da Sessão';
$activePage = 'pos_manager_session_view';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/pos/gerente/dashboard'], ['Sessões', '/pos/gerente/sessoes'], ['Detalhe', '']];

include dirname(__DIR__, 2) . '/layouts/top.php';
?>

<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h1 class="h3 mb-0"><i class="bi bi-clock-history"></i> Detalhe da Sessão #<?= $sessionId ?></h1>
        <span class="badge bg-info text-dark">Portal Gerente</span>
    </div>

    <?php if ($erro): ?>
    <div class="alert alert-danger"><?= htmlspecialchars($erro) ?></div>
    <?php endif; ?>

    <?php if ($sessao): ?>
    <div class="row">
        <div class="col-md-6">
            <div class="card mb-3">
                <div class="card-body">
                    <p><strong>Terminal:</strong> <?= htmlspecialchars($sessao['terminal_nome'] ?? ('#' . $sessao['terminal_id'])) ?></p>
                    <p><strong>Operador:</strong> <?= htmlspecialchars($sessao['operador_nome'] ?? ('#' . $sessao['user_id'])) ?></p>
                    <p><strong>Abertura:</strong> <?= !empty($sessao['opened_at']) ? date('d/m/Y H:i', strtotime($sessao['opened_at'])) : '—' ?></p>
                    <p><strong>Fecho:</strong> <?= !empty($sessao['closed_at']) ? date('d/m/Y H:i', strtotime($sessao['closed_at'])) : '—' ?></p>
                    <p><strong>Saldo inicial:</strong> <?= number_format((float) ($sessao['opening_amount'] ?? 0), 2) ?> MZN</p>
                    <p><strong>Saldo final:</strong> <?= isset($sessao['closing_amount']) && $sessao['closing_amount'] !== null ? number_format((float) $sessao['closing_amount'], 2) . ' MZN' : '—' ?></p>
                    <p><strong>Estado:</strong>
                        <span class="badge <?= ($sessao['status'] ?? '') === 'aberta' ? 'bg-success' : 'bg-secondary' ?>">
                            <?= ucfirst($sessao['status'] ?? '—') ?>
                        </span>
                    </p>
                </div>
            </div>
        </div>
        <div class="col-md-6">
            <div class="card">
                <div class="card-header"><strong>Movimentos de Caixa</strong></div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-striped mb-0">
                            <thead>
                                <tr><th>Tipo</th><th>Valor</th><th>Motivo</th><th>Data</th></tr>
                            </thead>
                            <tbody>
                            <?php if (empty($movimentos)): ?>
                                <tr><td colspan="4" class="text-muted text-center">Sem movimentos.</td></tr>
                            <?php else: ?>
                                <?php foreach ($movimentos as $m): ?>
                                <tr>
                                    <td><?= ucfirst($m['tipo'] ?? '—') ?></td>
                                    <td><?= number_format((float) ($m['valor'] ?? 0), 2) ?> MZN</td>
                                    <td><?= htmlspecialchars($m['motivo'] ?? '—') ?></td>
                                    <td><?= !empty($m['created_at']) ? date('d/m/Y H:i', strtotime($m['created_at'])) : '—' ?></td>
                                </tr>
                                <?php endforeach; ?>
                            <?php endif; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <?php endif; ?>

    <a href="<?= htmlspecialchars($app->routes->path('pos_manager_sessions')) ?>" class="btn btn-secondary mt-3">Voltar</a>
</div>

<?php include dirname(__DIR__, 2) . '/layouts/bottom.php'; ?>
