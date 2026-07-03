<?php
declare(strict_types=1);
$_rh        = include dirname(__DIR__) . '/partials/rh_resources.php';
$pageTitle  = 'Critérios de Avaliação';
$activePage = 'rh_criterios_avaliacao';
$breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Critérios de Avaliação', '']];
$workspace  = [
    'title'     => 'Critérios de Avaliação',
    'subtitle'  => 'Indicadores e pesos usados nas avaliações de desempenho.',
    'endpoint'  => '/nexora/api/rh_operacao',
    'resources' => ['criterios_avaliacao' => $_rh['criterios_avaliacao']],
];
include dirname(__DIR__) . '/partials/operational_workspace.php';
