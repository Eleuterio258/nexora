<?php
declare(strict_types=1);

return [

    // ── Cargos ────────────────────────────────────────────────────────────────
    'cargos' => [
        'label' => 'Cargos', 'path' => '/api/rh/cargos',
        'columns' => [['codigo', 'Código'], ['nome', 'Nome'], ['descricao', 'Descrição'], ['salario_min', 'Sal. Min'], ['salario_max', 'Sal. Max'], ['num_funcionarios', 'Func.'], ['ativo', 'Ativo']],
        'create' => ['operation' => 'cargo.create', 'label' => 'Novo Cargo', 'fields' => [
            ['name' => 'codigo',      'label' => 'Código',          'required' => true],
            ['name' => 'nome',        'label' => 'Nome',            'required' => true],
            ['name' => 'descricao',   'label' => 'Descrição'],
            ['name' => 'salario_min', 'label' => 'Salário Mín. (MZN)', 'type' => 'number'],
            ['name' => 'salario_max', 'label' => 'Salário Máx. (MZN)', 'type' => 'number'],
        ]],
        'actions' => [
            ['operation' => 'cargo.update', 'label' => 'Editar', 'fields' => [
                ['name' => 'codigo',      'label' => 'Código'],
                ['name' => 'nome',        'label' => 'Nome'],
                ['name' => 'descricao',   'label' => 'Descrição'],
                ['name' => 'salario_min', 'label' => 'Salário Mín. (MZN)', 'type' => 'number'],
                ['name' => 'salario_max', 'label' => 'Salário Máx. (MZN)', 'type' => 'number'],
                ['name' => 'ativo',       'label' => 'Ativo', 'type' => 'select', 'options' => [['value' => 'true', 'label' => 'Sim'], ['value' => 'false', 'label' => 'Não']]],
            ]],
            ['operation' => 'cargo.delete', 'label' => 'Eliminar', 'confirm' => 'Eliminar este cargo? Esta ação não pode ser revertida.'],
        ],
    ],

    // ── Unidades Organizacionais ───────────────────────────────────────────────
    'unidades' => [
        'label' => 'Unidades Organizacionais', 'path' => '/api/rh/unidades',
        'columns' => [['codigo', 'Código'], ['nome', 'Nome'], ['tipo', 'Tipo'], ['unidade_pai_nome', 'Unidade Pai'], ['responsavel_nome', 'Responsável'], ['num_funcionarios', 'Func.'], ['ativo', 'Ativo']],
        'create' => ['operation' => 'unidade.create', 'label' => 'Nova Unidade', 'fields' => [
            ['name' => 'codigo',    'label' => 'Código', 'required' => true],
            ['name' => 'nome',      'label' => 'Nome',   'required' => true],
            ['name' => 'tipo',      'label' => 'Tipo',   'type' => 'select', 'options' => ['departamento', 'equipa', 'divisao', 'seccao', 'direccao', 'gabinete', 'projeto', 'outro']],
            ['name' => 'parent_id', 'label' => 'Unidade Pai (ID)', 'type' => 'number'],
            ['name' => 'responsavel_id', 'label' => 'Responsável (ID funcionário)', 'type' => 'number'],
            ['name' => 'descricao', 'label' => 'Descrição'],
        ]],
        'actions' => [
            ['operation' => 'unidade.update', 'label' => 'Editar', 'fields' => [
                ['name' => 'codigo',         'label' => 'Código'],
                ['name' => 'nome',           'label' => 'Nome'],
                ['name' => 'tipo',           'label' => 'Tipo', 'type' => 'select', 'options' => ['departamento', 'equipa', 'divisao', 'seccao', 'direccao', 'gabinete', 'projeto', 'outro']],
                ['name' => 'parent_id',      'label' => 'Unidade Pai (ID)', 'type' => 'number'],
                ['name' => 'responsavel_id', 'label' => 'Responsável (ID funcionário)', 'type' => 'number'],
                ['name' => 'descricao',      'label' => 'Descrição'],
                ['name' => 'ativo',          'label' => 'Ativo', 'type' => 'select', 'options' => [['value' => 'true', 'label' => 'Sim'], ['value' => 'false', 'label' => 'Não']]],
            ]],
            ['operation' => 'unidade.mover', 'label' => 'Mover', 'fields' => [
                ['name' => 'parent_id', 'label' => 'Nova Unidade Pai (ID, 0 = raiz)', 'type' => 'number', 'required' => true],
            ]],
            ['operation' => 'unidade.delete', 'label' => 'Eliminar', 'confirm' => 'Eliminar esta unidade organizacional?'],
        ],
    ],

    // ── Horários de Trabalho ────────────────────────────────────────────────────
    'horarios' => [
        'label' => 'Horários', 'path' => '/api/rh/horarios',
        'columns' => [['codigo', 'Código'], ['nome', 'Nome'], ['hora_entrada', 'Entrada'], ['hora_saida', 'Saída'], ['dias_semana', 'Dias'], ['carga_semanal_horas', 'Carga (h)'], ['num_funcionarios', 'Func.'], ['ativo', 'Ativo']],
        'create' => ['operation' => 'horario.create', 'label' => 'Novo Horário', 'fields' => [
            ['name' => 'codigo',      'label' => 'Código',          'required' => true],
            ['name' => 'nome',        'label' => 'Nome',            'required' => true],
            ['name' => 'hora_entrada','label' => 'Entrada (HH:MM)', 'required' => true, 'placeholder' => '08:00'],
            ['name' => 'hora_saida',  'label' => 'Saída (HH:MM)',   'required' => true, 'placeholder' => '17:00'],
            ['name' => 'intervalo_inicio', 'label' => 'Início intervalo (HH:MM)', 'placeholder' => '12:00'],
            ['name' => 'intervalo_fim',    'label' => 'Fim intervalo (HH:MM)',    'placeholder' => '13:00'],
            ['name' => 'dias_semana', 'label' => 'Dias (ex: 1,2,3,4,5)', 'placeholder' => '1,2,3,4,5'],
            ['name' => 'carga_semanal_horas', 'label' => 'Carga semanal (horas)', 'type' => 'number'],
            ['name' => 'descricao',   'label' => 'Descrição'],
        ]],
        'actions' => [
            ['operation' => 'horario.update', 'label' => 'Editar', 'fields' => [
                ['name' => 'codigo',           'label' => 'Código'],
                ['name' => 'nome',             'label' => 'Nome'],
                ['name' => 'hora_entrada',     'label' => 'Entrada (HH:MM)'],
                ['name' => 'hora_saida',       'label' => 'Saída (HH:MM)'],
                ['name' => 'intervalo_inicio', 'label' => 'Início intervalo'],
                ['name' => 'intervalo_fim',    'label' => 'Fim intervalo'],
                ['name' => 'dias_semana',      'label' => 'Dias (ex: 1,2,3,4,5)'],
                ['name' => 'carga_semanal_horas', 'label' => 'Carga semanal (h)', 'type' => 'number'],
                ['name' => 'ativo',            'label' => 'Ativo', 'type' => 'select', 'options' => [['value' => 'true', 'label' => 'Sim'], ['value' => 'false', 'label' => 'Não']]],
            ]],
            ['operation' => 'horario.delete', 'label' => 'Eliminar', 'confirm' => 'Eliminar este horário?'],
        ],
    ],

    // ── Componentes Salariais ───────────────────────────────────────────────────
    'componentes_salariais' => [
        'label' => 'Componentes Salariais', 'path' => '/api/rh/componentes-salariais',
        'columns' => [['codigo', 'Código'], ['nome', 'Nome'], ['tipo', 'Tipo'], ['forma_calculo', 'Forma de Cálculo'], ['valor_padrao', 'Valor Padrão'], ['num_atribuicoes', 'Atrib.'], ['ativo', 'Ativo']],
        'create' => ['operation' => 'componente.create', 'label' => 'Novo Componente', 'fields' => [
            ['name' => 'codigo',       'label' => 'Código', 'required' => true],
            ['name' => 'nome',         'label' => 'Nome',   'required' => true],
            ['name' => 'tipo',         'label' => 'Tipo',   'type' => 'select', 'options' => [['value' => 'provento', 'label' => 'Provento'], ['value' => 'desconto', 'label' => 'Desconto']], 'required' => true],
            ['name' => 'forma_calculo','label' => 'Forma de Cálculo', 'type' => 'select', 'options' => [['value' => 'fixo', 'label' => 'Valor Fixo'], ['value' => 'percentual', 'label' => 'Percentual']]],
            ['name' => 'valor_padrao', 'label' => 'Valor Padrão', 'type' => 'number'],
        ]],
        'actions' => [
            ['operation' => 'componente.update', 'label' => 'Editar', 'fields' => [
                ['name' => 'codigo',       'label' => 'Código'],
                ['name' => 'nome',         'label' => 'Nome'],
                ['name' => 'tipo',         'label' => 'Tipo',   'type' => 'select', 'options' => [['value' => 'provento', 'label' => 'Provento'], ['value' => 'desconto', 'label' => 'Desconto']]],
                ['name' => 'forma_calculo','label' => 'Forma de Cálculo', 'type' => 'select', 'options' => [['value' => 'fixo', 'label' => 'Valor Fixo'], ['value' => 'percentual', 'label' => 'Percentual']]],
                ['name' => 'valor_padrao', 'label' => 'Valor Padrão', 'type' => 'number'],
                ['name' => 'ativo',        'label' => 'Ativo', 'type' => 'select', 'options' => [['value' => 'true', 'label' => 'Sim'], ['value' => 'false', 'label' => 'Não']]],
            ]],
            ['operation' => 'componente.delete', 'label' => 'Eliminar', 'confirm' => 'Eliminar este componente salarial?'],
        ],
    ],

    // ── Benefícios ─────────────────────────────────────────────────────────────
    'beneficios' => [
        'label' => 'Benefícios', 'path' => '/api/rh/beneficios',
        'columns' => [['codigo', 'Código'], ['nome', 'Nome'], ['descricao', 'Descrição'], ['valor_padrao', 'Valor Padrão'], ['num_atribuicoes', 'Atrib.'], ['ativo', 'Ativo']],
        'create' => ['operation' => 'beneficio.create', 'label' => 'Novo Benefício', 'fields' => [
            ['name' => 'codigo',       'label' => 'Código', 'required' => true],
            ['name' => 'nome',         'label' => 'Nome',   'required' => true],
            ['name' => 'descricao',    'label' => 'Descrição'],
            ['name' => 'valor_padrao', 'label' => 'Valor Padrão (MZN)', 'type' => 'number'],
        ]],
        'actions' => [
            ['operation' => 'beneficio.update', 'label' => 'Editar', 'fields' => [
                ['name' => 'codigo',       'label' => 'Código'],
                ['name' => 'nome',         'label' => 'Nome'],
                ['name' => 'descricao',    'label' => 'Descrição'],
                ['name' => 'valor_padrao', 'label' => 'Valor Padrão (MZN)', 'type' => 'number'],
                ['name' => 'ativo',        'label' => 'Ativo', 'type' => 'select', 'options' => [['value' => 'true', 'label' => 'Sim'], ['value' => 'false', 'label' => 'Não']]],
            ]],
            ['operation' => 'beneficio.delete', 'label' => 'Eliminar', 'confirm' => 'Eliminar este benefício?'],
        ],
    ],

    // ── Tipos de Ausência ───────────────────────────────────────────────────────
    'tipos_ausencia' => [
        'label' => 'Tipos de Ausência', 'path' => '/api/rh/tipos-ausencia',
        'columns' => [['codigo', 'Código'], ['nome', 'Nome'], ['dias_anuais', 'Dias Anuais'], ['remunerada', 'Remunerada'], ['afeta_saldo', 'Afeta Saldo'], ['num_pedidos', 'Pedidos'], ['ativo', 'Ativo']],
        'create' => ['operation' => 'tipo_ausencia.create', 'label' => 'Novo Tipo de Ausência', 'fields' => [
            ['name' => 'codigo',      'label' => 'Código', 'required' => true],
            ['name' => 'nome',        'label' => 'Nome',   'required' => true],
            ['name' => 'dias_anuais', 'label' => 'Dias anuais', 'type' => 'number'],
            ['name' => 'remunerada',  'label' => 'Remunerada',  'type' => 'select', 'options' => [['value' => 'true', 'label' => 'Sim'], ['value' => 'false', 'label' => 'Não']]],
            ['name' => 'afeta_saldo', 'label' => 'Afeta saldo de férias', 'type' => 'select', 'options' => [['value' => 'true', 'label' => 'Sim'], ['value' => 'false', 'label' => 'Não']]],
        ]],
        'actions' => [
            ['operation' => 'tipo_ausencia.update', 'label' => 'Editar', 'fields' => [
                ['name' => 'codigo',      'label' => 'Código'],
                ['name' => 'nome',        'label' => 'Nome'],
                ['name' => 'dias_anuais', 'label' => 'Dias anuais', 'type' => 'number'],
                ['name' => 'remunerada',  'label' => 'Remunerada',  'type' => 'select', 'options' => [['value' => 'true', 'label' => 'Sim'], ['value' => 'false', 'label' => 'Não']]],
                ['name' => 'afeta_saldo', 'label' => 'Afeta saldo', 'type' => 'select', 'options' => [['value' => 'true', 'label' => 'Sim'], ['value' => 'false', 'label' => 'Não']]],
                ['name' => 'ativo',       'label' => 'Ativo',        'type' => 'select', 'options' => [['value' => 'true', 'label' => 'Sim'], ['value' => 'false', 'label' => 'Não']]],
            ]],
            ['operation' => 'tipo_ausencia.delete', 'label' => 'Eliminar', 'confirm' => 'Eliminar este tipo de ausência?'],
        ],
    ],

    // ── Critérios de Avaliação ──────────────────────────────────────────────────
    'criterios_avaliacao' => [
        'label' => 'Critérios de Avaliação', 'path' => '/api/rh/criterios-avaliacao',
        'columns' => [['codigo', 'Código'], ['nome', 'Nome'], ['descricao', 'Descrição'], ['peso', 'Peso'], ['num_usos', 'Usos'], ['ativo', 'Ativo']],
        'create' => ['operation' => 'criterio.create', 'label' => 'Novo Critério', 'fields' => [
            ['name' => 'codigo',    'label' => 'Código', 'required' => true],
            ['name' => 'nome',      'label' => 'Nome',   'required' => true],
            ['name' => 'descricao', 'label' => 'Descrição'],
            ['name' => 'peso',      'label' => 'Peso',   'type' => 'number'],
        ]],
        'actions' => [
            ['operation' => 'criterio.update', 'label' => 'Editar', 'fields' => [
                ['name' => 'codigo',    'label' => 'Código'],
                ['name' => 'nome',      'label' => 'Nome'],
                ['name' => 'descricao', 'label' => 'Descrição'],
                ['name' => 'peso',      'label' => 'Peso',   'type' => 'number'],
                ['name' => 'ativo',     'label' => 'Ativo',  'type' => 'select', 'options' => [['value' => 'true', 'label' => 'Sim'], ['value' => 'false', 'label' => 'Não']]],
            ]],
            ['operation' => 'criterio.delete', 'label' => 'Eliminar', 'confirm' => 'Eliminar este critério de avaliação?'],
        ],
    ],

    // ── Formações ───────────────────────────────────────────────────────────────
    'formacoes' => [
        'label' => 'Formações', 'path' => '/api/rh/formacoes',
        'columns' => [['codigo', 'Código'], ['nome', 'Nome'], ['categoria', 'Categoria'], ['duracao_horas', 'Duração (h)'], ['entidade_formadora', 'Entidade'], ['num_participacoes', 'Partic.'], ['ativo', 'Ativo']],
        'create' => ['operation' => 'formacao.create', 'label' => 'Nova Formação', 'fields' => [
            ['name' => 'codigo',              'label' => 'Código',    'required' => true],
            ['name' => 'nome',                'label' => 'Nome',      'required' => true],
            ['name' => 'categoria',           'label' => 'Categoria', 'type' => 'select', 'options' => ['tecnica', 'comportamental', 'obrigatoria', 'outra']],
            ['name' => 'duracao_horas',       'label' => 'Duração (h)', 'type' => 'number'],
            ['name' => 'entidade_formadora',  'label' => 'Entidade Formadora'],
            ['name' => 'descricao',           'label' => 'Descrição'],
        ]],
        'actions' => [
            ['operation' => 'formacao.update', 'label' => 'Editar', 'fields' => [
                ['name' => 'codigo',             'label' => 'Código'],
                ['name' => 'nome',               'label' => 'Nome'],
                ['name' => 'categoria',          'label' => 'Categoria', 'type' => 'select', 'options' => ['tecnica', 'comportamental', 'obrigatoria', 'outra']],
                ['name' => 'duracao_horas',      'label' => 'Duração (h)', 'type' => 'number'],
                ['name' => 'entidade_formadora', 'label' => 'Entidade Formadora'],
                ['name' => 'descricao',          'label' => 'Descrição'],
                ['name' => 'ativo',              'label' => 'Ativo', 'type' => 'select', 'options' => [['value' => 'true', 'label' => 'Sim'], ['value' => 'false', 'label' => 'Não']]],
            ]],
            ['operation' => 'formacao.delete', 'label' => 'Eliminar', 'confirm' => 'Eliminar esta formação?'],
        ],
    ],

    // ── Períodos de Avaliação ───────────────────────────────────────────────────
    'periodos' => [
        'label' => 'Períodos de Avaliação', 'path' => '/api/rh/periodos',
        'columns' => [['nome', 'Nome'], ['data_inicio', 'Início'], ['data_fim', 'Fim'], ['estado', 'Estado']],
        'create' => ['operation' => 'periodo.create', 'label' => 'Novo Período', 'fields' => [
            ['name' => 'nome',        'label' => 'Nome',     'required' => true],
            ['name' => 'data_inicio', 'label' => 'Início',   'type' => 'date', 'required' => true],
            ['name' => 'data_fim',    'label' => 'Fim',      'type' => 'date', 'required' => true],
        ]],
        'actions' => [
            ['operation' => 'periodo.encerrar', 'label' => 'Encerrar', 'confirm' => 'Encerrar este período? Não será possível registar novas avaliações.'],
        ],
    ],

    // ── Processamento Salarial ──────────────────────────────────────────────────
    'folhas_pagamento' => [
        'label' => 'Folhas de Pagamento', 'path' => '/api/rh/folhas-pagamento',
        'columns' => [['mes', 'Mês'], ['ano', 'Ano'], ['num_funcionarios', 'Func.'], ['total_proventos', 'Proventos'], ['total_descontos', 'Descontos'], ['total_liquido', 'Líquido'], ['estado', 'Estado']],
        'create' => ['operation' => 'folha.create', 'label' => 'Nova Folha', 'fields' => [
            ['name' => 'mes', 'label' => 'Mês', 'type' => 'select', 'required' => true, 'default' => date('n'), 'options' => [
                ['value' => '1',  'label' => 'Janeiro'],
                ['value' => '2',  'label' => 'Fevereiro'],
                ['value' => '3',  'label' => 'Março'],
                ['value' => '4',  'label' => 'Abril'],
                ['value' => '5',  'label' => 'Maio'],
                ['value' => '6',  'label' => 'Junho'],
                ['value' => '7',  'label' => 'Julho'],
                ['value' => '8',  'label' => 'Agosto'],
                ['value' => '9',  'label' => 'Setembro'],
                ['value' => '10', 'label' => 'Outubro'],
                ['value' => '11', 'label' => 'Novembro'],
                ['value' => '12', 'label' => 'Dezembro'],
            ]],
            ['name' => 'ano', 'label' => 'Ano', 'type' => 'select', 'required' => true, 'default' => date('Y'), 'options' => array_map(
                fn($y) => ['value' => (string)$y, 'label' => (string)$y],
                range(date('Y') - 1, date('Y') + 1)
            )],
        ]],
        'actions' => [
            ['link' => '/nexora/rh/folha-pagamento?id={id}', 'label' => 'Ver',       'only_when' => ['estado' => ['processada', 'paga', 'cancelada']]],
            ['operation' => 'folha.processar', 'label' => 'Processar', 'only_when' => ['estado' => 'aberta'],                 'confirm' => 'Processar esta folha? Serão gerados os recibos para todos os funcionários ativos.'],
            ['operation' => 'folha.pagar',     'label' => 'Pagar',     'only_when' => ['estado' => 'processada'],             'confirm' => 'Marcar esta folha e todos os recibos como pagos?'],
            ['operation' => 'folha.cancelar',  'label' => 'Cancelar',  'only_when' => ['estado' => ['aberta', 'processada']], 'confirm' => 'Cancelar esta folha de pagamento?'],
        ],
    ],
];
