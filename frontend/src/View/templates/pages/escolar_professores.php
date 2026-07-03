<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Professores';
$activePage = 'escolar_professores';
$breadcrumb = $app->routes->escolarBreadcrumb([['Professores', '']]);

$workspace = [
    'title'     => 'Professores',
    'subtitle'  => 'Gestão de docentes e cargos horários.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['teachers' => $_escolar['teachers']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
