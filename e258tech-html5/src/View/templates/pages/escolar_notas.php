<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Notas';
$activePage = 'escolar_notas';
$breadcrumb = [['Admin', '/nexora/'], ['Gestão Escolar', '/nexora/gestao-escolar'], ['Notas', '']];

$workspace = [
    'title'     => 'Notas',
    'subtitle'  => 'Lançamento e correcção de notas.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['grades' => $_escolar['grades']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';