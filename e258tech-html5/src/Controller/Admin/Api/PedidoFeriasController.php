<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class PedidoFeriasController
{
    public function pedidoFeriasCriar(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'tipo_id'    => $request->int('tipo_id') ?? 0,
            'data_inicio' => $request->string('data_inicio'),
            'data_fim'   => $request->string('data_fim'),
            'motivo'     => $request->string('motivo') ?: null,
        ];

        return $d->result(fn() => $d->rh->criarPedidoFerias($payload));
    }

    public function pedidoFeriasCancelar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->cancelarPedidoFerias($request->int('id') ?? 0));
    }
}
