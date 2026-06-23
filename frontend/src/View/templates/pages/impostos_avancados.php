<?php
declare(strict_types=1);

$pageTitle = 'Impostos Avançados';
$activePage = 'impostos_avancados';
$breadcrumb = [['Admin', '/nexora/'], ['Impostos Avançados', '']];

$workspace = [
    'title' => 'Impostos Avançados',
    'subtitle' => 'Regimes fiscais, isenções, retenções, declarações e certificados.',
    'endpoint' => '/nexora/api/imposto_operacao',
    'resources' => [
        'regimes' => [
            'label' => 'Regimes fiscais', 'path' => '/api/impostos/regimes',
            'columns' => [['nome|tipo', 'Regime'], ['inicio|data_inicio', 'Início'], ['fim|data_fim', 'Fim'], ['ativo|status', 'Estado']],
            'create' => ['operation' => 'regime.create', 'label' => 'Novo regime', 'fields' => [
                ['name' => 'tipo', 'label' => 'Regime', 'type' => 'select', 'options' => ['simplificado', 'normal', 'isento'], 'required' => true],
                ['name' => 'data_inicio', 'label' => 'Data de início', 'type' => 'date', 'required' => true],
                ['name' => 'data_fim', 'label' => 'Data de fim', 'type' => 'date'],
            ]],
        ],
        'isencoes' => [
            'label' => 'Isenções de IVA', 'path' => '/api/impostos/isencoes',
            'columns' => [['numero|numero_isencao', 'Número'], ['entity_type|entidade_tipo', 'Entidade'], ['entity_id|entidade_id', 'ID'], ['valid_from|inicio', 'Início'], ['valid_until|validade', 'Validade'], ['status|ativo', 'Estado']],
            'create' => ['operation' => 'exemption.create', 'label' => 'Nova isenção', 'fields' => [
                ['name' => 'entity_type', 'label' => 'Tipo de entidade', 'type' => 'select', 'options' => ['cliente', 'fornecedor', 'produto', 'categoria'], 'required' => true],
                ['name' => 'entity_id', 'label' => 'ID da entidade', 'type' => 'number', 'required' => true],
                ['name' => 'numero_isencao', 'label' => 'Número da isenção', 'required' => true],
                ['name' => 'data_inicio', 'label' => 'Início', 'type' => 'date', 'required' => true],
                ['name' => 'validade', 'label' => 'Validade', 'type' => 'date', 'required' => true],
                ['name' => 'motivo', 'label' => 'Motivo', 'type' => 'textarea'],
            ]],
            'actions' => [[
                'operation' => 'exemption.delete', 'label' => 'Remover', 'confirm' => 'Remover esta isenção?',
            ]],
        ],
        'retencoes' => [
            'label' => 'Retenções', 'path' => '/api/impostos/retencoes',
            'columns' => [['id', 'ID'], ['tipo', 'Tipo'], ['entity_type|entidade_tipo', 'Entidade'], ['document_number|documento', 'Documento'], ['base|valor_base', 'Base'], ['tax|valor_retido', 'Retido'], ['data', 'Data']],
            'create' => ['operation' => 'withholding.create', 'label' => 'Nova retenção', 'fields' => [
                ['name' => 'tipo', 'label' => 'Tipo', 'type' => 'select', 'options' => ['IRPS', 'IRPC'], 'required' => true],
                ['name' => 'entity_type', 'label' => 'Entidade', 'type' => 'select', 'options' => ['fornecedor', 'colaborador'], 'required' => true],
                ['name' => 'entity_id', 'label' => 'ID da entidade', 'type' => 'number', 'required' => true],
                ['name' => 'documento_id', 'label' => 'ID do documento', 'type' => 'number', 'required' => true],
                ['name' => 'valor_base', 'label' => 'Valor base', 'type' => 'number', 'required' => true],
                ['name' => 'taxa', 'label' => 'Taxa (%)', 'type' => 'number', 'required' => true],
                ['name' => 'data', 'label' => 'Data', 'type' => 'date', 'required' => true],
            ]],
        ],
        'declaracoes' => [
            'label' => 'Declarações', 'path' => '/api/impostos/declaracoes',
            'columns' => [['numero|id', 'Número'], ['tipo', 'Tipo'], ['periodo_inicio|inicio', 'Início'], ['periodo_fim|fim', 'Fim'], ['valor_pagar|saldo', 'Saldo'], ['status', 'Estado']],
            'create' => ['operation' => 'return.create', 'label' => 'Gerar declaração', 'fields' => [
                ['name' => 'tipo', 'label' => 'Tipo', 'type' => 'select', 'options' => ['IVA', 'RETENCOES'], 'required' => true],
                ['name' => 'periodo_inicio', 'label' => 'Início do período', 'type' => 'date', 'required' => true],
                ['name' => 'periodo_fim', 'label' => 'Fim do período', 'type' => 'date', 'required' => true],
            ]],
            'actions' => [[
                'operation' => 'return.submit', 'label' => 'Submeter', 'confirm' => 'Submeter esta declaração? Depois de submetida ficará imutável.',
            ]],
        ],
        'certificados' => [
            'label' => 'Certificados', 'path' => '/api/impostos/certificados',
            'columns' => [['numero', 'Número'], ['tipo', 'Tipo'], ['entity_type|entidade_tipo', 'Entidade'], ['emissao|data_emissao', 'Emissão'], ['validade|data_validade', 'Validade'], ['status|ativo', 'Estado']],
            'create' => ['operation' => 'certificate.create', 'label' => 'Novo certificado', 'fields' => [
                ['name' => 'tipo', 'label' => 'Tipo', 'type' => 'select', 'options' => ['isencao', 'bom_contribuinte'], 'required' => true],
                ['name' => 'entity_type', 'label' => 'Tipo de entidade', 'required' => true],
                ['name' => 'entity_id', 'label' => 'ID da entidade', 'type' => 'number', 'required' => true],
                ['name' => 'numero', 'label' => 'Número', 'required' => true],
                ['name' => 'emissao', 'label' => 'Emissão', 'type' => 'date', 'required' => true],
                ['name' => 'validade', 'label' => 'Validade', 'type' => 'date', 'required' => true],
            ]],
        ],
    ],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
