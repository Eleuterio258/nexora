<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Inadimplência';
$activePage = 'escolar_inadimplencia';
$breadcrumb = $app->routes->escolarBreadcrumb([['Inadimplência', '']]);

$workspace = [
    'title'     => 'Inadimplência',
    'subtitle'  => 'Alunos com cobranças em atraso.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['delinquency' => $_escolar['delinquency']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';