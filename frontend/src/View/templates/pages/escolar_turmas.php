<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Turmas';
$activePage = 'escolar_turmas';
$breadcrumb = [['Admin', '/nexora/'], ['Gestão Escolar', '/nexora/gestao-escolar'], ['Turmas', '']];

$workspace = [
    'title'     => 'Turmas',
    'subtitle'  => 'Gestão de turmas e directores de turma.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['classes' => $_escolar['classes']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';