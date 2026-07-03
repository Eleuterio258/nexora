<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Turmas';
$activePage = 'escolar_turmas';
$breadcrumb = $app->routes->escolarBreadcrumb([['Turmas', '']]);

$_page      = max(1, (int) ($_GET['pagina'] ?? 1));
$_turno     = in_array($_GET['turno'] ?? '', ['manha','tarde','noite'], true) ? $_GET['turno'] : '';
$_qs        = http_build_query(array_filter(['pagina' => $_page, 'por_pagina' => 25, 'turno' => $_turno]));

$_classesResource            = $_escolar['classes'];
$_classesResource['path']   .= '?' . $_qs;
$_classesResource['filters'] = [
    ['name' => 'turno', 'label' => 'Turno', 'options' => ['' => 'Todos', 'manha' => 'Manhã', 'tarde' => 'Tarde', 'noite' => 'Noite'], 'current' => $_turno],
];

$workspace = [
    'title'     => 'Turmas',
    'subtitle'  => 'Gestão de turmas e directores de turma.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['classes' => $_classesResource],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';