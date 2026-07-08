<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Períodos Lectivos';
$activePage = 'escolar_periodos';
$breadcrumb = $app->routes->escolarBreadcrumb([['Períodos Lectivos', '']]);

$workspace = [
    'title'     => 'Períodos Lectivos',
    'subtitle'  => 'Gerir trimestres, semestres, módulos e outros períodos de avaliação de forma livre.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['terms' => $_escolar['terms']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
