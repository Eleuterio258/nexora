<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Planos de Cobrança';
$activePage = 'escolar_planos_cobranca';
$breadcrumb = [['Admin', '/nexora/'], ['Gestão Escolar', '/nexora/gestao-escolar'], ['Planos de Cobrança', '']];

$workspace = [
    'title'     => 'Planos de Cobrança',
    'subtitle'  => 'Planos de propinas e taxas escolares.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['fee_plans' => $_escolar['fee_plans']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';