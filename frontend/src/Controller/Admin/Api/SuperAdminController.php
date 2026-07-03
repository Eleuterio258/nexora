<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class SuperAdminController
{
    // Dashboard
    public function superadminDashboard(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->superAdmin->dashboard());
    }

    // Tenants
    public function superadminTenants(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->superAdmin->listTenants([
            'status' => $request->string('status'),
            'search' => $request->string('search'),
            'page' => $request->int('page') ?: 1,
            'limit' => $request->int('limit') ?: 20,
        ]));
    }

    public function superadminTenantSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id') ?? 0;
        return $d->result(fn() => $d->superAdmin->saveTenant($id, [
            'codigo' => $request->string('codigo'),
            'nome' => $request->string('nome'),
            'dominio' => $request->string('dominio') ?: null,
            'plano_id' => $request->int('plano_id'),
            'limite_utilizadores' => $request->int('limite_utilizadores'),
            'limite_armazenamento_gb' => $request->int('limite_armazenamento_gb'),
            'validade_plano' => $request->string('validade_plano') ?: null,
            'metadata' => $request->array('metadata'),
        ]));
    }

    public function superadminTenantDelete(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->superAdmin->deleteTenant($request->int('id') ?? 0));
    }

    public function superadminTenantStatus(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->superAdmin->changeTenantStatus(
            $request->int('id') ?? 0,
            $request->string('status')
        ));
    }

    // Planos
    public function superadminPlans(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->superAdmin->listPlans());
    }

    public function superadminPlanSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id') ?? 0;
        return $d->result(fn() => $d->superAdmin->savePlan($id, [
            'codigo' => $request->string('codigo'),
            'nome' => $request->string('nome'),
            'descricao' => $request->string('descricao') ?: null,
            'preco_mensal' => $request->float('preco_mensal'),
            'preco_anual' => $request->float('preco_anual'),
            'moeda' => $request->string('moeda') ?: 'MZN',
            'limites' => $request->array('limites'),
            'ativo' => $request->bool('ativo'),
        ]));
    }

    public function superadminPlanDelete(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->superAdmin->deletePlan($request->int('id') ?? 0));
    }

    // Modulos
    public function superadminModulesDisponiveis(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->superAdmin->listAvailableModules());
    }

    public function superadminModulesTenant(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->superAdmin->listTenantModules($request->int('tenant_id') ?? 0));
    }

    public function superadminModuleSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->superAdmin->updateTenantModule(
            $request->int('tenant_id') ?? 0,
            $request->string('modulo'),
            $request->bool('ativo'),
            $request->array('config')
        ));
    }

    public function superadminModulesReset(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->superAdmin->resetTenantModules($request->int('tenant_id') ?? 0));
    }

    // Utilizadores globais
    public function superadminUtilizadores(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->superAdmin->listGlobalUsers([
            'tenant_id' => $request->string('tenant_id'),
            'search' => $request->string('search'),
            'page' => $request->int('page') ?: 1,
            'limit' => $request->int('limit') ?: 20,
        ]));
    }

    public function superadminUserTipo(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->authorization->setUserTipo(
            $request->int('id') ?? 0,
            $request->string('tipo')
        ));
    }

    public function superadminUserResetPassword(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->authorization->resetUserPassword(
            $request->int('id') ?? 0,
            $request->string('password')
        ));
    }

    // Próximo número de funcionário para um tenant
    public function superadminProximoNumeroFuncionario(Request $request, AdminApiDependencies $d): ApiResult
    {
        $tenantId = $request->int('tenant_id') ?? 0;
        return $d->result(fn() => $d->superAdmin->proximoNumeroFuncionarioTenant($tenantId));
    }

    // Criar Funcionário em qualquer Tenant
    public function superadminCriarFuncionario(Request $request, AdminApiDependencies $d): ApiResult
    {
        $tenantId = $request->int('tenant_id') ?? 0;
        return $d->result(fn() => $d->superAdmin->criarFuncionarioTenant($tenantId, [
            'nome_completo'      => $request->string('nome_completo'),
            'numero_funcionario' => $request->string('numero_funcionario') ?: null,
            'data_nascimento'    => $request->string('data_nascimento') ?: null,
            'genero'             => $request->string('genero') ?: null,
            'nuit'               => $request->string('nuit') ?: null,
            'telefone'           => $request->string('telefone') ?: null,
            'email'              => $request->string('email') ?: null,
            'endereco'           => $request->string('endereco') ?: null,
            'cargo'              => $request->string('cargo') ?: null,
            'data_admissao'      => $request->string('data_admissao') ?: null,
            'tipo_contrato'      => $request->string('tipo_contrato') ?: null,
            'salario_base'       => $request->float('salario_base'),
            'estado'             => $request->string('estado') ?: 'ativo',
        ]));
    }

    // Configuracoes globais
    public function superadminSettings(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->superAdmin->listGlobalSettings());
    }

    public function superadminSettingSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->superAdmin->saveGlobalSetting(
            $request->string('chave'),
            $request->string('valor') ?: null,
            $request->string('descricao') ?: null
        ));
    }
}
