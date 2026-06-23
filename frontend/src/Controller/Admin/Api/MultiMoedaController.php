<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;
use E258Tech\Infrastructure\Auth\PhpSessionAuthorization;

final class MultiMoedaController
{
    public function multiMoedaOperacao(Request $request, AdminApiDependencies $d): ApiResult
    {
        $operation = $request->string('operation');
        $action = match (true) {
            str_ends_with($operation, '.remove') => 'eliminar',
            str_ends_with($operation, '.create') => 'criar',
            str_ends_with($operation, '.add')    => 'criar',
            default                              => 'criar',
        };
        $authorization = new PhpSessionAuthorization();
        if (!$authorization->can('multi-moeda', $action)) {
            return new ApiResult(['erro' => 'Sem permissao para executar esta acao.'], 403);
        }
        $payload = $request->all()['payload'] ?? [];
        return $d->result(fn() => $d->multiMoeda->execute(
            $operation, $request->int('id'), is_array($payload) ? $payload : []
        ));
    }
}
