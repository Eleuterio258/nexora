<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Disciplinas';
$activePage = 'escolar_disciplinas';
$breadcrumb = $app->routes->escolarBreadcrumb([['Disciplinas', '']]);

$workspace = [
    'title'     => 'Disciplinas',
    'subtitle'  => 'Catálogo de disciplinas lectivas.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['subjects' => $_escolar['subjects']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';