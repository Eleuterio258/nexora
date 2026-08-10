<?php

declare(strict_types=1);

if (!$app->session->canModule('autorizacao')) {
    header('Location: /nexora');
    exit;
}

$id = $_GET['id'] ?? '';
$isEdit = $id !== '';
$terminal = null;
$erro = null;
$sucesso = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');

        $data = [
            'serial_number' => $_POST['serial_number'] ?? '',
            'name' => $_POST['name'] ?? '',
            'description' => $_POST['description'] ?? null,
            'model' => $_POST['model'] ?? null,
            'manufacturer' => $_POST['manufacturer'] ?? null,
        ];

        if ($isEdit) {
            $app->payCoreTerminalAdmin->update($id, $data);
            $sucesso = 'Terminal actualizado com sucesso.';
        } else {
            $novo = $app->payCoreTerminalAdmin->create($data);
            $id = $novo['id'] ?? '';
            $isEdit = $id !== '';
            $sucesso = 'Terminal criado com sucesso.';
        }
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

try {
    if ($isEdit) {
        $terminal = $app->payCoreTerminalAdmin->get($id);
    }
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

if ($isEdit && $terminal === null) {
    header('Location: ' . $app->routes->path('terminais_admin'));
    exit;
}

$pageTitle  = $isEdit ? 'Editar Terminal' : 'Novo Terminal';
$activePage = 'terminais_admin';
$breadcrumb = [['Admin', '/nexora/'], ['Terminais POS', '/nexora/admin/terminais'], [$pageTitle, '']];
$csrf       = $app->security->csrfToken();

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title"><?= $pageTitle ?></h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('terminais_admin')) ?>" class="adm-btn adm-btn-outline">
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
<?php endif; ?>

<div class="adm-card" style="max-width:560px">
    <div class="adm-card-body">
        <form method="post" action="">
            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">

            <div class="adm-form-group">
                <label class="adm-label" for="serial_number">Número de série <span class="adm-text-red">*</span></label>
                <input type="text" id="serial_number" name="serial_number" class="adm-input" value="<?= htmlspecialchars($terminal['serialNumber'] ?? '') ?>" <?= $isEdit ? 'readonly' : 'required' ?>>
                <?php if ($isEdit): ?><p class="adm-input-hint">O numero de serie nao pode ser alterado.</p><?php endif; ?>
            </div>

            <div class="adm-form-group">
                <label class="adm-label" for="name">Nome <span class="adm-text-red">*</span></label>
                <input type="text" id="name" name="name" class="adm-input" value="<?= htmlspecialchars($terminal['name'] ?? '') ?>" required>
            </div>

            <div class="adm-form-row" style="grid-template-columns:1fr 1fr">
                <div class="adm-form-group">
                    <label class="adm-label" for="model">Modelo</label>
                    <input type="text" id="model" name="model" class="adm-input" value="<?= htmlspecialchars($terminal['model'] ?? '') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="manufacturer">Fabricante</label>
                    <input type="text" id="manufacturer" name="manufacturer" class="adm-input" value="<?= htmlspecialchars($terminal['manufacturer'] ?? '') ?>">
                </div>
            </div>

            <div class="adm-form-group">
                <label class="adm-label" for="description">Descrição</label>
                <textarea id="description" name="description" class="adm-textarea" rows="2"><?= htmlspecialchars($terminal['description'] ?? '') ?></textarea>
            </div>

            <div class="adm-flex-end">
                <a href="<?= htmlspecialchars($app->routes->path('terminais_admin')) ?>" class="adm-btn adm-btn-outline">Cancelar</a>
                <button type="submit" class="adm-btn adm-btn-primary">
                    <i class="fa-solid fa-save"></i> Guardar
                </button>
            </div>
        </form>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
