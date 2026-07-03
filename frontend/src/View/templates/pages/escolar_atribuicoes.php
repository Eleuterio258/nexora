<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Atribuições';
$activePage = 'escolar_atribuicoes';
$breadcrumb = $app->routes->escolarBreadcrumb([['Atribuições', '']]);

$workspace = [
    'title'     => 'Atribuições',
    'subtitle'  => 'Atribuição de professores a turmas e disciplinas.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['teacher_assignments' => $_escolar['teacher_assignments']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';