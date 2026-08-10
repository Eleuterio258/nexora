<?php

declare(strict_types=1);

if (!$app->session->canModule('autorizacao')) {
    header('Location: /nexora');
    exit;
}

$id = $_GET['id'] ?? '';
if ($id === '') {
    header('Location: ' . $app->routes->path('utilizadores'));
    exit;
}

$erro = null;
$utilizador = null;

try {
    $utilizador = $app->payCoreUser->get($id);
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

if ($utilizador === null) {
    header('Location: ' . $app->routes->path('utilizadores'));
    exit;
}

$pageTitle  = 'Detalhe do Utilizador';
$activePage = 'utilizadores';
$breadcrumb = [['Admin', '/nexora/'], ['Utilizadores', '/nexora/admin/utilizadores'], ['Detalhe', '']];

$roleLabel = match ($utilizador['role'] ?? '') {
    'SUPER_ADMIN' => 'Super Admin',
    'ADMIN' => 'Administrador',
    'OPERADOR' => 'Operador',
    default => $utilizador['role'] ?? '—',
};

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title"><?= htmlspecialchars($utilizador['name'] ?? '—') ?></h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('utilizadores')) ?>" class="adm-btn adm-btn-outline">
            <i class="fa-solid fa-arrow-left"></i> Voltar
        </a>
        <a href="<?= htmlspecialchars($app->routes->path('utilizador_form', ['id' => $id])) ?>" class="adm-btn adm-btn-primary">
            <i class="fa-solid fa-pen"></i> Editar
        </a>
    </div>
</div>

<?php if ($erro): ?>
<div class="adm-alert adm-alert--error" style="margin-bottom:var(--adm-sp-5)">
    <i class="fa-solid fa-circle-exclamation"></i>
    <span><?= htmlspecialchars($erro) ?></span>
</div>
<?php endif; ?>

<div class="adm-card" style="max-width:560px">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Informações</h2>
    </div>
    <div class="adm-card-body">
        <div class="adm-detail-pair" style="margin-bottom:var(--adm-sp-3)">
            <span class="adm-detail-pair-label">Email</span>
            <span class="adm-detail-pair-value"><?= htmlspecialchars($utilizador['email'] ?? '—') ?></span>
        </div>
        <div class="adm-detail-pair" style="margin-bottom:var(--adm-sp-3)">
            <span class="adm-detail-pair-label">Perfil</span>
            <span class="adm-detail-pair-value"><span class="adm-badge <?= match($utilizador['role'] ?? '') { 'SUPER_ADMIN' => 'adm-badge--red', 'ADMIN' => 'adm-badge--blue', 'OPERADOR' => 'adm-badge--green', default => 'adm-badge--gray' } ?>"><?= $roleLabel ?></span></span>
        </div>
        <div class="adm-detail-pair" style="margin-bottom:var(--adm-sp-3)">
            <span class="adm-detail-pair-label">Telefone</span>
            <span class="adm-detail-pair-value"><?= htmlspecialchars($utilizador['phoneNumber'] ?? '—') ?></span>
        </div>
        <div class="adm-detail-pair" style="margin-bottom:var(--adm-sp-3)">
            <span class="adm-detail-pair-label">2FA</span>
            <span class="adm-detail-pair-value">
                <?php if (($utilizador['twoFactorEnabled'] ?? false)): ?>
                <span class="adm-badge adm-badge--green">Activo</span>
                <?php else: ?>
                <span class="adm-badge adm-badge--gray">Inactivo</span>
                <?php endif; ?>
            </span>
        </div>
        <div class="adm-detail-pair" style="margin-bottom:0">
            <span class="adm-detail-pair-label">Estado</span>
            <span class="adm-detail-pair-value">
                <?php if (($utilizador['active'] ?? false)): ?>
                <span class="adm-badge adm-badge--green">Activo</span>
                <?php else: ?>
                <span class="adm-badge adm-badge--gray">Inactivo</span>
                <?php endif; ?>
            </span>
        </div>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
