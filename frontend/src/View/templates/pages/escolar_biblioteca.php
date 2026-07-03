<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Biblioteca';
$activePage = 'escolar_biblioteca';
$breadcrumb = $app->routes->escolarBreadcrumb([['Biblioteca', '']]);

$workspace = [
    'title'     => 'Biblioteca',
    'subtitle'  => 'Catálogo de livros e acervo.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['books' => $_escolar['books']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';