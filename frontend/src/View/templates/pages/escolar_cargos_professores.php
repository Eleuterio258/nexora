<?php
declare(strict_types=1);

$_escolar   = include dirname(__DIR__) . '/partials/escolar_resources.php';
$pageTitle  = 'Cargos de Professores';
$activePage = 'escolar_cargos_professores';
$breadcrumb = [['Admin', '/nexora/'], ['Gestão Escolar', '/nexora/gestao-escolar'], ['Cargos de Professores', '']];

$workspace = [
    'title'     => 'Cargos de Professores',
    'subtitle'  => 'Cargos e funções atribuídos a professores.',
    'endpoint'  => '/nexora/api/escolar_operacao',
    'resources' => ['teacher_roles' => $_escolar['teacher_roles']],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';