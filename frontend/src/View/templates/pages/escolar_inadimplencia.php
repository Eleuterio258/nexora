<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Inadimplência';
$activePage = 'escolar_inadimplencia';
$breadcrumb = [['Admin', '/nexora/'], ['Gestão Escolar', '/nexora/gestao-escolar'], ['Inadimplência', '']];

$workspace = [
    'title'     => 'Inadimplência',
    'subtitle'  => 'Alunos com cobranças em atraso.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['delinquency' => $_escolar['delinquency']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';