<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Comunicação';
$activePage = 'escolar_comunicacao';
$breadcrumb = $app->routes->escolarBreadcrumb([['Comunicação', '']]);

$workspace = [
    'title'     => 'Comunicação',
    'subtitle'  => 'Comunicados e avisos escolares.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['messages' => $_escolar['messages']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';