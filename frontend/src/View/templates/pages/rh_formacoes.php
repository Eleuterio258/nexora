<?php
declare(strict_types=1);
$_rh        = include dirname(__DIR__) . '/partials/rh_resources.php';
$pageTitle  = 'Formações';
$activePage = 'rh_formacoes';
$breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Formações', '']];
$workspace  = [
    'title'     => 'Formações',
    'subtitle'  => 'Catálogo de formações disponíveis para funcionários.',
    'endpoint'  => '/nexora/api/rh_operacao',
    'resources' => ['formacoes' => $_rh['formacoes']],
];
include dirname(__DIR__) . '/partials/operational_workspace.php';
