<?php
declare(strict_types=1);
$_rh        = include dirname(__DIR__) . '/partials/rh_resources.php';
$pageTitle  = 'Componentes Salariais';
$activePage = 'rh_componentes_salariais';
$breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Componentes Salariais', '']];
$workspace  = [
    'title'     => 'Componentes Salariais',
    'subtitle'  => 'Proventos e descontos que compõem a folha de pagamento.',
    'endpoint'  => '/nexora/api/rh_operacao',
    'resources' => ['componentes_salariais' => $_rh['componentes_salariais']],
];
include dirname(__DIR__) . '/partials/operational_workspace.php';
