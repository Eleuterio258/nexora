<?php
declare (strict_types = 1);

namespace E258Tech\Routing\Pages;

/**
 * Rotas do portal POS — organizadas por persona:
 *
 *   /pos/operador/*  → terminal de venda, sessão, devoluções
 *   /pos/gerente/*   → dashboard, relatórios, histórico de vendas/sessões
 *   /pos/admin/*     → terminais, catálogo, descontos, configuração
 *
 * As rotas antigas (/nexora/pos/*) continuam em ComercialPageRoutes.php durante
 * a transição, mas apontam para as mesmas views. Quando os portais estiverem
 * 100% operacionais, as rotas antigas devem ser removidas e substituídas por
 * redirecionamentos.
 */
final class PosPageRoutes
{
    public static function pages(): array
    {
        return [
            // ═════════════════════════════════════════════════════════════════
            // PORTAL OPERADOR
            // ═════════════════════════════════════════════════════════════════
            'pos_operator_terminal'      => ['path' => '/pos/operador/terminal',      'view' => 'pos/operator/terminal.php',      'permission' => 'pos:operar_pos'],
            'pos_operator_session_open'  => ['path' => '/pos/operador/sessao/abrir',  'view' => 'pos/operator/session_open.php',  'permission' => 'pos:abrir_sessao'],
            'pos_operator_session_close' => ['path' => '/pos/operador/sessao/fechar', 'view' => 'pos/operator/session_close.php', 'permission' => 'pos:fechar_sessao'],
            'pos_operator_returns'       => ['path' => '/pos/operador/devolucoes',    'view' => 'pos/operator/returns.php',       'permission' => 'pos:processar_devolucao'],

            // ═════════════════════════════════════════════════════════════════
            // PORTAL GERENTE
            // ═════════════════════════════════════════════════════════════════
            'pos_manager_dashboard'      => ['path' => '/pos/gerente/dashboard',      'view' => 'pos/manager/dashboard.php',      'permission' => 'pos:relatorios'],
            'pos_manager_sales'          => ['path' => '/pos/gerente/vendas',         'view' => 'pos/manager/sales.php',          'permission' => 'pos:ver_vendas'],
            'pos_manager_sale_view'      => ['path' => '/pos/gerente/vendas/ver',     'view' => 'pos/manager/sale_view.php',      'permission' => 'pos:ver_vendas'],
            'pos_manager_sessions'       => ['path' => '/pos/gerente/sessoes',        'view' => 'pos/manager/sessions.php',       'permission' => 'pos:supervisionar'],
            'pos_manager_session_view'   => ['path' => '/pos/gerente/sessoes/ver',    'view' => 'pos/manager/session_view.php',   'permission' => 'pos:supervisionar'],
            'pos_manager_reports'        => ['path' => '/pos/gerente/relatorios',     'view' => 'pos/manager/reports.php',        'permission' => 'pos:relatorios'],
            'pos_manager_cash_closing'   => ['path' => '/pos/gerente/relatorios/fecho', 'view' => 'pos/manager/cash_closing.php', 'permission' => 'pos:relatorios'],

            // ═════════════════════════════════════════════════════════════════
            // PORTAL ADMIN
            // ═════════════════════════════════════════════════════════════════
            'pos_admin_terminals'        => ['path' => '/pos/admin/terminais',        'view' => 'pos/admin/terminals.php',        'permission' => 'pos:gerir_terminais'],
            'pos_admin_terminal_form'    => ['path' => '/pos/admin/terminais/form',   'view' => 'pos/admin/terminal_form.php',  'permission' => 'pos:gerir_terminais'],
            'pos_admin_catalog'          => ['path' => '/pos/admin/catalogo',         'view' => 'pos/admin/catalog.php',          'permission' => 'pos:gerir_catalogo'],
            'pos_admin_discounts'        => ['path' => '/pos/admin/descontos',        'view' => 'pos/admin/discounts.php',        'permission' => 'pos:gerir_descontos'],
            'pos_admin_configuration'    => ['path' => '/pos/admin/configuracao',     'view' => 'pos/admin/configuration.php',    'permission' => 'pos:configurar'],
        ];
    }
}
