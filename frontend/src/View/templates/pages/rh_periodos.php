<?php
declare(strict_types=1);
$_rh        = include dirname(__DIR__) . '/partials/rh_resources.php';
$pageTitle  = 'Períodos de Avaliação';
$activePage = 'rh_periodos';
$breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Períodos de Avaliação', '']];
$workspace  = [
    'title'     => 'Períodos de Avaliação',
    'subtitle'  => 'Janelas temporais para avaliações de desempenho.',
    'endpoint'  => '/nexora/api/rh_operacao',
    'resources' => ['periodos' => $_rh['periodos']],
];
include dirname(__DIR__) . '/partials/operational_workspace.php';
