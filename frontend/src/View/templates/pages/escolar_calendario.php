<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Calendário escolar';
$activePage = 'escolar_calendario';
$breadcrumb = $app->routes->escolarBreadcrumb([['Calendário', '']]);

$workspace = [
    'title'     => 'Calendário escolar',
    'subtitle'  => 'Eventos, feriados e exames.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['calendar' => $_escolar['calendar']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
