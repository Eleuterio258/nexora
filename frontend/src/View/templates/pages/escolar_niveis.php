<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Níveis de ensino';
$activePage = 'escolar_niveis';
$breadcrumb = $app->routes->escolarBreadcrumb([['Níveis de ensino', '']]);

$workspace = [
    'title'     => 'Níveis de ensino',
    'subtitle'  => 'Configuração de níveis, escalas e nomenclaturas.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['levels' => $_escolar['levels']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
