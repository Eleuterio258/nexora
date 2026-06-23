<?php
declare(strict_types=1);

$pageTitle  = 'Financeiro';
$activePage = 'financeiro';
$breadcrumb = [['Admin', '/nexora/'], ['Financeiro', '']];

$workspace = [
    'title'    => 'Financeiro',
    'subtitle' => 'Categorias, métodos de pagamento, contas a receber e a pagar.',
    'endpoint' => '/nexora/api/financeiro_operacao',
    'resources' => [
        'categorias' => [
            'label'   => 'Categorias',
            'path'    => '/api/financeiro/categorias',
            'columns' => [
                ['codigo', 'Código'],
                ['nome',   'Nome'],
                ['tipo',   'Tipo'],
            ],
            'create' => [
                'operation' => 'categoria.create',
                'label'     => 'Nova Categoria',
                'fields'    => [
                    ['name' => 'nome',  'label' => 'Nome', 'required' => true],
                    ['name' => 'tipo',  'label' => 'Tipo', 'type' => 'select',
                     'options' => ['receita', 'despesa', 'transferencia'], 'required' => true],
                    ['name' => 'codigo',    'label' => 'Código'],
                    ['name' => 'parent_id', 'label' => 'ID Categoria Pai', 'type' => 'number'],
                ],
            ],
        ],
        'metodos_pagamento' => [
            'label'   => 'Métodos de Pagamento',
            'path'    => '/api/financeiro/metodos-pagamento',
            'columns' => [
                ['codigo', 'Código'],
                ['nome',   'Nome'],
                ['tipo',   'Tipo'],
                ['ativo',  'Activo'],
            ],
            'create' => [
                'operation' => 'metodo.create',
                'label'     => 'Novo Método',
                'fields'    => [
                    ['name' => 'codigo', 'label' => 'Código', 'required' => true],
                    ['name' => 'nome',   'label' => 'Nome',   'required' => true],
                    ['name' => 'tipo',   'label' => 'Tipo',   'type' => 'select',
                     'options' => ['dinheiro', 'transferencia', 'cheque', 'cartao', 'mpesa', 'outro']],
                ],
            ],
        ],
        'contas_receber' => [
            'label'   => 'Contas a Receber',
            'path'    => '/api/financeiro/contas-receber',
            'columns' => [
                ['numero',          'Número'],
                ['valor_total',     'Total'],
                ['valor_pago',      'Pago'],
                ['valor_pendente',  'Pendente'],
                ['data_vencimento', 'Vencimento'],
                ['status',          'Estado'],
            ],
            'create' => [
                'operation' => 'receber.create',
                'label'     => 'Nova Conta a Receber',
                'fields'    => [
                    ['name' => 'numero',          'label' => 'Número',         'required' => true],
                    ['name' => 'customer_id',     'label' => 'ID Cliente',     'type' => 'number', 'required' => true],
                    ['name' => 'valor_total',     'label' => 'Valor Total',    'type' => 'number', 'required' => true],
                    ['name' => 'data_vencimento', 'label' => 'Vencimento',     'type' => 'date',   'required' => true],
                    ['name' => 'data_emissao',    'label' => 'Emissão',        'type' => 'date'],
                    ['name' => 'descricao',       'label' => 'Descrição',      'type' => 'textarea'],
                ],
            ],
            'actions' => [
                ['operation' => 'receber.pagar', 'label' => 'Registar Pagamento'],
            ],
        ],
        'contas_pagar' => [
            'label'   => 'Contas a Pagar',
            'path'    => '/api/financeiro/contas-pagar',
            'columns' => [
                ['numero',          'Número'],
                ['valor_total',     'Total'],
                ['valor_pago',      'Pago'],
                ['valor_pendente',  'Pendente'],
                ['data_vencimento', 'Vencimento'],
                ['status',          'Estado'],
            ],
            'create' => [
                'operation' => 'pagar.create',
                'label'     => 'Nova Conta a Pagar',
                'fields'    => [
                    ['name' => 'numero',          'label' => 'Número',       'required' => true],
                    ['name' => 'valor_total',     'label' => 'Valor Total',  'type' => 'number', 'required' => true],
                    ['name' => 'data_vencimento', 'label' => 'Vencimento',   'type' => 'date',   'required' => true],
                    ['name' => 'supplier_id',     'label' => 'ID Fornecedor','type' => 'number'],
                    ['name' => 'data_emissao',    'label' => 'Emissão',      'type' => 'date'],
                    ['name' => 'descricao',       'label' => 'Descrição',    'type' => 'textarea'],
                ],
            ],
            'actions' => [
                ['operation' => 'pagar.pagar', 'label' => 'Registar Pagamento'],
            ],
        ],
    ],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
