<?php

declare(strict_types=1);

if (!$app->session->canModule('autorizacao')) {
    header('Location: /nexora');
    exit;
}

$id = $_GET['id'] ?? '';
$isEdit = $id !== '';
$utilizador = null;
$erro = null;
$sucesso = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');

        $data = [
            'name' => $_POST['name'] ?? '',
            'email' => $_POST['email'] ?? '',
            'role' => $_POST['role'] ?? '',
            'active' => isset($_POST['active']),
            'phone_number' => $_POST['phone_number'] ?? null,
            'two_factor_enabled' => isset($_POST['two_factor_enabled']),
        ];

        if (!$isEdit || $_POST['password'] !== '') {
            $data['password'] = $_POST['password'] ?? '';
        }

        if ($isEdit) {
            $app->payCoreUser->update($id, $data);
            $sucesso = 'Utilizador actualizado com sucesso.';
        } else {
            $novo = $app->payCoreUser->create($data);
            $id = $novo['id'] ?? '';
            $isEdit = $id !== '';
            $sucesso = 'Utilizador criado com sucesso.';
        }
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

try {
    if ($isEdit) {
        $utilizador = $app->payCoreUser->get($id);
    }
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

if ($isEdit && $utilizador === null) {
    header('Location: ' . $app->routes->path('utilizadores'));
    exit;
}

$pageTitle  = $isEdit ? 'Editar Utilizador' : 'Novo Utilizador';
$activePage = 'utilizadores';
$breadcrumb = [['Admin', '/nexora/'], ['Utilizadores', '/nexora/admin/utilizadores'], [$pageTitle, '']];
$csrf       = $app->security->csrfToken();

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title"><?= $pageTitle ?></h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('utilizadores')) ?>" class="adm-btn adm-btn-outline">
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
                <label class="adm-label" for="name">Nome <span class="adm-text-red">*</span></label>
                <input type="text" id="name" name="name" class="adm-input" value="<?= htmlspecialchars($utilizador['name'] ?? '') ?>" required>
            </div>

            <div class="adm-form-group">
                <label class="adm-label" for="email">Email <span class="adm-text-red">*</span></label>
                <input type="email" id="email" name="email" class="adm-input" value="<?= htmlspecialchars($utilizador['email'] ?? '') ?>" required>
            </div>

            <div class="adm-form-row" style="grid-template-columns:1fr 1fr">
                <div class="adm-form-group">
                    <label class="adm-label" for="role">Perfil <span class="adm-text-red">*</span></label>
                    <select id="role" name="role" class="adm-select" required>
                        <option value="ADMIN" <?= ($utilizador['role'] ?? '') === 'ADMIN' ? 'selected' : '' ?>>Administrador</option>
                        <option value="OPERADOR" <?= ($utilizador['role'] ?? '') === 'OPERADOR' ? 'selected' : '' ?>>Operador</option>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="phone_number">Telefone</label>
                    <input type="text" id="phone_number" name="phone_number" class="adm-input" value="<?= htmlspecialchars($utilizador['phoneNumber'] ?? '') ?>">
                </div>
            </div>

            <div class="adm-form-group">
                <label class="adm-label" for="password">Palavra-passe <?= $isEdit ? '(deixe em branco para manter)' : '<span class="adm-text-red">*</span>' ?></label>
                <input type="password" id="password" name="password" class="adm-input" <?= $isEdit ? '' : 'required' ?>>
            </div>

            <div class="adm-form-group">
                <label class="adm-label" style="display:flex;align-items:center;gap:var(--adm-sp-2)">
                    <input type="checkbox" name="active" id="active" <?= ($isEdit ? ($utilizador['active'] ?? false) : true) ? 'checked' : '' ?>>
                    Activo
                </label>
            </div>

            <div class="adm-form-group">
                <label class="adm-label" style="display:flex;align-items:center;gap:var(--adm-sp-2)">
                    <input type="checkbox" name="two_factor_enabled" id="two_factor_enabled" <?= ($utilizador['twoFactorEnabled'] ?? false) ? 'checked' : '' ?>>
                    Autenticacao de dois factores
                </label>
            </div>

            <div class="adm-flex-end">
                <a href="<?= htmlspecialchars($app->routes->path('utilizadores')) ?>" class="adm-btn adm-btn-outline">Cancelar</a>
                <button type="submit" class="adm-btn adm-btn-primary">
                    <i class="fa-solid fa-save"></i> Guardar
                </button>
            </div>
        </form>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
