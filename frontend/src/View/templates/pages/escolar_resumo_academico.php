<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Resumo Académico';
$activePage = 'escolar_resumo_academico';
$breadcrumb = $app->routes->escolarBreadcrumb([['Resumo Académico', '']]);

$workspace = [
    'title'     => 'Resumo Académico',
    'subtitle'  => 'Indicadores académicos consolidados.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['academic_report' => $_escolar['academic_report']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';