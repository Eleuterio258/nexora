<?php
declare(strict_types=1);
$_rh        = include dirname(__DIR__) . '/partials/rh_resources.php';
$pageTitle  = 'Tipos de Ausência';
$activePage = 'rh_tipos_ausencia';
$breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Tipos de Ausência', '']];
$workspace  = [
    'title'     => 'Tipos de Ausência',
    'subtitle'  => 'Férias, licenças, faltas justificadas e outros tipos de ausência.',
    'endpoint'  => '/nexora/api/rh_operacao',
    'resources' => ['tipos_ausencia' => $_rh['tipos_ausencia']],
];
include dirname(__DIR__) . '/partials/operational_workspace.php';
