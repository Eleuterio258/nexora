<?php

declare(strict_types=1);

if (!$app->session->canModule('autorizacao')) {
    header('Location: /nexora');
    exit;
}

$erro = null;
$sucesso = null;
$terminais = [];
$stats = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['acao']) && $_POST['acao'] === 'eliminar') {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');
        $app->payCoreTerminalAdmin->delete($_POST['id'] ?? '');
        $sucesso = 'Terminal removido com sucesso.';
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['acao']) && $_POST['acao'] === 'status') {
    try {
        $app->security->validateCsrf($_POST['csrf_token'] ?? '');
        $app->payCoreTerminalAdmin->updateStatus($_POST['id'] ?? '', $_POST['status'] ?? '');
        $sucesso = 'Estado do terminal actualizado.';
    } catch (\Throwable $e) {
        $erro = $e->getMessage();
    }
}

$filtroStatus = $_GET['status'] ?? '';

try {
    $query = [];
    if ($filtroStatus !== '') {
        $query['status'] = $filtroStatus;
    }
    $terminais = $app->payCoreTerminalAdmin->list($query);
    $stats = $app->payCoreTerminalAdmin->stats();
} catch (\Throwable $e) {
    $erro = $e->getMessage();
}

$pageTitle  = 'Terminais POS';
$activePage = 'terminais_admin';
$breadcrumb = [['Admin', '/nexora/'], ['Terminais POS', '']];
$csrf       = $app->security->csrfToken();

$statusLabel = static fn(string $status): string => match ($status) {
    'ACTIVE' => 'Activo',
    'INACTIVE' => 'Inactivo',
    'BLOCKED' => 'Bloqueado',
    'MAINTENANCE' => 'Manutencao',
    'OFFLINE' => 'Offline',
    default => $status,
};

$statusBadge = static fn(string $status): string => match ($status) {
    'ACTIVE' => 'adm-badge--green',
    'INACTIVE' => 'adm-badge--gray',
    'BLOCKED' => 'adm-badge--red',
    'MAINTENANCE' => 'adm-badge--yellow',
    'OFFLINE' => 'adm-badge--indigo',
    default => 'adm-badge--gray',
};

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Terminais POS</h1>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('terminal_admin_form')) ?>" class="adm-btn adm-btn-primary">
            <i class="fa-solid fa-plus"></i> Novo terminal
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

<?php if (!empty($stats)): ?>
<div class="adm-stats-grid" style="margin-bottom:var(--adm-sp-6)">
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue"><i class="fa-solid fa-desktop" style="font-size:1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= (int) ($stats['total'] ?? 0) ?></div>
            <div class="adm-stat-label">Total</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--green"><i class="fa-solid fa-circle-check" style="font-size:1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= (int) ($stats['byStatus']['ACTIVE'] ?? 0) ?></div>
            <div class="adm-stat-label">Activos</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--gray"><i class="fa-solid fa-circle-pause" style="font-size:1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= (int) ($stats['byStatus']['INACTIVE'] ?? 0) ?></div>
            <div class="adm-stat-label">Inactivos</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--red"><i class="fa-solid fa-ban" style="font-size:1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= (int) ($stats['byStatus']['BLOCKED'] ?? 0) ?></div>
            <div class="adm-stat-label">Bloqueados</div>
        </div>
    </div>
</div>
<?php endif; ?>

<div class="adm-card" style="margin-bottom:var(--adm-sp-6)">
    <div class="adm-card-body">
        <form method="get" action="" class="adm-filter-bar" style="padding:0;background:none;border:none">
            <div class="adm-form-row" style="gap:var(--adm-sp-3);margin:0;align-items:end">
                <div class="adm-form-group" style="margin-bottom:0">
                    <label class="adm-label" for="status">Estado</label>
                    <select id="status" name="status" class="adm-select">
                        <option value="">Todos</option>
                        <option value="ACTIVE" <?= $filtroStatus === 'ACTIVE' ? 'selected' : '' ?>>Activo</option>
                        <option value="INACTIVE" <?= $filtroStatus === 'INACTIVE' ? 'selected' : '' ?>>Inactivo</option>
                        <option value="BLOCKED" <?= $filtroStatus === 'BLOCKED' ? 'selected' : '' ?>>Bloqueado</option>
                        <option value="MAINTENANCE" <?= $filtroStatus === 'MAINTENANCE' ? 'selected' : '' ?>>Manutencao</option>
                        <option value="OFFLINE" <?= $filtroStatus === 'OFFLINE' ? 'selected' : '' ?>>Offline</option>
                    </select>
                </div>
                <button type="submit" class="adm-btn adm-btn-primary">
                    <i class="fa-solid fa-filter"></i> Filtrar
                </button>
                <a href="<?= htmlspecialchars($app->routes->path('terminais_admin')) ?>" class="adm-btn adm-btn-outline">
                    <i class="fa-solid fa-rotate-right"></i>
                </a>
            </div>
        </form>
    </div>
</div>

<div class="adm-card">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Lista de terminais</h2>
    </div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($terminais)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr>
                        <th>Nome</th>
                        <th>Serial</th>
                        <th>Modelo</th>
                        <th>Fabricante</th>
                        <th>Estado</th>
                        <th style="width:160px"></th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($terminais as $t): ?>
                    <tr>
                        <td class="adm-fw-600"><?= htmlspecialchars($t['name'] ?? '—') ?></td>
                        <td class="adm-text-muted"><?= htmlspecialchars($t['serialNumber'] ?? '—') ?></td>
                        <td class="adm-text-muted"><?= htmlspecialchars($t['model'] ?? '—') ?></td>
                        <td class="adm-text-muted"><?= htmlspecialchars($t['manufacturer'] ?? '—') ?></td>
                        <td><span class="adm-badge <?= ($statusBadge)($t['status'] ?? '') ?>"><?= ($statusLabel)($t['status'] ?? '') ?></span></td>
                        <td>
                            <div class="adm-actions">
                                <a href="<?= htmlspecialchars($app->routes->path('terminal_admin_form', ['id' => $t['id'] ?? ''])) ?>" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Editar">
                                    <i class="fa-solid fa-pen"></i>
                                </a>
                                <form method="post" action="" style="display:inline">
                                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
                                    <input type="hidden" name="acao" value="status">
                                    <input type="hidden" name="id" value="<?= htmlspecialchars($t['id'] ?? '') ?>">
                                    <input type="hidden" name="status" value="<?= ($t['status'] ?? '') === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE' ?>">
                                    <button type="submit" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="<?= ($t['status'] ?? '') === 'ACTIVE' ? 'Desactivar' : 'Activar' ?>">
                                        <i class="fa-solid <?= ($t['status'] ?? '') === 'ACTIVE' ? 'fa-pause' : 'fa-play' ?>"></i>
                                    </button>
                                </form>
                                <form method="post" action="" style="display:inline" onsubmit="return confirm('Remover este terminal?')">
                                    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
                                    <input type="hidden" name="acao" value="eliminar">
                                    <input type="hidden" name="id" value="<?= htmlspecialchars($t['id'] ?? '') ?>">
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
            <i class="fa-solid fa-desktop" style="font-size:2rem;opacity:.2"></i>
            <p class="adm-empty-title">Sem terminais</p>
            <p class="adm-empty-sub">Registe o primeiro terminal POS para comecar a vender.</p>
            <a href="<?= htmlspecialchars($app->routes->path('terminal_admin_form')) ?>" class="adm-btn adm-btn-primary">
                <i class="fa-solid fa-plus"></i> Novo terminal
            </a>
        </div>
        <?php endif; ?>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
