<?php

if (!$app->session->canModule('pos')) {
    header('Location: /nexora');
    exit;
}

$id = $_GET['id'] ?? '';
$erro = null;
$sucesso = null;
$sessao = null;
$resumo = null;
$movimentos = [];

if ($id === '') {
    header('Location: ' . $app->routes->path('pos_sessoes'));
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['acao']) && $_POST['acao'] === 'movimento') {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');

        $app->payCoreCashDrawer->addMovement($id, [
            'type' => $_POST['type'] ?? '',
            'amount' => (float) ($_POST['amount'] ?? 0),
            'description' => $_POST['description'] ?? '',
        ]);

        $sucesso = 'Movimento registado com sucesso.';
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

try {
    $sessao = $app->payCoreCashDrawer->get($id);
    $resumo = $app->payCoreCashDrawer->summary($id);
    $movimentos = $app->payCoreCashDrawer->movements($id);
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

$pageTitle  = 'Detalhe da Sessão';
$activePage = 'pos_sessa_detalhe';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/nexora/pos'], ['Sessões de Caixa', '/nexora/pos/sessoes'], ['Detalhe', '']];
$csrf       = $app->security->csrfToken();

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Detalhe da Sessão</h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('pos_sessoes')) ?>" class="adm-btn adm-btn-outline">
            <i class="fa-solid fa-arrow-left"></i> Voltar
        </a>
        <?php if ($sessao !== null && ($sessao['status'] ?? '') === 'OPEN'): ?>
        <a href="<?= htmlspecialchars($app->routes->path('pos_sessa_fecho', ['id' => $id])) ?>" class="adm-btn adm-btn-primary">
            <i class="fa-solid fa-lock"></i> Fechar caixa
        </a>
        <?php endif; ?>
    </div>
</div>

<?php if ($erro): ?>
<div class="adm-alert adm-alert--error" style="margin-bottom:var(--adm-sp-5)">
    <i class="fa-solid fa-circle-exclamation"></i>
    <span><?= htmlspecialchars($erro) ?></span>
</div>
<?php endif; ?>

<?php if ($sucesso): ?>
<div class="adm-alert adm-alert--success" style="margin-bottom:var(--adm-sp-5)">
    <i class="fa-solid fa-check-circle"></i>
    <span><?= htmlspecialchars($sucesso) ?></span>
</div>
<?php endif; ?>

<?php if ($sessao !== null && $resumo !== null): ?>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--adm-sp-6);align-items:start;margin-bottom:var(--adm-sp-6)">
    <div class="adm-card">
        <div class="adm-card-header">
            <h2 class="adm-card-title">Informações da sessão</h2>
        </div>
        <div class="adm-card-body">
            <div class="adm-detail-grid" style="grid-template-columns:1fr 1fr;gap:var(--adm-sp-4)">
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Operador</span>
                    <span class="adm-detail-pair-value"><?= htmlspecialchars($sessao['opened_by_name'] ?? '—') ?></span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Estado</span>
                    <span class="adm-detail-pair-value">
                        <?php if (($sessao['status'] ?? '') === 'OPEN'): ?>
                        <span class="adm-badge adm-badge--green">Aberta</span>
                        <?php else: ?>
                        <span class="adm-badge adm-badge--gray">Fechada</span>
                        <?php endif; ?>
                    </span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Abertura</span>
                    <span class="adm-detail-pair-value"><?= !empty($sessao['opened_at']) ? date('d/m/Y H:i', strtotime($sessao['opened_at'])) : '—' ?></span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Fecho</span>
                    <span class="adm-detail-pair-value"><?= !empty($sessao['closed_at']) ? date('d/m/Y H:i', strtotime($sessao['closed_at'])) : '—' ?></span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Valor inicial</span>
                    <span class="adm-detail-pair-value"><?= number_format((float) ($sessao['initial_amount'] ?? 0), 2) ?> MZN</span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Diferença</span>
                    <span class="adm-detail-pair-value <?= ($sessao['difference'] ?? 0) < 0 ? 'adm-text-red' : (($sessao['difference'] ?? 0) > 0 ? 'adm-text-green' : '') ?>">
                        <?= isset($sessao['difference']) ? (($sessao['difference'] > 0 ? '+' : '') . number_format((float) $sessao['difference'], 2) . ' MZN') : '—' ?>
                    </span>
                </div>
            </div>
        </div>
    </div>

    <div class="adm-card">
        <div class="adm-card-header">
            <h2 class="adm-card-title">Resumo financeiro</h2>
        </div>
        <div class="adm-card-body">
            <div class="adm-detail-grid" style="grid-template-columns:1fr 1fr;gap:var(--adm-sp-4)">
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Total entradas</span>
                    <span class="adm-detail-pair-value adm-text-green">+<?= number_format((float) ($resumo['summary']['totalInflows'] ?? 0), 2) ?> MZN</span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Total saídas</span>
                    <span class="adm-detail-pair-value adm-text-red">-<?= number_format((float) ($resumo['summary']['totalOutflows'] ?? 0), 2) ?> MZN</span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Saldo esperado</span>
                    <span class="adm-detail-pair-value adm-fw-700"><?= number_format((float) ($resumo['summary']['expectedBalance'] ?? 0), 2) ?> MZN</span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Valor final</span>
                    <span class="adm-detail-pair-value"><?= ($sessao['final_amount'] !== null) ? number_format((float) $sessao['final_amount'], 2) . ' MZN' : '—' ?></span>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="adm-card" style="margin-bottom:var(--adm-sp-6)">
    <div class="adm-card-header" style="justify-content:space-between">
        <h2 class="adm-card-title">Movimentações</h2>
        <?php if (($sessao['status'] ?? '') === 'OPEN'): ?>
        <button type="button" class="adm-btn adm-btn-primary adm-btn-sm" onclick="document.getElementById('movimentoModal').classList.add('open')">
            <i class="fa-solid fa-plus"></i> Registar movimento
        </button>
        <?php endif; ?>
    </div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($movimentos)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Tipo</th>
                        <th>Valor</th>
                        <th>Descrição</th>
                        <th>Data</th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($movimentos as $m): ?>
                    <tr>
                        <td>
                            <?php if (($m['type'] ?? '') === 'INFLOW'): ?>
                            <span class="adm-badge adm-badge--green">Entrada</span>
                            <?php elseif (($m['type'] ?? '') === 'OUTFLOW'): ?>
                            <span class="adm-badge adm-badge--red">Saída</span>
                            <?php else: ?>
                            <span class="adm-badge adm-badge--gray"><?= htmlspecialchars($m['type'] ?? '—') ?></span>
                            <?php endif; ?>
                        </td>
                        <td class="adm-fw-600"><?= number_format((float) ($m['amount'] ?? 0), 2) ?> MZN</td>
                        <td><?= htmlspecialchars($m['description'] ?? '—') ?></td>
                        <td class="adm-text-muted"><?= !empty($m['created_at']) ? date('d/m/Y H:i', strtotime($m['created_at'])) : '—' ?></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-8)">
            <p class="adm-empty-title">Sem movimentações</p>
            <p class="adm-empty-sub">Não foram registadas movimentações manuais nesta sessão.</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<?php if (($sessao['status'] ?? '') === 'OPEN'): ?>
