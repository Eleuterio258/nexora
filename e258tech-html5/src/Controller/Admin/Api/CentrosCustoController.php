<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class CentrosCustoController
{
    public function centrosCustoAlocacaoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'cost_center_id' => $request->int('cost_center_id'),
            'source_service' => $request->string('source_service'),
            'source_type' => $request->string('source_type'),
            'source_id' => $request->int('source_id'),
            'descricao' => $request->string('descricao') ?: null,
            'valor' => $request->float('valor'),
            'moeda' => $request->string('moeda') ?: null,
            'allocation_percent' => $request->float('allocation_percent'),
            'referencia_tipo' => $request->string('referencia_tipo') ?: null,
            'referencia_id' => $request->int('referencia_id'),
        ];

        return $d->result(fn() => $d->centrosCusto->createAllocation($payload));
    }

    public function centrosCustoCentroRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->centrosCusto->deleteCostCenter($request->int('id') ?? 0));
    }

    public function centrosCustoCentroSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'parent_id' => $request->int('parent_id'),
                'codigo' => $request->string('codigo') ?: null,
                'nome' => $request->string('nome') ?: null,
                'tipo' => $request->string('tipo') ?: null,
                'gestor_user_id' => $request->int('gestor_user_id'),
                'activo' => $request->bool('activo'),
            ]
            : [
                'parent_id' => $request->int('parent_id'),
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'tipo' => $request->string('tipo') ?: null,
                'gestor_user_id' => $request->int('gestor_user_id'),
            ];

        return $d->result(fn() => $d->centrosCusto->saveCostCenter($id, $payload));
    }

    public function centrosCustoOrcamentoRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->centrosCusto->deleteBudget($request->int('id') ?? 0));
    }

    public function centrosCustoOrcamentoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'valor_orcamentado' => $request->float('valor_orcamentado'),
                'moeda' => $request->string('moeda') ?: null,
            ]
            : [
                'cost_center_id' => $request->int('cost_center_id'),
                'ano' => $request->int('ano'),
                'mes' => $request->int('mes'),
                'valor_orcamentado' => $request->float('valor_orcamentado'),
                'moeda' => $request->string('moeda') ?: null,
            ];

        return $d->result(fn() => $d->centrosCusto->saveBudget($id, $payload));
    }
}
