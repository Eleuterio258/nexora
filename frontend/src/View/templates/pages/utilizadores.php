<?php

declare(strict_types=1);

if (!$app->session->canModule('autorizacao')) {
    header('Location: /nexora');
    exit;
}

$erro = null;
$sucesso = null;
$utilizadores = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['acao']) && $_POST['acao'] === 'eliminar') {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');
        $app->payCoreUser->delete($_POST['id'] ?? '');
        $sucesso = 'Utilizador removido com sucesso.';
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

$filtroRole = $_GET['role'] ?? '';

try {
    $utilizadores = $app->payCoreUser->list($filtroRole !== '' ? $filtroRole : null);
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

$pageTitle  = 'Utilizadores';
$activePage = 'utilizadores';
$breadcrumb = [['Admin', '/nexora/'], ['Utilizadores', '']];
$csrf       = $app->security->csrfToken();

$roleLabel = static fn(string $role): string => match ($role) {
    'SUPER_ADMIN' => 'Super Admin',
    'ADMIN' => 'Administrador',
    'OPERADOR' => 'Operador',
    default => $role,
};

$roleBadge = static fn(string $role): string => match ($role) {
    'SUPER_ADMIN' => 'adm-badge--red',
    'ADMIN' => 'adm-badge--blue',
    'OPERADOR' => 'adm-badge--green',
    default => 'adm-badge--gray',
};

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Utilizadores</h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('utilizador_form')) ?>" class="adm-btn adm-btn-primary">
            <i class="fa-solid fa-plus"></i> Novo utilizador
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

<div class="adm-card" style="margin-bottom:var(--adm-sp-6)">
    <div class="adm-card-body">
        <form method="get" action="" class="adm-filter-bar" style="padding:0;background:none;border:none">
            <div class="adm-form-row" style="gap:var(--adm-sp-3);margin:0;align-items:end">
                <div class="adm-form-group" style="margin-bottom:0">
                    <label class="adm-label" for="role">Perfil</label>
                    <select id="role" name="role" class="adm-select">
                        <option value="">Todos</option>
                        <option value="ADMIN" <?= $filtroRole === 'ADMIN' ? 'selected' : '' ?>>Administrador</option>
                        <option value="OPERADOR" <?= $filtroRole === 'OPERADOR' ? 'selected' : '' ?>>Operador</option>
                    </select>
                </div>
                <button type="submit" class="adm-btn adm-btn-primary">
                    <i class="fa-solid fa-filter"></i> Filtrar
                </button>
                <a href="<?= htmlspecialchars($app->routes->path('utilizadores')) ?>" class="adm-btn adm-btn-outline">
                    <i class="fa-solid fa-rotate-right"></i>
                </a>
            </div>
        </form>
    </div>
</div>

<div class="adm-card">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Lista de utilizadores</h2>
    </div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($utilizadores)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Nome</th>
                        <th>Email</th>
                        <th>Perfil</th>
                        <th>Telefone</th>
                        <th>2FA</th>
                        <th>Estado</th>
                        <th style="width:120px"></th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($utilizadores as $u): ?>
                    <tr>
                        <td class="adm-fw-600"><?= htmlspecialchars($u['name'] ?? '—') ?></td>
                        <td class="adm-text-muted"><?= htmlspecialchars($u['email'] ?? '—') ?></td>
                        <td><span class="adm-badge <?= ($roleBadge)($u['role'] ?? '') ?>"><?= ($roleLabel)($u['role'] ?? '') ?></span></td>
                        <td class="adm-text-muted"><?= htmlspecialchars($u['phoneNumber'] ?? '—') ?></td>
                        <td>
                            <?php if (($u['twoFactorEnabled'] ?? false)): ?>
                            <span class="adm-badge adm-badge--green">Activo</span>
                            <?php else: ?>
                            <span class="adm-badge adm-badge--gray">Inactivo</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <?php if (($u['active'] ?? false)): ?>
                            <span class="adm-badge adm-badge--green">Activo</span>
                            <?php else: ?>
                            <span class="adm-badge adm-badge--gray">Inactivo</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <div class="adm-actions">
                                <a href="<?= htmlspecialchars($app->routes->path('utilizador_detalhe', ['id' => $u['id'] ?? ''])) ?>" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Ver detalhes">
                                    <i class="fa-solid fa-eye"></i>
                                </a>
                                <a href="<?= htmlspecialchars($app->routes->path('utilizador_form', ['id' => $u['id'] ?? ''])) ?>" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Editar">
                                    <i class="fa-solid fa-pen"></i>
                                </a>
                                <form method="post" action="" style="display:inline" onsubmit="return confirm('Remover este utilizador?')">
                                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
                                    <input type="hidden" name="acao" value="eliminar">
                                    <input type="hidden" name="id" value="<?= htmlspecialchars($u['id'] ?? '') ?>">
                                    <button type="submit" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Remover">
                                        <i class="fa-solid fa-trash"></i>
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-12)">
            <i class="fa-solid fa-users" style="font-size:2rem;opacity:.2"></i>
            <p class="adm-empty-title">Sem utilizadores</p>
            <p class="adm-empty-sub">Crie o primeiro utilizador para aceder ao sistema.</p>
            <a href="<?= htmlspecialchars($app->routes->path('utilizador_form')) ?>" class="adm-btn adm-btn-primary">
                <i class="fa-solid fa-plus"></i> Novo utilizador
            </a>
        </div>
        <?php endif; ?>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
