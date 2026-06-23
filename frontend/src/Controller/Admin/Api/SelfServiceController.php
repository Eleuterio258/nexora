<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class SelfServiceController
{
    // ── Chat ─────────────────────────────────────────────────────────────────

    public function selfServiceChatConversas(Request $request, AdminApiDependencies $d): ApiResult
    {
        return new ApiResult($d->selfService->listarConversas(), 200);
    }

    public function selfServiceChatCriar(Request $request, AdminApiDependencies $d): ApiResult
    {
        $tipo  = $request->string('tipo') ?: 'individual';
        $nome  = $request->string('nome') ?: null;
        $parts = array_map('intval', (array)($request->all()['participantes'] ?? []));
        return new ApiResult($d->selfService->criarConversa($tipo, $nome, $parts), 200);
    }

    public function selfServiceChatMensagens(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = (int)$request->string('conversa_id');
        return new ApiResult($d->selfService->listarMensagens($id), 200);
    }

    public function selfServiceChatEnviar(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id      = (int)$request->string('conversa_id');
        $conteudo = $request->string('conteudo');
        return new ApiResult($d->selfService->enviarMensagem($id, $conteudo), 200);
    }

    // ── Assiduidade ───────────────────────────────────────────────────────────

    public function selfServiceJustificacao(Request $request, AdminApiDependencies $d): ApiResult
    {
        return new ApiResult($d->selfService->criarJustificacao(
            $request->string('tipo') ?: 'falta',
            $request->string('data'),
            $request->string('motivo')
        ), 200);
    }

    // ── Perfil ────────────────────────────────────────────────────────────────

    public function selfServicePerfilUpdate(Request $request, AdminApiDependencies $d): ApiResult
    {
        return new ApiResult($d->selfService->actualizarPerfil(
            $request->string('nome') ?: null,
            $request->string('telefone') ?: null
        ), 200);
    }

    public function selfServiceSenha(Request $request, AdminApiDependencies $d): ApiResult
    {
        return new ApiResult($d->selfService->alterarSenha(
            $request->string('senha_actual'),
            $request->string('senha_nova')
        ), 200);
    }

    // ── Utilizadores ─────────────────────────────────────────────────────────

    public function selfServiceUtilizadores(Request $request, AdminApiDependencies $d): ApiResult
    {
        return new ApiResult($d->selfService->listarUtilizadores(), 200);
    }
}
