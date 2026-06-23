<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Matrículas';
$activePage = 'escolar_matriculas';
$breadcrumb = [['Admin', '/nexora/'], ['Gestão Escolar', '/nexora/gestao-escolar'], ['Matrículas', '']];

$workspace = [
    'title'     => 'Matrículas',
    'subtitle'  => 'Matrículas, transferências e cancelamentos.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['enrollments' => $_escolar['enrollments']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';