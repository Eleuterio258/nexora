<?php
declare(strict_types=1);

namespace E258Tech\Routing\Api;

final class SistemaApiRoutes
{
    public static function endpoints(): array
    {
        return [
            // ── Assinaturas ───────────────────────────────────────────────────────
            'assinaturas_operacao' => ['module' => 'assinaturas', 'action' => 'gerir_assinaturas'],

            // ── Gestão Escolar ────────────────────────────────────────────────────
            'escolar_operacao'    => ['module' => 'gestao-escolar', 'action' => 'gerir_academico'],
            'escolar_config_get'  => ['module' => 'gestao-escolar', 'action' => 'gerir_academico', 'method' => 'GET'],
            'escolar_config_save' => ['module' => 'gestao-escolar', 'action' => 'gerir_academico'],

            // ── Notificações ──────────────────────────────────────────────────────
            'notificacoes_operacao' => ['module' => 'notificacoes', 'action' => 'gerir_notificacoes'],

            // ── Segurança ─────────────────────────────────────────────────────────
            'seguranca_operacao' => ['module' => 'seguranca', 'action' => 'gerir_politicas'],

            // ── Sistema ───────────────────────────────────────────────────────────
            'sistema_setting_save'        => ['module' => 'sistema-configuracao', 'action' => 'editar_configuracoes'],
            'sistema_cidade_save'         => ['module' => 'sistema-configuracao', 'action' => 'editar_configuracoes'],
            'sistema_idioma_save'         => ['module' => 'sistema-configuracao', 'action' => 'editar_configuracoes'],
            'sistema_pais_save'           => ['module' => 'sistema-configuracao', 'action' => 'editar_configuracoes'],
            'sistema_moeda_save'          => ['module' => 'sistema-configuracao', 'action' => 'editar_configuracoes'],
            'sistema_taxa_cambio_save'    => ['module' => 'sistema-configuracao', 'action' => 'editar_configuracoes'],
            'sistema_email_template_save' => ['module' => 'sistema-configuracao', 'action' => 'gerir_templates'],
            'sistema_sms_template_save'   => ['module' => 'sistema-configuracao', 'action' => 'gerir_templates'],
            'sistema_integracao_save'     => ['module' => 'sistema-configuracao', 'action' => 'gerir_templates'],

            // ── Super Admin ───────────────────────────────────────────────────────
            'superadmin_dashboard'                 => ['module' => 'superadmin', 'action' => 'ver_dashboard',               'method' => 'GET'],
            'superadmin_tenants'                   => ['module' => 'superadmin', 'action' => 'gerir_tenants',               'method' => 'GET'],
            'superadmin_tenant_save'               => ['module' => 'superadmin', 'action' => 'gerir_tenants'],
            'superadmin_tenant_delete'             => ['module' => 'superadmin', 'action' => 'gerir_tenants'],
            'superadmin_tenant_status'             => ['module' => 'superadmin', 'action' => 'gerir_tenants'],
            'superadmin_plans'                     => ['module' => 'superadmin', 'action' => 'gerir_planos',                'method' => 'GET'],
            'superadmin_plan_save'                 => ['module' => 'superadmin', 'action' => 'gerir_planos'],
            'superadmin_plan_delete'               => ['module' => 'superadmin', 'action' => 'gerir_planos'],
            'superadmin_modules_disponiveis'       => ['module' => 'superadmin', 'action' => 'gerir_modulos',              'method' => 'GET'],
            'superadmin_modules_tenant'            => ['module' => 'superadmin', 'action' => 'gerir_modulos',              'method' => 'GET'],
            'superadmin_module_save'               => ['module' => 'superadmin', 'action' => 'gerir_modulos'],
            'superadmin_modules_reset'             => ['module' => 'superadmin', 'action' => 'gerir_modulos'],
            'superadmin_utilizadores'              => ['module' => 'superadmin', 'action' => 'gerir_utilizadores_globais', 'method' => 'GET'],
            'superadmin_user_tipo'                 => ['module' => 'superadmin', 'action' => 'gerir_utilizadores_globais'],
            'superadmin_user_reset_password'       => ['module' => 'superadmin', 'action' => 'gerir_utilizadores_globais'],
            'superadmin_settings'                  => ['module' => 'superadmin', 'action' => 'gerir_configuracoes_globais', 'method' => 'GET'],
            'superadmin_setting_save'              => ['module' => 'superadmin', 'action' => 'gerir_configuracoes_globais'],
            'superadmin_proximo_numero_funcionario' => ['module' => 'superadmin', 'action' => 'gerir_tenants',             'method' => 'GET'],
            'superadmin_criar_funcionario'         => ['module' => 'superadmin', 'action' => 'gerir_tenants'],

            // ── Aprovações ────────────────────────────────────────────────────────
            'aprovacao_flows'         => ['module' => 'aprovacoes', 'action' => 'gerir_fluxos',    'method' => 'GET'],
            'aprovacao_flow_criar'    => ['module' => 'aprovacoes', 'action' => 'gerir_fluxos'],
            'aprovacao_flow_obter'    => ['module' => 'aprovacoes', 'action' => 'gerir_fluxos',    'method' => 'GET'],
            'aprovacao_flow_save'     => ['module' => 'aprovacoes', 'action' => 'gerir_fluxos'],
            'aprovacao_flow_delete'   => ['module' => 'aprovacoes', 'action' => 'gerir_fluxos'],
            'aprovacao_requests'      => ['module' => 'aprovacoes', 'action' => 'aprovar_pedidos', 'method' => 'GET'],
            'aprovacao_pendentes'     => ['module' => 'aprovacoes', 'action' => 'aprovar_pedidos', 'method' => 'GET'],
            'aprovacao_request_obter' => ['module' => 'aprovacoes', 'action' => 'aprovar_pedidos', 'method' => 'GET'],
            'aprovacao_decidir'       => ['module' => 'aprovacoes', 'action' => 'aprovar_pedidos'],
            'aprovacao_cancelar'      => ['module' => 'aprovacoes', 'action' => 'aprovar_pedidos'],

            // ── Tarefas / Kanban ──────────────────────────────────────────────────
            'quadro_save'     => ['module' => 'tarefas', 'action' => 'gerir_quadros'],
            'quadro_delete'   => ['module' => 'tarefas', 'action' => 'gerir_quadros'],
            'quadro_arquivar' => ['module' => 'tarefas', 'action' => 'gerir_quadros'],
            'lista_save'      => ['module' => 'tarefas', 'action' => 'gerir_listas'],
            'lista_delete'    => ['module' => 'tarefas', 'action' => 'gerir_listas'],
            'lista_reordenar' => ['module' => 'tarefas', 'action' => 'gerir_listas'],
            'cartao_save'     => ['module' => 'tarefas', 'action' => 'gerir_cartoes'],
            'cartao_mover'    => ['module' => 'tarefas', 'action' => 'mover_cartoes'],
            'cartao_concluir' => ['module' => 'tarefas', 'action' => 'mover_cartoes'],
            'cartao_delete'   => ['module' => 'tarefas', 'action' => 'eliminar_cartoes'],
        ];
    }
}
