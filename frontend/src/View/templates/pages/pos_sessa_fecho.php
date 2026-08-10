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

if ($id === '') {
    header('Location: ' . $app->routes->path('pos_sessoes'));
    exit;
}

try {
    $sessao = $app->payCoreCashDrawer->get($id);
    $resumo = $app->payCoreCashDrawer->summary($id);
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && $sessao !== null) {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');

        $finalAmount = (float) ($_POST['final_amount'] ?? 0);
        $expected = (float) ($resumo['summary']['expectedBalance'] ?? 0);
        $diferenca = $finalAmount - $expected;
        $justificativa = trim($_POST['justificativa'] ?? '');

        if ($diferenca !== 0.0 && $justificativa === '') {
            throw new \E258Tech\Model\Exception\OperationException('É obrigatória uma justificativa quando há diferença de valores.');
        }

        $app->payCoreCashDrawer->close($id, [
            'finalAmount' => $finalAmount,
            'observations' => $justificativa !== '' ? "Diferença: " . number_format($diferenca, 2) . " MZN. " . $justificativa : ($_POST['observations'] ?? null),
        ]);

        $sucesso = 'Sessão de caixa fechada com sucesso.';
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

$pageTitle  = 'Fechar Sessão de Caixa';
$activePage = 'pos_sessa_fecho';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/nexora/pos'], ['Sessões de Caixa', '/nexora/pos/sessoes'], ['Fechar', '']];
$csrf       = $app->security->csrfToken();

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Fechar Sessão de Caixa</h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('pos_sessoes')) ?>" class="adm-btn adm-btn-outline">
            <i class="fa-solid fa-arrow-left"></i> Voltar
        </a>
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
<div style="margin-bottom:var(--adm-sp-6)">
    <a href="<?= htmlspecialchars($app->routes->path('pos_sessoes')) ?>" class="adm-btn adm-btn-primary">Ver sessões</a>
</div>
<?php elseif ($sessao !== null && $resumo !== null): ?>

<div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--adm-sp-6);align-items:start;margin-bottom:var(--adm-sp-6)">
    <div class="adm-card">
        <div class="adm-card-header">
            <h2 class="adm-card-title">Resumo financeiro</h2>
        </div>
        <div class="adm-card-body">
            <div class="adm-detail-grid" style="grid-template-columns:1fr 1fr;gap:var(--adm-sp-4)">
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Valor inicial</span>
                    <span class="adm-detail-pair-value"><?= number_format((float) ($sessao['initial_amount'] ?? 0), 2) ?> MZN</span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Total entradas</span>
                    <span class="adm-detail-pair-value adm-text-green">+<?= number_format((float) ($resumo['summary']['totalInflows'] ?? 0), 2) ?> MZN</span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Total saídas</span>
                    <span class="adm-detail-pair-value adm-text-red">-<?= number_format((float) ($resumo['summary']['totalOutflows'] ?? 0), 2) ?> MZN</span>
                </div>
                <div class="adm-detail-pair">
                    <span class="adm-detail-pair-label">Valor esperado</span>
                    <span class="adm-detail-pair-value adm-fw-700"><?= number_format((float) ($resumo['summary']['expectedBalance'] ?? 0), 2) ?> MZN</span>
                </div>
            </div>
        </div>
    </div>

    <div class="adm-card">
        <div class="adm-card-header">
            <h2 class="adm-card-title">Contagem final</h2>
        </div>
        <div class="adm-card-body">
            <form method="post" action="" id="fechoForm">
                <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">

                <div class="adm-form-group">
                    <label class="adm-label" for="final_amount">Valor contado (MZN)</label>
                    <input type="number" id="final_amount" name="final_amount" class="adm-input" step="0.01" min="0" value="<?= number_format((float) ($resumo['summary']['expectedBalance'] ?? 0), 2) ?>" required>
                </div>

                <div class="adm-form-group" id="justificativaGroup" style="display:none">
                    <label class="adm-label" for="justificativa">Justificativa da diferença</label>
                    <textarea id="justificativa" name="justificativa" class="adm-textarea" rows="3"></textarea>
                    <p class="adm-input-hint">Obrigatória quando o valor contado difere do esperado.</p>
                </div>

                <div class="adm-form-group">
                    <label class="adm-label" for="observations">Observações gerais</label>
                    <textarea id="observations" name="observations" class="adm-textarea" rows="2"></textarea>
                </div>

                <div class="adm-flex-end">
                    <button type="submit" class="adm-btn adm-btn-primary">
                        <i class="fa-solid fa-lock"></i> Fechar caixa
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
(function() {
    const expected = <?= (float) ($resumo['summary']['expectedBalance'] ?? 0) ?>;
    const finalInput = document.getElementById('final_amount');
    const justGroup = document.getElementById('justificativaGroup');

    function checkDifference() {
        const final = parseFloat(finalInput.value) || 0;
        const diff = Math.round((final - expected) * 100) / 100;
        justGroup.style.display = diff !== 0 ? 'block' : 'none';
    }

    finalInput.addEventListener('input', checkDifference);
    checkDifference();
})();
</script>

<?php endif; ?>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
