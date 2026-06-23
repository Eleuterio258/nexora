<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Pagamentos';
$activePage = 'escolar_pagamentos';
$breadcrumb = [['Admin', '/nexora/'], ['Gestão Escolar', '/nexora/gestao-escolar'], ['Pagamentos', '']];

$workspace = [
    'title'     => 'Pagamentos',
    'subtitle'  => 'Registo e consulta de pagamentos.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['payments' => $_escolar['payments']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';