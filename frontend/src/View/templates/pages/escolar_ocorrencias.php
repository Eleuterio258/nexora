<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Ocorrências disciplinares';
$activePage = 'escolar_ocorrencias';
$breadcrumb = $app->routes->escolarBreadcrumb([['Ocorrências', '']]);

$workspace = [
    'title'     => 'Ocorrências disciplinares',
    'subtitle'  => 'Registo de incidentes, sanções e méritos.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['incidents' => $_escolar['incidents']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
