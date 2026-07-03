<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Anos Lectivos';
$activePage = 'escolar_anos_lectivos';
$breadcrumb = $app->routes->escolarBreadcrumb([['Anos Lectivos', '']]);

$workspace = [
    'title'     => 'Anos Lectivos',
    'subtitle'  => 'Gestão dos anos e períodos lectivos.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['years' => $_escolar['years']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';