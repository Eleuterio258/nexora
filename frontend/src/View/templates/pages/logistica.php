<?php
declare(strict_types=1);

$pageTitle  = 'Logística';
$activePage = 'logistica';
$breadcrumb = [['Admin', '/nexora/'], ['Logística', '']];

$workspace = [
    'title'    => 'Logística',
    'subtitle' => 'Motoristas, viaturas, rotas, estados, envios e tracking de entregas.',
    'endpoint' => '/nexora/api/logistica_operacao',
    'resources' => [
        'motoristas' => [
            'label'   => 'Motoristas',
            'path'    => '/api/delivery-drivers',
            'columns' => [
                ['codigo',         'Código'],
                ['nome',           'Nome'],
                ['telefone',       'Telefone'],
                ['carta_conducao', 'Carta de Condução'],
                ['activo',         'Activo'],
            ],
            'create' => [
                'operation' => 'motorista.create',
                'label'     => 'Novo Motorista',
                'fields'    => [
                    ['name' => 'codigo',         'label' => 'Código',            'required' => true],
                    ['name' => 'nome',           'label' => 'Nome',              'required' => true],
                    ['name' => 'telefone',       'label' => 'Telefone'],
                    ['name' => 'documento',      'label' => 'Documento de ID'],
                    ['name' => 'carta_conducao', 'label' => 'Carta de Condução'],
                ],
            ],
        ],
        'viaturas' => [
            'label'   => 'Viaturas',
            'path'    => '/api/delivery-vehicles',
            'columns' => [
                ['codigo',        'Código'],
                ['matricula',     'Matrícula'],
                ['marca',         'Marca'],
                ['modelo',        'Modelo'],
                ['capacidade_kg', 'Capacidade (kg)'],
                ['activo',        'Activo'],
            ],
            'create' => [
                'operation' => 'viatura.create',
                'label'     => 'Nova Viatura',
                'fields'    => [
                    ['name' => 'codigo',        'label' => 'Código',           'required' => true],
                    ['name' => 'matricula',     'label' => 'Matrícula',        'required' => true],
                    ['name' => 'marca',         'label' => 'Marca'],
                    ['name' => 'modelo',        'label' => 'Modelo'],
                    ['name' => 'capacidade_kg', 'label' => 'Capacidade (kg)', 'type' => 'number'],
                ],
            ],
        ],
        'rotas' => [
            'label'   => 'Rotas',
            'path'    => '/api/delivery-routes',
            'columns' => [
                ['codigo',                'Código'],
                ['nome',                  'Nome'],
                ['origem',                'Origem'],
                ['destino',               'Destino'],
                ['distancia_km',          'Distância (km)'],
                ['duracao_estimada_min',  'Duração Est. (min)'],
            ],
            'create' => [
                'operation' => 'rota.create',
                'label'     => 'Nova Rota',
                'fields'    => [
                    ['name' => 'codigo',                'label' => 'Código',             'required' => true],
                    ['name' => 'nome',                  'label' => 'Nome',               'required' => true],
                    ['name' => 'origem',                'label' => 'Origem',             'required' => true],
                    ['name' => 'destino',               'label' => 'Destino',            'required' => true],
                    ['name' => 'distancia_km',          'label' => 'Distância (km)',     'type' => 'number'],
                    ['name' => 'duracao_estimada_min',  'label' => 'Duração Est. (min)', 'type' => 'number'],
                ],
            ],
        ],
        'estados' => [
            'label'   => 'Estados de Entrega',
            'path'    => '/api/delivery-status',
            'columns' => [
                ['codigo', 'Código'],
                ['nome',   'Nome'],
                ['ordem',  'Ordem'],
                ['final',  'Estado Final'],
            ],
            'create' => [
                'operation' => 'estado.create',
                'label'     => 'Novo Estado',
                'fields'    => [
                    ['name' => 'codigo', 'label' => 'Código', 'required' => true],
                    ['name' => 'nome',   'label' => 'Nome',   'required' => true],
                    ['name' => 'ordem',  'label' => 'Ordem',  'type' => 'number'],
                    ['name' => 'final',  'label' => 'É estado final? (1=Sim / 0=Não)', 'type' => 'number'],
                ],
            ],
        ],
        'envios' => [
            'label'   => 'Envios',
            'path'    => '/api/shipments',
            'columns' => [
                ['numero',           'Número'],
                ['endereco_entrega', 'Endereço'],
                ['status',           'Estado'],
                ['driver_name',      'Motorista'],
                ['vehicle_plate',    'Viatura'],
                ['route_name',       'Rota'],
                ['data_prevista',    'Previsto'],
                ['created_at',       'Criado em'],
            ],
            'create' => [
                'operation' => 'envio.create',
                'label'     => 'Novo Envio',
                'fields'    => [
                    ['name' => 'numero',          'label' => 'Número',            'required' => true],
                    ['name' => 'endereco_entrega','label' => 'Endereço de Entrega','required' => true],
                    ['name' => 'customer_id',     'label' => 'ID do Cliente',      'type' => 'number'],
                    ['name' => 'route_id',        'label' => 'ID da Rota',         'type' => 'number'],
                    ['name' => 'driver_id',       'label' => 'ID do Motorista',    'type' => 'number'],
                    ['name' => 'vehicle_id',      'label' => 'ID da Viatura',      'type' => 'number'],
                    ['name' => 'contacto_entrega','label' => 'Contacto de Entrega'],
                    ['name' => 'data_prevista',   'label' => 'Data Prevista',      'type' => 'date'],
                    ['name' => 'observacoes',     'label' => 'Observações',        'type' => 'textarea'],
                ],
            ],
            'actions' => [
                [
                    'operation' => 'envio.item',
                    'label'     => 'Adicionar Item',
                    'fields'    => [
                        ['name' => 'shipment_id', 'label' => 'ID do Envio',   'type' => 'number', 'required' => true],
                        ['name' => 'descricao',   'label' => 'Descrição',      'required' => true],
                        ['name' => 'quantidade',  'label' => 'Quantidade',     'type' => 'number', 'required' => true],
                        ['name' => 'product_id',  'label' => 'ID do Produto',  'type' => 'number'],
                        ['name' => 'peso_kg',     'label' => 'Peso (kg)',      'type' => 'number'],
                    ],
                ],
                [
                    'operation' => 'tracking.create',
                    'label'     => 'Registar Tracking',
                    'fields'    => [
                        ['name' => 'shipment_id', 'label' => 'ID do Envio',   'type' => 'number', 'required' => true],
                        ['name' => 'status_id',   'label' => 'ID do Estado',  'type' => 'number', 'required' => true],
                        ['name' => 'localizacao', 'label' => 'Localização'],
                        ['name' => 'latitude',    'label' => 'Latitude',      'type' => 'number'],
                        ['name' => 'longitude',   'label' => 'Longitude',     'type' => 'number'],
                        ['name' => 'observacoes', 'label' => 'Observações',   'type' => 'textarea'],
                    ],
                ],
            ],
        ],
        'tracking' => [
            'label'   => 'Tracking',
            'path'    => '/api/delivery-tracking',
            'columns' => [
                ['shipment_number', 'Envio'],
                ['status',          'Código Estado'],
                ['status_nome',     'Estado'],
                ['localizacao',     'Localização'],
                ['registado_em',    'Registado em'],
            ],
        ],
    ],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
