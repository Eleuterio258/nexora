<?php
declare(strict_types=1);

namespace E258Tech\Routing\Pages;

final class SistemaPageRoutes
{
    public static function pages(): array
    {
        return [
            // Sistema
            'sistema_geral'     => ['path' => '/nexora/sistema/geral',      'view' => 'sistema_geral.php',     'permission' => 'sistema-configuracao'],
            'sistema_templates' => ['path' => '/nexora/sistema/templates',  'view' => 'sistema_templates.php', 'permission' => 'sistema-configuracao'],
            'sistema_logs'      => ['path' => '/nexora/sistema/logs',       'view' => 'sistema_logs.php',      'permission' => 'sistema-configuracao'],
            // Outros
            'assinaturas' => ['path' => '/nexora/assinaturas', 'view' => 'assinaturas.php', 'permission' => 'assinaturas'],
            'notificacoes' => ['path' => '/nexora/notificacoes', 'view' => 'notificacoes.php', 'permission' => 'notificacoes'],
            'seguranca'    => ['path' => '/nexora/seguranca',   'view' => 'seguranca.php',    'permission' => 'seguranca'],
            // Tarefas / Kanban
            'tarefas'        => ['path' => '/nexora/tarefas',        'view' => 'tarefas.php',        'permission' => 'tarefas'],
            'tarefas_quadro' => ['path' => '/nexora/tarefas/quadro', 'view' => 'tarefas_quadro.php', 'permission' => 'tarefas'],
            'tarefas_cartao' => ['path' => '/nexora/tarefas/cartao', 'view' => 'tarefas_cartao.php', 'permission' => 'tarefas'],
            // Self-service
            'pedido_ferias'     => ['path' => '/nexora/pedido-ferias', 'view' => 'pedido_ferias.php',     'permission' => ''],
            'chat'              => ['path' => '/nexora/chat',          'view' => 'chat.php',              'permission' => ''],
            'minha_assiduidade' => ['path' => '/nexora/assiduidade',   'view' => 'minha_assiduidade.php', 'permission' => ''],
            'meu_perfil'        => ['path' => '/nexora/perfil',        'view' => 'meu_perfil.php',        'permission' => ''],
            // Administração
            'utilizadores'    => ['path' => '/nexora/admin/utilizadores',      'view' => 'utilizadores.php',    'permission' => 'autorizacao'],
            'utilizador_form' => ['path' => '/nexora/admin/utilizadores/form', 'view' => 'utilizador_form.php', 'permission' => 'autorizacao'],
            'cargos'          => ['path' => '/nexora/admin/cargos',            'view' => 'cargos.php',          'permission' => 'autorizacao'],
            'cargo_form'      => ['path' => '/nexora/admin/cargos/form',       'view' => 'cargo_form.php',      'permission' => 'autorizacao'],
            'empresa'         => ['path' => '/nexora/admin/empresa',           'view' => 'empresa.php',         'permission' => 'empresa'],
            'sessoes'         => ['path' => '/nexora/admin/sessoes',           'view' => 'sessoes.php',         'permission' => 'auth'],
            'auditoria'       => ['path' => '/nexora/admin/auditoria',         'view' => 'auditoria.php',       'permission' => 'auditoria'],
            // Super Admin
            'superadmin_dashboard' => ['path' => '/nexora/superadmin',                  'view' => 'superadmin_dashboard.php', 'permission' => 'superadmin'],
            'superadmin_tenants'   => ['path' => '/nexora/superadmin/tenants',          'view' => 'superadmin_tenants.php',   'permission' => 'superadmin'],
            'superadmin_plans'     => ['path' => '/nexora/superadmin/plans',            'view' => 'superadmin_plans.php',     'permission' => 'superadmin'],
            'superadmin_modules'   => ['path' => '/nexora/superadmin/modules',          'view' => 'superadmin_modules.php',   'permission' => 'superadmin'],
            'superadmin_users'     => ['path' => '/nexora/superadmin/utilizadores',     'view' => 'superadmin_users.php',     'permission' => 'superadmin'],
            'superadmin_settings'  => ['path' => '/nexora/superadmin/settings',         'view' => 'superadmin_settings.php',  'permission' => 'superadmin'],
        ];
    }
}
