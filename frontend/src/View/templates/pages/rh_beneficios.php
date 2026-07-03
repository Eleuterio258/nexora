<?php
declare(strict_types=1);
$_rh        = include dirname(__DIR__) . '/partials/rh_resources.php';
$pageTitle  = 'Benefícios';
$activePage = 'rh_beneficios';
$breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Benefícios', '']];
$workspace  = [
    'title'     => 'Benefícios',
    'subtitle'  => 'Benefícios atribuídos a funcionários (seguros, subsídios, vales, etc.).',
    'endpoint'  => '/nexora/api/rh_operacao',
    'resources' => ['beneficios' => $_rh['beneficios']],
];
include dirname(__DIR__) . '/partials/operational_workspace.php';
