<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Boletins';
$activePage = 'escolar_boletins';
$breadcrumb = [['Admin', '/nexora/'], ['Gestão Escolar', '/nexora/gestao-escolar'], ['Boletins', '']];

$workspace = [
    'title'     => 'Boletins',
    'subtitle'  => 'Boletins académicos por aluno e período.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['report_cards' => $_escolar['report_cards']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';