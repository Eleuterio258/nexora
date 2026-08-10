<?php

if (!$app->session->canModule('pos')) {
    header('Location: /nexora');
    exit;
}

$erro = null;
$sucesso = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');

        $sessao = $app->payCoreCashDrawer->open([
            'terminalId' => $_POST['terminal_id'] ?? null,
            'initialAmount' => (float) ($_POST['initial_amount'] ?? 0),
            'observations' => $_POST['observations'] ?? null,
        ]);

        $sucesso = 'Sessão de caixa aberta com sucesso.';
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

$pageTitle  = 'Abrir Sessão de Caixa';
$activePage = 'pos_sessa_abrir';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/nexora/pos'], ['Sessões de Caixa', '/nexora/pos/sessoes'], ['Abrir', '']];
$csrf       = $app->security->csrfToken();

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Abrir Sessão de Caixa</h1>
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
    <a href="/nexora/pos" class="adm-btn adm-btn-outline">Ir para o POS</a>
</div>
<?php else: ?>

<div class="adm-card" style="max-width:560px">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Dados de abertura</h2>
    </div>
    <div class="adm-card-body">
        <form method="post" action="">
            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">

            <div class="adm-form-group">
                <label class="adm-label" for="terminal_id">Terminal</label>
                <input type="text" id="terminal_id" name="terminal_id" class="adm-input" placeholder="ID do terminal (opcional)">
                <p class="adm-input-hint">Deixe em branco para usar o terminal por omissão.</p>
            </div>

            <div class="adm-form-group">
                <label class="adm-label" for="initial_amount">Valor inicial em caixa (MZN)</label>
                <input type="number" id="initial_amount" name="initial_amount" class="adm-input" step="0.01" min="0" value="0.00" required>
            </div>

            <div class="adm-form-group">
                <label class="adm-label" for="observations">Observações</label>
                <textarea id="observations" name="observations" class="adm-textarea" rows="3" placeholder="Ex.: Abertura turno da manhã"></textarea>
            </div>

            <div class="adm-flex-end">
                <button type="submit" class="adm-btn adm-btn-primary">
                    <i class="fa-solid fa-lock-open"></i> Abrir caixa
                </button>
            </div>
        </form>
    </div>
</div>

<?php endif; ?>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
