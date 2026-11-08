<?php
declare (strict_types = 1);

namespace E258Tech\Routing\Pages;

/**
 * Páginas de administração de contas (utilizadores, cargos e sessões), que
 * vivem dentro do Painel Escolar e falam com /api/auth do backend.
 */
final class AdministracaoPageRoutes
{
    public static function pages(): array
    {
        return [
            'utilizadores'       => ['path' => '/escola/admin/utilizadores', 'view' => 'utilizadores.php', 'permission' => 'autorizacao'],
            'utilizador_form'    => ['path' => '/escola/admin/utilizadores/form', 'view' => 'utilizador_form.php', 'permission' => 'autorizacao'],
            'utilizador_detalhe' => ['path' => '/escola/admin/utilizadores/ver', 'view' => 'utilizador_detalhe.php', 'permission' => 'autorizacao'],
            'cargos'             => ['path' => '/escola/admin/cargos', 'view' => 'cargos.php', 'permission' => 'autorizacao'],
            'cargo_form'         => ['path' => '/escola/admin/cargos/form', 'view' => 'cargo_form.php', 'permission' => 'autorizacao'],
            'sessoes'            => ['path' => '/escola/admin/sessoes', 'view' => 'sessoes.php', 'permission' => 'auth'],
        ];
    }
}
