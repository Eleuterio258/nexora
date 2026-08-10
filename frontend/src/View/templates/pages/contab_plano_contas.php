<?php

declare(strict_types=1);

if (!$app->session->canModule('contabilidade')) {
    header('Location: /nexora');
    exit;
}

$pageTitle  = 'Plano de Contas';
$activePage = 'contab_plano_contas';
$breadcrumb = [['Admin', '/nexora/'], ['Contabilidade', ''], ['Plano de Contas', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Plano de Contas</h1>
</div>

<div class="adm-card" style="max-width:640px">
    <div class="adm-card-body" style="text-align:center;padding:var(--adm-sp-12)">
        <i class="fa-solid fa-book" style="font-size:3rem;color:var(--adm-gray-300);margin-bottom:var(--adm-sp-4)"></i>
        <h2 class="adm-empty-title">Contabilidade nao disponivel</h2>
        <p class="adm-text-sm adm-text-muted" style="margin-bottom:var(--adm-sp-6)">
            O backend PayCore ainda nao possui modulos de contabilidade (plano de contas, lancamentos, balancetes, ativos fixos, etc.).
        </p>
    </div>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
