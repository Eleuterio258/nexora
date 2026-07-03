<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Séries';
$activePage = 'escolar_series';
$breadcrumb = $app->routes->escolarBreadcrumb([['Séries', '']]);

$workspace = [
    'title'     => 'Séries',
    'subtitle'  => 'Séries ou anos dentro de cada nível de ensino.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['series' => $_escolar['series']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
