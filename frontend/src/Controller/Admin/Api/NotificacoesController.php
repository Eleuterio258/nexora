<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;
final class NotificacoesController
{
    public function notificacoesOperacao(Request $request, AdminApiDependencies $d): ApiResult
    {
        $operation = $request->string('operation');
        $payload = $request->all()['payload'] ?? [];
        return $d->result(fn() => $d->notificacoes->execute(
            $operation, $request->int('id'), is_array($payload) ? $payload : []
        ));
    }
}
