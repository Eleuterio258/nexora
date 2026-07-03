<?php

$resp  = $app->nexora->call('GET', '/api/superadmin/dashboard');
$stats = $resp['body'] ?? [];

$csrf = $app->security->csrfToken();
$pageTitle  = 'Dashboard';
$activePage = 'superadmin_dashboard';
$breadcrumb = [['Nexora', '/nexora/superadmin'], ['Dashboard', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Dashboard Global</h1>
</div>

<div class="adm-grid adm-grid-4">
    <div class="adm-card">
        <div class="adm-stat">
            <div class="adm-stat-label">Total Tenants</div>
            <div class="adm-stat-value"><?= (int) ($stats['total_tenants'] ?? 0) ?></div>
        </div>
    </div>
    <div class="adm-card">
        <div class="adm-stat">
            <div class="adm-stat-label">Tenants Ativos</div>
            <div class="adm-stat-value" style="color:var(--adm-green)"><?= (int) ($stats['tenants_ativos'] ?? 0) ?></div>
        </div>
    </div>
    <div class="adm-card">
        <div class="adm-stat">
            <div class="adm-stat-label">Utilizadores</div>
            <div class="adm-stat-value"><?= (int) ($stats['total_utilizadores'] ?? 0) ?></div>
        </div>
    </div>
    <div class="adm-card">
        <div class="adm-stat">
            <div class="adm-stat-label">Planos Ativos</div>
            <div class="adm-stat-value"><?= (int) ($stats['total_planos'] ?? 0) ?></div>
        </div>
    </div>
</div>

<div class="adm-grid adm-grid-2" style="margin-top:var(--adm-sp-5)">
    <div class="adm-card">
        <div class="adm-card-header">
            <h3 class="adm-card-title">Estado dos Tenants</h3>
        </div>
        <div class="adm-card-body">
            <ul class="adm-list">
                <li>
                    <div class="adm-flex adm-gap-2">
                        <span class="adm-badge adm-badge--green">Ativos</span>
                    </div>
                    <span class="adm-fw-600"><?= (int) ($stats['tenants_ativos'] ?? 0) ?></span>
                </li>
                <li>
                    <div class="adm-flex adm-gap-2">
                        <span class="adm-badge adm-badge--yellow">Suspensos</span>
                    </div>
                    <span class="adm-fw-600"><?= (int) ($stats['tenants_suspensos'] ?? 0) ?></span>
                </li>
                <li>
                    <div class="adm-flex adm-gap-2">
                        <span class="adm-badge adm-badge--gray">Inativos</span>
                    </div>
                    <span class="adm-fw-600"><?= (int) ($stats['tenants_inativos'] ?? 0) ?></span>
                </li>
            </ul>
        </div>
    </div>
    <div class="adm-card">
        <div class="adm-card-header">
            <h3 class="adm-card-title">Atalhos Rápidos</h3>
        </div>
        <div class="adm-card-body" style="display:flex;flex-wrap:wrap;gap:var(--adm-sp-3)">
            <a href="<?= htmlspecialchars($app->routes->path('superadmin_tenants')) ?>" class="adm-btn adm-btn-outline">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2"/></svg>
                Tenants
            </a>
            <a href="<?= htmlspecialchars($app->routes->path('superadmin_plans')) ?>" class="adm-btn adm-btn-outline">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2"/><rect x="9" y="3" width="6" height="4" rx="1"/></svg>
                Planos
            </a>
            <a href="<?= htmlspecialchars($app->routes->path('superadmin_modules')) ?>" class="adm-btn adm-btn-outline">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="6" height="6"/><rect x="16" y="3" width="6" height="6"/><rect x="2" y="15" width="6" height="6"/><rect x="16" y="15" width="6" height="6"/></svg>
                Módulos
            </a>
            <a href="<?= htmlspecialchars($app->routes->path('superadmin_settings')) ?>" class="adm-btn adm-btn-outline">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M12 1v4M12 19v4M4.22 4.22l2.83 2.83M16.95 16.95l2.83 2.83M1 12h4M19 12h4M4.22 19.78l2.83-2.83M16.95 7.05l2.83-2.83"/></svg>
                Configurações
            </a>
        </div>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
