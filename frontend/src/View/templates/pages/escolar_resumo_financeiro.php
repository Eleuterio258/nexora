<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Resumo Financeiro';
$activePage = 'escolar_resumo_financeiro';
$breadcrumb = $app->routes->escolarBreadcrumb([['Resumo Financeiro', '']]);

$workspace = [
    'title'     => 'Resumo Financeiro',
    'subtitle'  => 'Indicadores financeiros escolares.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['financial_report' => $_escolar['financial_report']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';