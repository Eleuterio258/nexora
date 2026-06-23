<?php
declare(strict_types=1);

$pageTitle  = 'Notificações';
$activePage = 'notificacoes';
$breadcrumb = [['Admin', '/nexora/'], ['Notificações', '']];

$workspace = [
    'title'    => 'Notificações',
    'subtitle' => 'Canais, templates e mensagens de notificação.',
    'endpoint' => '/nexora/api/notificacoes_operacao',
    'resources' => [
        'canais' => [
            'label'   => 'Canais',
            'path'    => '/api/notificacoes/canais',
            'columns' => [
                ['nome',       'Nome'],
                ['tipo',       'Tipo'],
                ['created_at', 'Criado em'],
            ],
            'create' => [
                'operation' => 'canal.create',
                'label'     => 'Novo Canal',
                'fields'    => [
                    ['name' => 'nome', 'label' => 'Nome', 'required' => true],
                    ['name' => 'tipo', 'label' => 'Tipo', 'type' => 'select',
                     'options' => ['email', 'sms', 'push', 'webhook'], 'required' => true],
                ],
            ],
        ],
        'templates' => [
            'label'   => 'Templates',
            'path'    => '/api/notificacoes/templates',
            'columns' => [
                ['codigo',     'Código'],
                ['canal_tipo', 'Canal'],
                ['assunto',    'Assunto'],
                ['activo',     'Activo'],
            ],
            'create' => [
                'operation' => 'template.create',
                'label'     => 'Novo Template',
                'fields'    => [
                    ['name' => 'codigo',     'label' => 'Código',    'required' => true],
                    ['name' => 'canal_tipo', 'label' => 'Canal',     'type' => 'select',
                     'options' => ['email', 'sms', 'push', 'webhook'], 'required' => true],
                    ['name' => 'assunto',    'label' => 'Assunto'],
                    ['name' => 'corpo',      'label' => 'Corpo',     'type' => 'textarea', 'required' => true],
                ],
            ],
            'actions' => [
                ['operation' => 'template.update', 'label' => 'Editar'],
            ],
        ],
        'mensagens' => [
            'label'   => 'Mensagens',
            'path'    => '/api/notificacoes/mensagens',
            'columns' => [
                ['canal_tipo',   'Canal'],
                ['destinatario', 'Destinatário'],
                ['status',       'Estado'],
                ['tentativas',   'Tentativas'],
                ['created_at',   'Criado em'],
            ],
            'create' => [
                'operation' => 'mensagem.send',
                'label'     => 'Enviar Notificação',
                'fields'    => [
                    ['name' => 'canal_tipo',   'label' => 'Canal', 'type' => 'select',
                     'options' => ['email', 'sms', 'push', 'webhook'], 'required' => true],
                    ['name' => 'destinatario', 'label' => 'Destinatário', 'required' => true],
                    ['name' => 'corpo',        'label' => 'Mensagem',     'type' => 'textarea', 'required' => true],
                    ['name' => 'template_id',  'label' => 'ID Template (opcional)', 'type' => 'number'],
                ],
            ],
        ],
    ],
];

include dirname(__DIR__) . '/partials/operational_workspace.php';
