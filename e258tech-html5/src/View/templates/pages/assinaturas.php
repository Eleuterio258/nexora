<?php
declare(strict_types=1);

$pageTitle  = 'Assinaturas';
$activePage = 'assinaturas';
$breadcrumb = [['Admin', '/nexora/'], ['Assinaturas', '']];

$workspace = [
    'title'    => 'Assinaturas',
    'subtitle' => 'Planos de subscrição e gestão de assinaturas.',
    'endpoint' => '/nexora/api/assinaturas_operacao',
    'resources' => [
        'planos' => [
            'label'   => 'Planos',
            'path'    => '/api/assinaturas/planos',
            'columns' => [
                ['codigo',         'Código'],
                ['nome',           'Nome'],
                ['billing_period', 'Período'],
                ['preco',          'Preço'],
                ['moeda',          'Moeda'],
                ['activo',         'Activo'],
            ],
            'create' => [
                'operation' => 'plano.create',
                'label'     => 'Novo Plano',
                'fields'    => [
                    ['name' => 'codigo',         'label' => 'Código',  'required' => true],
                    ['name' => 'nome',           'label' => 'Nome',    'required' => true],
                    ['name' => 'billing_period', 'label' => 'Período', 'type' => 'select',
                     'options' => ['mensal', 'trimestral', 'anual'], 'required' => true],
                    ['name' => 'preco', 'label' => 'Preço', 'type' => 'number', 'required' => true],
                    ['name' => 'moeda', 'label' => 'Moeda (ex: MZN)'],
                ],
            ],
        ],
        'subscriptions' => [
            'label'   => 'Assinaturas',
            'path'    => '/api/assinaturas/subscriptions',
            'columns' => [
                ['numero',     'Número'],
                ['plano_nome', 'Plano'],
                ['status',     'Estado'],
                ['starts_at',  'Início'],
                ['ends_at',    'Fim'],
                ['moeda',      'Moeda'],
                ['unit_price', 'Preço'],
            ],
            'create' => [
                'operation' => 'assinatura.create',
                'label'     => 'Nova Assinatura',
                'fields'    => [
                    ['name' => 'numero',     'label' => 'Número',     'required' => true],
                    ['name' => 'plan_id',    'label' => 'ID Plano',   'type' => 'number', 'required' => true],
                    ['name' => 'starts_at',  'label' => 'Início',     'type' => 'date',   'required' => true],
                    ['name' => 'unit_price', 'label' => 'Preço Unit.','type' => 'number'],
                    ['name' => 'moeda',      'label' => 'Moeda (ex: MZN)'],
                    ['name' => 'company_id', 'label' => 'ID Empresa', 'type' => 'number'],
                ],
            ],
            'actions' => [
                ['operation' => 'assinatura.cancelar', 'label' => 'Cancelar', 'confirm' => 'Cancelar esta assinatura?'],
                ['operation' => 'assinatura.renovar',  'label' => 'Renovar'],
            ],
        ],
    ],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
