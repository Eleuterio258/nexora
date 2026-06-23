<?php
declare(strict_types=1);

$pageTitle  = 'Multi-Moeda';
$activePage = 'multi_moeda';
$breadcrumb = [['Admin', '/nexora/'], ['Multi-Moeda', '']];

$workspace = [
    'title'    => 'Multi-Moeda',
    'subtitle' => 'Moedas, taxas de câmbio e moedas activas do tenant.',
    'endpoint' => '/nexora/api/multi_moeda_operacao',
    'resources' => [
        'moedas' => [
            'label'   => 'Moedas',
            'path'    => '/api/multi-moeda/moedas',
            'columns' => [
                ['code',     'Código'],
                ['name',     'Nome'],
                ['symbol',   'Símbolo'],
                ['decimals', 'Decimais'],
                ['active',   'Activa'],
            ],
            'create' => [
                'operation' => 'moeda.create',
                'label'     => 'Nova Moeda',
                'fields'    => [
                    ['name' => 'code',     'label' => 'Código (ex: USD)', 'required' => true],
                    ['name' => 'name',     'label' => 'Nome',             'required' => true],
                    ['name' => 'symbol',   'label' => 'Símbolo (ex: $)'],
                    ['name' => 'decimals', 'label' => 'Decimais',         'type' => 'number'],
                ],
            ],
        ],
        'taxas_cambio' => [
            'label'   => 'Taxas de Câmbio',
            'path'    => '/api/multi-moeda/taxas-cambio',
            'columns' => [
                ['base_code',      'Base'],
                ['quote_code',     'Cotação'],
                ['rate',           'Taxa'],
                ['source',         'Fonte'],
                ['effective_date', 'Data Efectiva'],
            ],
            'create' => [
                'operation' => 'taxa.create',
                'label'     => 'Nova Taxa de Câmbio',
                'fields'    => [
                    ['name' => 'base_currency_id',  'label' => 'ID Moeda Base',     'type' => 'number', 'required' => true],
                    ['name' => 'quote_currency_id', 'label' => 'ID Moeda Cotação',  'type' => 'number', 'required' => true],
                    ['name' => 'rate',              'label' => 'Taxa',              'type' => 'number', 'required' => true],
                    ['name' => 'effective_date',    'label' => 'Data Efectiva',     'type' => 'date'],
                    ['name' => 'source',            'label' => 'Fonte (ex: manual)'],
                ],
            ],
        ],
        'tenant_moedas' => [
            'label'   => 'Moedas Activas',
            'path'    => '/api/multi-moeda/tenant-moedas',
            'columns' => [
                ['code',    'Código'],
                ['name',    'Nome'],
                ['symbol',  'Símbolo'],
                ['is_base', 'Base'],
                ['active',  'Activa'],
            ],
            'create' => [
                'operation' => 'tenant.add',
                'label'     => 'Adicionar Moeda',
                'fields'    => [
                    ['name' => 'currency_id', 'label' => 'ID Moeda', 'type' => 'number', 'required' => true],
                    ['name' => 'is_base',     'label' => 'É Moeda Base?', 'type' => 'select', 'options' => ['false', 'true']],
                ],
            ],
            'actions' => [
                ['operation' => 'tenant.remove', 'label' => 'Remover', 'confirm' => 'Remover esta moeda do tenant?'],
            ],
        ],
    ],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
