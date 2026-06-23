<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Cobranças';
$activePage = 'escolar_cobrancas';
$breadcrumb = [['Admin', '/nexora/'], ['Gestão Escolar', '/nexora/gestao-escolar'], ['Cobranças', '']];

$workspace = [
    'title'     => 'Cobranças',
    'subtitle'  => 'Cobranças geradas para alunos.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['student_invoices' => $_escolar['student_invoices']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';