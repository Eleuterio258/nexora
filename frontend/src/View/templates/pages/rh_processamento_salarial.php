<?php
declare(strict_types=1);
$_rh        = include dirname(__DIR__) . '/partials/rh_resources.php';
$pageTitle  = 'Processamento Salarial';
$activePage = 'rh_processamento_salarial';
$breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Processamento Salarial', '']];
$workspace  = [
    'title'     => 'Processamento Salarial',
    'subtitle'  => 'Criação, processamento e pagamento de folhas de pagamento mensais.',
    'endpoint'  => '/nexora/api/rh_operacao',
    'resources' => ['folhas_pagamento' => $_rh['folhas_pagamento']],
];
include dirname(__DIR__) . '/partials/operational_workspace.php';
