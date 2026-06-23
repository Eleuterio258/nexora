<?php
declare(strict_types=1);

$pageTitle = 'Gestão de Stock';
$activePage = 'stock';
$breadcrumb = [['Admin', '/nexora/'], ['Gestão de Stock', '']];

$warehouseFields = [
    ['name' => 'codigo', 'label' => 'Código', 'required' => true],
    ['name' => 'nome', 'label' => 'Nome', 'required' => true],
    ['name' => 'endereco', 'label' => 'Endereço'],
    ['name' => 'responsavel', 'label' => 'Responsável'],
];
$productWarehouseFields = [
    ['name' => 'product_id', 'label' => 'ID do produto', 'type' => 'number', 'required' => true],
    ['name' => 'warehouse_id', 'label' => 'ID do armazém', 'type' => 'number', 'required' => true],
];

$workspace = [
    'title' => 'Gestão de Stock',
    'subtitle' => 'Armazéns, movimentos, reservas, lotes, séries, contagens e alertas.',
    'endpoint' => '/nexora/api/stock_operacao',
    'resources' => [
        'warehouses' => [
            'label' => 'Armazéns', 'path' => '/api/stock/warehouses',
            'columns' => [['codigo|id', 'Código'], ['nome', 'Nome'], ['endereco', 'Endereço'], ['ativo|status', 'Estado']],
            'create' => ['operation' => 'warehouse.create', 'label' => 'Novo armazém', 'fields' => $warehouseFields],
            'actions' => [
                ['operation' => 'warehouse.update', 'label' => 'Editar', 'fields' => $warehouseFields],
                ['operation' => 'warehouse.activate', 'label' => 'Activar'],
                ['operation' => 'warehouse.deactivate', 'label' => 'Desactivar', 'confirm' => 'Desactivar este armazém?'],
            ],
        ],
        'locations' => [
            'label' => 'Localizações', 'path' => null,
            'description' => 'Crie corredores, prateleiras e outras localizações dentro de um armazém.',
            'create' => ['operation' => 'location.create', 'label' => 'Nova localização', 'fields' => [
                ['name' => 'warehouse_id', 'label' => 'ID do armazém', 'type' => 'number', 'required' => true],
                ['name' => 'codigo', 'label' => 'Código', 'required' => true],
                ['name' => 'nome', 'label' => 'Nome'],
                ['name' => 'tipo', 'label' => 'Tipo', 'type' => 'select', 'options' => ['corredor', 'prateleira', 'zona', 'outro']],
            ]],
        ],
        'items' => [
            'label' => 'Posição', 'path' => '/api/stock/items',
            'columns' => [['product_name|product_id', 'Produto'], ['warehouse_name|warehouse_id', 'Armazém'], ['quantidade|quantity', 'Quantidade'], ['reservado|reserved_quantity', 'Reservado'], ['stock_minimo|minimum_stock', 'Mínimo']],
            'create' => ['operation' => 'item.create', 'label' => 'Inicializar stock', 'fields' => array_merge($productWarehouseFields, [
                ['name' => 'quantidade', 'label' => 'Quantidade inicial', 'type' => 'number'],
            ])],
            'actions' => [[
                'operation' => 'item.minimum', 'label' => 'Definir limites', 'fields' => [
                    ['name' => 'stock_minimo', 'label' => 'Stock mínimo', 'type' => 'number', 'required' => true],
                    ['name' => 'stock_maximo', 'label' => 'Stock máximo', 'type' => 'number'],
                ],
            ]],
        ],
        'movements' => [
            'label' => 'Movimentos', 'path' => '/api/stock/movements',
            'columns' => [['id', 'ID'], ['product_name|product_id', 'Produto'], ['warehouse_name|warehouse_id', 'Armazém'], ['tipo|type', 'Tipo'], ['quantidade|quantity', 'Quantidade'], ['created_at|data', 'Data']],
            'create' => ['operation' => 'movement.create', 'label' => 'Novo movimento', 'fields' => array_merge($productWarehouseFields, [
                ['name' => 'tipo', 'label' => 'Tipo', 'type' => 'select', 'options' => ['entrada', 'saida'], 'required' => true],
                ['name' => 'quantidade', 'label' => 'Quantidade', 'type' => 'number', 'required' => true],
                ['name' => 'motivo', 'label' => 'Motivo', 'type' => 'textarea'],
            ])],
        ],
        'adjustments' => [
            'label' => 'Ajustes', 'path' => '/api/stock/adjustments',
            'columns' => [['id', 'ID'], ['product_name|product_id', 'Produto'], ['warehouse_name|warehouse_id', 'Armazém'], ['tipo', 'Tipo'], ['quantidade', 'Quantidade'], ['motivo', 'Motivo']],
            'create' => ['operation' => 'adjustment.create', 'label' => 'Novo ajuste', 'fields' => array_merge($productWarehouseFields, [
                ['name' => 'tipo', 'label' => 'Tipo', 'type' => 'select', 'options' => ['positivo', 'negativo'], 'required' => true],
                ['name' => 'quantidade', 'label' => 'Quantidade', 'type' => 'number', 'required' => true],
                ['name' => 'motivo', 'label' => 'Motivo', 'type' => 'textarea', 'required' => true],
            ])],
        ],
        'transfers' => [
            'label' => 'Transferências', 'path' => '/api/stock/transfers',
            'columns' => [['numero|id', 'Número'], ['source_warehouse_name|warehouse_origem_id', 'Origem'], ['destination_warehouse_name|warehouse_destino_id', 'Destino'], ['status', 'Estado'], ['created_at|data', 'Data']],
            'create' => ['operation' => 'transfer.create', 'label' => 'Nova transferência', 'fields' => [
                ['name' => 'warehouse_origem_id', 'label' => 'ID armazém de origem', 'type' => 'number', 'required' => true],
                ['name' => 'warehouse_destino_id', 'label' => 'ID armazém de destino', 'type' => 'number', 'required' => true],
                ['name' => 'observacoes', 'label' => 'Observações', 'type' => 'textarea'],
            ]],
            'actions' => [
                ['operation' => 'transfer.confirm', 'label' => 'Confirmar'],
                ['operation' => 'transfer.receive', 'label' => 'Receber'],
                ['operation' => 'transfer.cancel', 'label' => 'Cancelar', 'confirm' => 'Cancelar esta transferência?'],
            ],
        ],
        'reservations' => [
            'label' => 'Reservas', 'path' => '/api/stock/reservations',
            'columns' => [['id', 'ID'], ['product_name|product_id', 'Produto'], ['warehouse_name|warehouse_id', 'Armazém'], ['quantidade|quantity', 'Quantidade'], ['reference_type', 'Referência'], ['status', 'Estado']],
            'create' => ['operation' => 'reservation.create', 'label' => 'Nova reserva', 'fields' => array_merge($productWarehouseFields, [
                ['name' => 'quantidade', 'label' => 'Quantidade', 'type' => 'number', 'required' => true],
                ['name' => 'reference_type', 'label' => 'Tipo de referência', 'required' => true],
                ['name' => 'reference_id', 'label' => 'ID da referência', 'type' => 'number', 'required' => true],
            ])],
            'actions' => [
                ['operation' => 'reservation.release', 'label' => 'Liberar'],
                ['operation' => 'reservation.consume', 'label' => 'Consumir'],
            ],
        ],
        'batches' => [
            'label' => 'Lotes', 'path' => '/api/stock/batches',
            'columns' => [['numero|batch_number', 'Lote'], ['product_name|product_id', 'Produto'], ['warehouse_name|warehouse_id', 'Armazém'], ['quantidade|quantity', 'Quantidade'], ['validade|expiry_date', 'Validade']],
            'create' => ['operation' => 'batch.create', 'label' => 'Novo lote', 'fields' => array_merge($productWarehouseFields, [
                ['name' => 'numero', 'label' => 'Número do lote', 'required' => true],
                ['name' => 'fabricacao', 'label' => 'Fabricação', 'type' => 'date'],
                ['name' => 'validade', 'label' => 'Validade', 'type' => 'date'],
                ['name' => 'quantidade', 'label' => 'Quantidade', 'type' => 'number', 'required' => true],
            ])],
        ],
        'serials' => [
            'label' => 'Números de série', 'path' => '/api/stock/serials',
            'columns' => [['serial|numero_serie', 'Número'], ['product_name|product_id', 'Produto'], ['warehouse_name|warehouse_id', 'Armazém'], ['status', 'Estado']],
            'create' => ['operation' => 'serial.create', 'label' => 'Novo número de série', 'fields' => array_merge($productWarehouseFields, [
                ['name' => 'serial', 'label' => 'Número de série', 'required' => true],
            ])],
            'actions' => [[
                'operation' => 'serial.status', 'label' => 'Alterar estado', 'fields' => [
                    ['name' => 'status', 'label' => 'Estado', 'type' => 'select', 'options' => ['disponivel', 'reservado', 'vendido', 'devolvido'], 'required' => true],
                ],
            ]],
        ],
        'counts' => [
            'label' => 'Contagens', 'path' => '/api/stock/counts',
            'columns' => [['numero|id', 'Número'], ['warehouse_name|warehouse_id', 'Armazém'], ['status', 'Estado'], ['created_at|data_inicio', 'Início'], ['divergencias|items', 'Itens']],
            'create' => ['operation' => 'count.create', 'label' => 'Iniciar contagem', 'fields' => [
                ['name' => 'warehouse_id', 'label' => 'ID do armazém', 'type' => 'number', 'required' => true],
                ['name' => 'observacoes', 'label' => 'Observações', 'type' => 'textarea'],
            ]],
            'actions' => [
                ['operation' => 'count.item.create', 'label' => 'Lançar item', 'fields' => [
                    ['name' => 'product_id', 'label' => 'ID do produto', 'type' => 'number', 'required' => true],
                    ['name' => 'quantidade_contada', 'label' => 'Quantidade contada', 'type' => 'number', 'required' => true],
                ]],
                ['operation' => 'count.close', 'label' => 'Fechar', 'confirm' => 'Fechar a contagem e gerar os ajustes?'],
                ['operation' => 'count.cancel', 'label' => 'Cancelar', 'confirm' => 'Cancelar esta contagem?'],
            ],
        ],
        'alerts' => [
            'label' => 'Alertas', 'path' => '/api/stock/alerts',
            'columns' => [['id', 'ID'], ['alert_type|tipo', 'Tipo'], ['product_name|product_id', 'Produto'], ['warehouse_name|warehouse_id', 'Armazém'], ['message|mensagem', 'Mensagem'], ['status', 'Estado']],
            'actions' => [
                ['operation' => 'alert.resolve', 'label' => 'Resolver'],
                ['operation' => 'alert.ignore', 'label' => 'Ignorar'],
            ],
        ],
        'low_stock' => [
            'label' => 'Stock crítico', 'path' => '/api/stock/reports/low-stock',
            'columns' => [['product_name|product_id', 'Produto'], ['warehouse_name|warehouse_id', 'Armazém'], ['quantidade|quantity', 'Quantidade'], ['stock_minimo|minimum_stock', 'Mínimo']],
        ],
        'valuation' => [
            'label' => 'Valorização', 'path' => '/api/stock/reports/valuation',
            'columns' => [['product_name|product_id', 'Produto'], ['warehouse_name|warehouse_id', 'Armazém'], ['quantidade|quantity', 'Quantidade'], ['custo_medio|average_cost', 'Custo médio'], ['valor|valuation', 'Valor']],
        ],
    ],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
