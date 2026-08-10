<?php

declare(strict_types=1);

if (!$app->session->canModule('sistema-configuracao')) {
    header('Location: /nexora');
    exit;
}

$pageTitle  = 'Configuração do Sistema';
$activePage = 'sistema_geral';
$breadcrumb = [['Admin', '/nexora/'], ['Configuração', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Configuração do Sistema</h1>
</div>

<div class="adm-card" style="max-width:640px">
    <div class="adm-card-body" style="text-align:center;padding:var(--adm-sp-12)">
        <i class="fa-solid fa-gear" style="font-size:3rem;color:var(--adm-gray-300);margin-bottom:var(--adm-sp-4)"></i>
        <h2 class="adm-empty-title">Configuracoes do tenant</h2>
        <p class="adm-text-sm adm-text-muted" style="margin-bottom:var(--adm-sp-6)">
            O backend PayCore ainda nao expoe endpoints de configuracao geral do tenant (nome da empresa, moeda, impostos, etc.).
            A gestao de terminais POS e utilizadores ja esta disponivel.
        </p>
        <div style="display:flex;gap:var(--adm-sp-3);justify-content:center">
            <a href="<?= htmlspecialchars($app->routes->path('terminais_admin')) ?>" class="adm-btn adm-btn-outline">
                <i class="fa-solid fa-desktop"></i> Terminais
            </a>
            <a href="<?= htmlspecialchars($app->routes->path('utilizadores')) ?>" class="adm-btn adm-btn-primary">
                <i class="fa-solid fa-users"></i> Utilizadores
            </a>
        </div>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
