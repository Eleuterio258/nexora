<?php
declare(strict_types=1);

namespace E258Tech\Routing\Api;

final class EmpresaClientesApiRoutes
{
    public static function endpoints(): array
    {
        return [
            // ── Empresa ───────────────────────────────────────────────────────────
            'empresa_save'         => ['module' => 'empresa', 'action' => 'editar_empresa'],
            'empresa_fiscal_save'  => ['module' => 'empresa', 'action' => 'editar_empresa'],
            'empresa_branch_save'  => ['module' => 'empresa', 'action' => 'gerir_filiais'],
            'empresa_licenca_save' => ['module' => 'empresa', 'action' => 'gerir_licencas'],

            // ── Clientes ──────────────────────────────────────────────────────────
            'cliente_save'            => ['module' => 'clientes', 'action' => 'gerir_clientes'],
            'cliente_estado'          => ['module' => 'clientes', 'action' => 'gerir_clientes'],
            'cliente_contacto_save'   => ['module' => 'clientes', 'action' => 'gerir_clientes'],
            'cliente_contacto_delete' => ['module' => 'clientes', 'action' => 'gerir_clientes'],
            'cliente_endereco_save'   => ['module' => 'clientes', 'action' => 'gerir_clientes'],
            'cliente_endereco_delete' => ['module' => 'clientes', 'action' => 'gerir_clientes'],
            'cliente_pagamento_save'  => ['module' => 'clientes', 'action' => 'gerir_clientes'],
            'cliente_grupo_save'      => ['module' => 'clientes', 'action' => 'gerir_grupos'],
            'cliente_credito_save'    => ['module' => 'clientes', 'action' => 'gerir_credito'],
        ];
    }
}
