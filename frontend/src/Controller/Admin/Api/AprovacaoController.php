<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class AprovacaoController
{
    // ── Flows de aprovação ────────────────────────────────────────────────────

    public function aprovacaoFlows(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->aprovacao->execute('flows.listar', null, $request->all()));
    }

    public function aprovacaoFlowCriar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->aprovacao->execute('flows.criar', null, $request->all()));
    }

    public function aprovacaoFlowObter(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->aprovacao->execute('flows.obter', $request->int('id'), []));
    }

    public function aprovacaoFlowSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->aprovacao->execute('flows.save', $request->int('id'), $request->all()));
    }

    public function aprovacaoFlowDelete(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->aprovacao->execute('flows.delete', $request->int('id'), []));
    }

    // ── Pedidos de aprovação ──────────────────────────────────────────────────

    public function aprovacaoRequests(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->aprovacao->execute('requests.listar', null, $request->all()));
    }

    public function aprovacaoPendentes(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->aprovacao->execute('requests.pendentes', null, []));
    }

    public function aprovacaoRequestObter(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->aprovacao->execute('requests.obter', $request->int('id'), []));
    }

    public function aprovacaoDecidir(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->aprovacao->execute('requests.decidir', $request->int('id'), $request->all()));
    }

    public function aprovacaoCancelar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->aprovacao->execute('requests.cancelar', $request->int('id'), $request->all()));
    }
}
