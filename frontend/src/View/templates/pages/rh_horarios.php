<?php
declare(strict_types=1);
$_rh        = include dirname(__DIR__) . '/partials/rh_resources.php';
$pageTitle  = 'Horários de Trabalho';
$activePage = 'rh_horarios';
$breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Horários de Trabalho', '']];
$workspace  = [
    'title'     => 'Horários de Trabalho',
    'subtitle'  => 'Configuração de turnos, entradas, saídas e dias úteis.',
    'endpoint'  => '/nexora/api/rh_operacao',
    'resources' => ['horarios' => $_rh['horarios']],
];
include dirname(__DIR__) . '/partials/operational_workspace.php';
