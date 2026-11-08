<?php
declare (strict_types = 1);

namespace E258Tech\Routing\Api;

final class AuthApiRoutes
{
    public static function endpoints(): array
    {
        return [
            // ── Autorização (IT admin) ────────────────────────────────────────────
            'utilizador_tipo'             => ['module' => 'autorizacao', 'action' => 'gerir_utilizadores'],
            'utilizador_reset_password'   => ['module' => 'autorizacao', 'action' => 'gerir_utilizadores'],
            'cargo_estado'                => ['module' => 'autorizacao', 'action' => 'gerir_perfis'],
            'cargo_permissoes'            => ['module' => 'autorizacao', 'action' => 'gerir_permissoes'],
            'cargo_permissoes_get'        => ['module' => 'autorizacao', 'action' => 'gerir_permissoes', 'method' => 'GET'],
            'cargo_save'                  => ['module' => 'autorizacao', 'action' => 'gerir_perfis'],
            'utilizador_cargo'            => ['module' => 'autorizacao', 'action' => 'gerir_utilizadores'],
            'utilizador_estado'           => ['module' => 'autorizacao', 'action' => 'gerir_utilizadores'],
            'utilizador_permissoes'       => ['module' => 'autorizacao', 'action' => 'gerir_permissoes'],
            'utilizador_save'             => ['module' => 'autorizacao', 'action' => 'gerir_utilizadores'],

            // ── Sessões (Auth) ────────────────────────────────────────────────────
            'sessao_revogar'              => ['module' => 'auth', 'action' => 'ver_sessoes'],
        ];
    }
}
