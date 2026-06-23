<?php
declare(strict_types=1);

$pageTitle  = 'Segurança';
$activePage = 'seguranca';
$breadcrumb = [['Admin', '/nexora/'], ['Segurança', '']];

$workspace = [
    'title'    => 'Segurança',
    'subtitle' => 'Políticas, MFA e lista de IPs autorizados.',
    'endpoint' => '/nexora/api/seguranca_operacao',
    'resources' => [
        'politicas' => [
            'label'   => 'Políticas',
            'path'    => '/api/seguranca/politicas',
            'columns' => [
                ['codigo', 'Código'],
                ['nome',   'Nome'],
                ['activo', 'Activa'],
            ],
            'create' => [
                'operation' => 'politica.create',
                'label'     => 'Nova Política',
                'fields'    => [
                    ['name' => 'codigo', 'label' => 'Código', 'required' => true],
                    ['name' => 'nome',   'label' => 'Nome',   'required' => true],
                ],
            ],
            'actions' => [
                ['operation' => 'politica.update', 'label' => 'Editar'],
            ],
        ],
        'mfa_enrollments' => [
            'label'   => 'MFA Enrollments',
            'path'    => '/api/seguranca/mfa-enrollments',
            'columns' => [
                ['user_id',    'ID Utilizador'],
                ['metodo',     'Método'],
                ['verified',   'Verificado'],
                ['created_at', 'Criado em'],
            ],
        ],
        'ip_allowlist' => [
            'label'   => 'IPs Autorizados',
            'path'    => '/api/seguranca/ip-allowlist',
            'columns' => [
                ['ip_or_cidr', 'IP / CIDR'],
                ['descricao',  'Descrição'],
                ['activo',     'Activo'],
            ],
            'create' => [
                'operation' => 'ip.add',
                'label'     => 'Adicionar IP',
                'fields'    => [
                    ['name' => 'ip_or_cidr', 'label' => 'IP ou CIDR', 'required' => true],
                    ['name' => 'descricao',  'label' => 'Descrição'],
                ],
            ],
            'actions' => [
                ['operation' => 'ip.remove', 'label' => 'Remover', 'confirm' => 'Remover este IP da allowlist?'],
            ],
        ],
    ],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
