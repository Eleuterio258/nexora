<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;
use E258Tech\Infrastructure\Auth\PhpSessionAuthorization;

final class NotificacoesController
{
    public function notificacoesOperacao(Request $request, AdminApiDependencies $d): ApiResult
    {
        $operation = $request->string('operation');
        $action = match (true) {
            str_ends_with($operation, '.update') => 'editar',
            str_ends_with($operation, '.send')   => 'criar',
            default                              => 'criar',
        };
        $authorization = new PhpSessionAuthorization();
        if (!$authorization->can('notificacoes', $action)) {
            return new ApiResult(['erro' => 'Sem permissao para executar esta acao.'], 403);
        }
        $payload = $request->all()['payload'] ?? [];
        return $d->result(fn() => $d->notificacoes->execute(
            $operation, $request->int('id'), is_array($payload) ? $payload : []
        ));
    }
}
