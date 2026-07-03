<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Cursos';
$activePage = 'escolar_cursos';
$breadcrumb = $app->routes->escolarBreadcrumb([['Cursos', '']]);

$workspace = [
    'title'     => 'Cursos',
    'subtitle'  => 'Cursos técnicos e universitários.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['courses' => $_escolar['courses']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
