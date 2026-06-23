<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Cargos de Alunos';
$activePage = 'escolar_cargos_alunos';
$breadcrumb = [['Admin', '/nexora/'], ['Gestão Escolar', '/nexora/gestao-escolar'], ['Cargos de Alunos', '']];

$workspace = [
    'title'     => 'Cargos de Alunos',
    'subtitle'  => 'Cargos e funções atribuídos a alunos.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['student_roles' => $_escolar['student_roles']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';