<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Frequência';
$activePage = 'escolar_frequencia';
$breadcrumb = $app->routes->escolarBreadcrumb([['Frequência', '']]);

$workspace = [
    'title'     => 'Frequência',
    'subtitle'  => 'Registo de presenças e faltas.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['attendance' => $_escolar['attendance']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';