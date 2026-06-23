<?php
declare(strict_types=1);

$pageTitle  = 'Tesouraria';
$activePage = 'tesouraria';
$breadcrumb = [['Admin', '/nexora/'], ['Tesouraria', '']];

$workspace = [
    'title'    => 'Tesouraria',
    'subtitle' => 'Contas bancárias, caixas, movimentos e reconciliações.',
    'endpoint' => '/nexora/api/tesouraria_operacao',
    'resources' => [
        'contas_bancarias' => [
            'label'   => 'Contas Bancárias',
            'path'    => '/api/tesouraria/contas-bancarias',
            'columns' => [
                ['codigo',        'Código'],
                ['banco',         'Banco'],
                ['numero_conta',  'Número de Conta'],
                ['iban',          'IBAN'],
                ['moeda',         'Moeda'],
                ['saldo_actual',  'Saldo Actual'],
                ['activo',        'Activo'],
            ],
            'create' => [
                'operation' => 'conta.create',
                'label'     => 'Nova Conta Bancária',
                'fields'    => [
                    ['name' => 'codigo',       'label' => 'Código',         'required' => true],
                    ['name' => 'banco',        'label' => 'Banco',          'required' => true],
                    ['name' => 'numero_conta', 'label' => 'Número de Conta','required' => true],
                    ['name' => 'iban',         'label' => 'IBAN'],
                    ['name' => 'moeda',        'label' => 'Moeda (ex: MZN)'],
                    ['name' => 'saldo_inicial','label' => 'Saldo Inicial',  'type' => 'number'],
                ],
            ],
        ],
        'caixas' => [
            'label'   => 'Caixas',
            'path'    => '/api/tesouraria/caixas',
            'columns' => [
                ['codigo',       'Código'],
                ['nome',         'Nome'],
                ['moeda',        'Moeda'],
                ['saldo_actual', 'Saldo Actual'],
                ['activo',       'Activo'],
            ],
            'create' => [
                'operation' => 'caixa.create',
                'label'     => 'Nova Caixa',
                'fields'    => [
                    ['name' => 'codigo',        'label' => 'Código',         'required' => true],
                    ['name' => 'nome',          'label' => 'Nome',           'required' => true],
                    ['name' => 'moeda',         'label' => 'Moeda (ex: MZN)'],
                    ['name' => 'saldo_inicial', 'label' => 'Saldo Inicial',  'type' => 'number'],
                ],
            ],
        ],
        'movimentos' => [
            'label'   => 'Movimentos',
            'path'    => '/api/tesouraria/movimentos',
            'columns' => [
                ['tipo',           'Tipo'],
                ['banco|caixa_nome', 'Conta / Caixa'],
                ['valor',          'Valor'],
                ['moeda',          'Moeda'],
                ['data_movimento', 'Data'],
                ['referencia',     'Referência'],
                ['descricao',      'Descrição'],
            ],
            'create' => [
                'operation' => 'movimento.create',
                'label'     => 'Novo Movimento',
                'fields'    => [
                    ['name' => 'tipo',            'label' => 'Tipo',                'type' => 'select', 'options' => ['recebimento', 'pagamento'], 'required' => true],
                    ['name' => 'valor',           'label' => 'Valor',               'type' => 'number', 'required' => true],
                    ['name' => 'bank_account_id', 'label' => 'ID Conta Bancária',   'type' => 'number'],
                    ['name' => 'cash_register_id','label' => 'ID Caixa',            'type' => 'number'],
                    ['name' => 'moeda',           'label' => 'Moeda (ex: MZN)'],
                    ['name' => 'data_movimento',  'label' => 'Data',                'type' => 'date'],
                    ['name' => 'metodo',          'label' => 'Método de Pagamento'],
                    ['name' => 'referencia',      'label' => 'Referência'],
                    ['name' => 'descricao',       'label' => 'Descrição',           'type' => 'textarea'],
                ],
            ],
        ],
        'reconciliacoes' => [
            'label'   => 'Reconciliações',
            'path'    => '/api/tesouraria/reconciliacoes',
            'columns' => [
                ['banco',           'Banco'],
                ['numero_conta',    'Conta'],
                ['periodo_inicio',  'Início'],
                ['periodo_fim',     'Fim'],
                ['saldo_extracto',  'Extrato'],
                ['saldo_sistema',   'Sistema'],
                ['diferenca',       'Diferença'],
                ['status',          'Estado'],
            ],
            'create' => [
                'operation' => 'reconciliacao.create',
                'label'     => 'Nova Reconciliação',
                'fields'    => [
                    ['name' => 'bank_account_id', 'label' => 'ID Conta Bancária', 'type' => 'number', 'required' => true],
                    ['name' => 'periodo_inicio',  'label' => 'Período Início',    'type' => 'date',   'required' => true],
                    ['name' => 'periodo_fim',     'label' => 'Período Fim',       'type' => 'date',   'required' => true],
                    ['name' => 'saldo_extracto',  'label' => 'Saldo do Extrato',  'type' => 'number', 'required' => true],
                    ['name' => 'observacoes',     'label' => 'Observações',       'type' => 'textarea'],
                ],
            ],
            'actions' => [
                ['operation' => 'reconciliacao.fechar', 'label' => 'Fechar', 'confirm' => 'Fechar esta reconciliação?'],
            ],
        ],
    ],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
