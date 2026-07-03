<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;
final class TesourariaController
{
    public function tesourariaOperacao(Request $request, AdminApiDependencies $d): ApiResult
    {
        $operation = $request->string('operation');
        $payload = $request->all()['payload'] ?? [];
        return $d->result(fn() => $d->tesouraria->execute(
            $operation,
            $request->int('id'),
            is_array($payload) ? $payload : []
        ));
    }
}
