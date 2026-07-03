<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Horários';
$activePage = 'escolar_horarios';
$breadcrumb = $app->routes->escolarBreadcrumb([['Horários', '']]);

$workspace = [
    'title'     => 'Horários',
    'subtitle'  => 'Gestão de slots e horários de aula.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => [
        'time_slots' => $_escolar['time_slots'],
        'timetable'  => $_escolar['timetable'],
    ],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
