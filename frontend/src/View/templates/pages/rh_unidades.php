<?php
declare(strict_types=1);
$_rh        = include dirname(__DIR__) . '/partials/rh_resources.php';
$pageTitle  = 'Unidades Organizacionais';
$activePage = 'rh_unidades';
$breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Unidades Organizacionais', '']];
$workspace  = [
    'title'     => 'Unidades Organizacionais',
    'subtitle'  => 'Departamentos, equipas, direções e demais unidades da estrutura organizacional.',
    'endpoint'  => '/nexora/api/rh_operacao',
    'resources' => ['unidades' => $_rh['unidades']],
];
include dirname(__DIR__) . '/partials/operational_workspace.php';
