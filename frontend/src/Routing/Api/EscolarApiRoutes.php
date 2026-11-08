<?php
declare (strict_types = 1);

namespace E258Tech\Routing\Api;

final class EscolarApiRoutes
{
    public static function endpoints(): array
    {
        return [
            // ── Gestão Escolar ────────────────────────────────────────────────────
            // As acções têm de existir no backend (auth.permissoes_cargo). Antes
            // pedia-se 'gerir_academico', que nenhum cargo tem, e só o
            // superadmin passava. escolar_operacao executa operações de uma
            // lista fechada (SchoolService) e cada uma é autorizada no backend
            // pela permissão da sua rota; aqui basta o acesso de leitura.
            'escolar_operacao'    => ['module' => 'gestao-escolar', 'action' => 'ver'],
            'escolar_config_get'  => ['module' => 'gestao-escolar', 'action' => 'gerir_propinas', 'method' => 'GET'],
            'escolar_config_save' => ['module' => 'gestao-escolar', 'action' => 'gerir_propinas'],
        ];
    }
}
