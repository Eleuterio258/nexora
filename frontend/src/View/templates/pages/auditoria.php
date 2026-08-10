<?php

declare(strict_types=1);

if (!$app->session->canModule('auditoria')) {
    header('Location: /nexora');
    exit;
}

$pageTitle  = 'Auditoria';
$activePage = 'auditoria';
$breadcrumb = [['Admin', '/nexora/'], ['Auditoria', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Auditoria</h1>
</div>

<div class="adm-card" style="max-width:640px">
    <div class="adm-card-body" style="text-align:center;padding:var(--adm-sp-12)">
        <i class="fa-solid fa-clipboard-list" style="font-size:3rem;color:var(--adm-gray-300);margin-bottom:var(--adm-sp-4)"></i>
        <h2 class="adm-empty-title">Logs de auditoria nao disponiveis</h2>
        <p class="adm-text-sm adm-text-muted" style="margin-bottom:var(--adm-sp-6)">
            O backend PayCore ainda nao expoe logs de auditoria. Quando disponivel, este ecra mostrara o historico de accoes dos utilizadores no sistema.
        </p>
        <a href="<?= htmlspecialchars($app->routes->path('utilizadores')) ?>" class="adm-btn adm-btn-outline">
            <i class="fa-solid fa-users"></i> Utilizadores
        </a>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
