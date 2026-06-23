<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Avaliações';
$activePage = 'escolar_avaliacoes';
$breadcrumb = [['Admin', '/nexora/'], ['Gestão Escolar', '/nexora/gestao-escolar'], ['Avaliações', '']];

$workspace = [
    'title'     => 'Avaliações',
    'subtitle'  => 'Instrumentos de avaliação por turma e disciplina.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['grade_items' => $_escolar['grade_items']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';