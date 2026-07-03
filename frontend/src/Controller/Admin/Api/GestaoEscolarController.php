<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;
final class GestaoEscolarController
{
    public function escolarOperacao(Request $request, AdminApiDependencies $d): ApiResult
    {
        $operation = $request->all()['operation'] ?? $request->string('operation');
        $payload = $request->all()['payload'] ?? [];
        return $d->result(fn() => $d->school->execute(
            $operation,
            $request->int('id'),
            is_array($payload) ? $payload : []
        ));
    }

    public function escolarConfigGet(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->school->getFinancialConfig());
    }

    public function escolarConfigSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $data = $request->all();
        return $d->result(fn() => $d->school->saveFinancialConfig([
            'conta_bancaria_id'              => isset($data['conta_bancaria_id']) && $data['conta_bancaria_id'] !== '' ? (int) $data['conta_bancaria_id'] : null,
            'centro_custo_id'                => isset($data['centro_custo_id']) && $data['centro_custo_id'] !== '' ? (int) $data['centro_custo_id'] : null,
            'criar_movimento_tesouraria'     => !empty($data['criar_movimento_tesouraria']),
            'criar_movimento_financeiro'     => !empty($data['criar_movimento_financeiro']),
            'criar_lancamento_contabilidade' => !empty($data['criar_lancamento_contabilidade']),
            'conta_debito_id'                => isset($data['conta_debito_id']) && $data['conta_debito_id'] !== '' ? (int) $data['conta_debito_id'] : null,
            'conta_credito_id'               => isset($data['conta_credito_id']) && $data['conta_credito_id'] !== '' ? (int) $data['conta_credito_id'] : null,
            'criar_recibo_faturacao'         => !empty($data['criar_recibo_faturacao']),
            'customer_group_id'              => isset($data['customer_group_id']) && $data['customer_group_id'] !== '' ? (int) $data['customer_group_id'] : null,
        ]));
    }
}
