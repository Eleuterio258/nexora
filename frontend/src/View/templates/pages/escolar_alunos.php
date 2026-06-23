<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Alunos';
$activePage = 'escolar_alunos';
$breadcrumb = [['Admin', '/nexora/'], ['Gestão Escolar', '/nexora/gestao-escolar'], ['Alunos', '']];

$workspace = [
    'title'     => 'Alunos',
    'subtitle'  => 'Registo e gestão de alunos.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['students' => $_escolar['students']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';