<!-- Modal de movimento -->
<div class="adm-modal-overlay" id="movimentoModal">
    <div class="adm-modal-content">
        <div class="adm-modal-header">
            <h3>Registar movimento</h3>
            <button type="button" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" onclick="document.getElementById('movimentoModal').classList.remove('open')">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>
        <form method="post" action="">
            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
            <input type="hidden" name="acao" value="movimento">

            <div class="adm-form-group">
                <label class="adm-label" for="type">Tipo</label>
                <select id="type" name="type" class="adm-select" required>
                    <option value="INFLOW">Entrada (suprimento)</option>
                    <option value="OUTFLOW">Saída (sangria)</option>
                </select>
            </div>

            <div class="adm-form-group">
                <label class="adm-label" for="amount">Valor (MZN)</label>
                <input type="number" id="amount" name="amount" class="adm-input" step="0.01" min="0.01" required>
            </div>

            <div class="adm-form-group">
                <label class="adm-label" for="description">Descrição</label>
                <textarea id="description" name="description" class="adm-textarea" rows="2" required placeholder="Ex.: Sangria para depósito bancário"></textarea>
            </div>

            <div class="adm-modal-footer">
                <button type="button" class="adm-btn adm-btn-outline" onclick="document.getElementById('movimentoModal').classList.remove('open')">Cancelar</button>
                <button type="submit" class="adm-btn adm-btn-primary">Registar</button>
            </div>
        </form>
    </div>
</div>
<?php endif; ?>

<?php endif; ?>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
