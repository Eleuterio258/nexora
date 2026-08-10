<?php

declare(strict_types=1);

if (!$app->session->canModule('seguranca')) {
    header('Location: /nexora');
    exit;
}

$pageTitle  = 'Segurança';
$activePage = 'seguranca';
$breadcrumb = [['Admin', '/nexora/'], ['Segurança', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Segurança</h1>
</div>

<div class="adm-card" style="max-width:640px">
    <div class="adm-card-body" style="text-align:center;padding:var(--adm-sp-12)">
        <i class="fa-solid fa-shield-halved" style="font-size:3rem;color:var(--adm-gray-300);margin-bottom:var(--adm-sp-4)"></i>
        <h2 class="adm-empty-title">Módulo em desenvolvimento</h2>
        <p class="adm-text-sm adm-text-muted" style="margin-bottom:var(--adm-sp-6)">
            O backend PayCore ainda nao expoe endpoints de politicas de seguranca, roles detalhadas nem sessoes activas.
            A gestao de utilizadores ja esta disponivel em <a href="<?= htmlspecialchars($app->routes->path('utilizadores')) ?>">Utilizadores</a>.
        </p>
        <a href="<?= htmlspecialchars($app->routes->path('utilizadores')) ?>" class="adm-btn adm-btn-primary">
            <i class="fa-solid fa-users"></i> Gerir utilizadores
        </a>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
