<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;
use E258Tech\Infrastructure\Auth\PhpSessionAuthorization;

final class EmpresaController
{
    public function empresaBranchSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $branchId = $request->int('branch_id');
        $action = $branchId ? 'editar' : 'criar';
        if (!(new PhpSessionAuthorization())->can('empresa', $action)) {
            return new ApiResult(['error' => 'Sem permissao para executar esta acao.'], 403);
        }

        if ($branchId) {
            return $d->result(
                fn() => $d->companies->setBranchState(
                    $request->int('id') ?? 0,
                    $branchId,
                    $request->string('status')
                ),
                'error'
            );
        }

        return $d->result(
            fn() => $d->companies->createBranch(
                $request->int('id') ?? 0,
                [
                    'codigo' => $request->string('codigo'),
                    'nome' => $request->string('nome'),
                    'principal' => $request->has('principal'),
                ]
            ),
            'error'
        );
    }

    public function empresaFiscalSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->companies->updateTaxInfo(
                $request->int('id') ?? 0,
                [
                    'nuit' => $request->string('nuit'),
                    'regime_iva' => $request->string('regime_iva') ?: null,
                    'taxa_iva_padrao' => $request->float('taxa_iva_padrao'),
                    'inicio_atividade' => $request->string('inicio_atividade') ?: null,
                    'reparticao_fiscal' => $request->string('reparticao_fiscal') ?: null,
                ]
            ),
            'error'
        );
    }

    public function empresaLicencaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->companies->createLicense(
                $request->int('id') ?? 0,
                [
                    'plano' => $request->string('plano'),
                    'limite_usuarios' => $request->int('limite_usuarios'),
                    'limite_filiais' => $request->int('limite_filiais'),
                    'inicia_em' => $request->string('inicia_em'),
                    'expira_em' => $request->string('expira_em') ?: null,
                ]
            ),
            'error'
        );
    }

    public function empresaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->companies->updateCompany(
                $request->int('id') ?? 0,
                [
                    'nome' => $request->string('nome'),
                    'nome_comercial' => $request->string('nome_comercial') ?: null,
                    'status' => $request->string('status'),
                    'moeda_base' => $request->string('moeda_base') ?: null,
                    'timezone' => $request->string('timezone') ?: null,
                ]
            ),
            'error'
        );
    }
}
