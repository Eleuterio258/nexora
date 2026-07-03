<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Empréstimos';
$activePage = 'escolar_emprestimos';
$breadcrumb = $app->routes->escolarBreadcrumb([['Empréstimos', '']]);

$workspace = [
    'title'     => 'Empréstimos',
    'subtitle'  => 'Empréstimos e devoluções de livros.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['loans' => $_escolar['loans']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';