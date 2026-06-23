<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;
use E258Tech\Infrastructure\Auth\PhpSessionAuthorization;

final class TesourariaController
{
    public function tesourariaOperacao(Request $request, AdminApiDependencies $d): ApiResult
    {
        $operation = $request->string('operation');
        $action = str_ends_with($operation, '.fechar') ? 'fechar'
            : (str_ends_with($operation, '.create') ? 'criar' : 'editar');
        $authorization = new PhpSessionAuthorization();
        if (!$authorization->can('tesouraria', $action)) {
            return new ApiResult(['erro' => 'Sem permissao para executar esta acao.'], 403);
        }
        $payload = $request->all()['payload'] ?? [];
        return $d->result(fn() => $d->tesouraria->execute(
            $operation,
            $request->int('id'),
            is_array($payload) ? $payload : []
        ));
    }
}
