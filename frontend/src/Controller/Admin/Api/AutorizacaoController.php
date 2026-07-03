<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class AutorizacaoController
{
    public function cargoEstado(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->authorization->setRoleState(
                $request->int('id') ?? 0,
                $request->bool('ativo')
            ),
            'error'
        );
    }

    public function cargoPermissoes(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->authorization->updateRolePermissions(
                $request->int('id') ?? 0,
                $d->normalizedPermissions($request->all()['permissoes'] ?? [])
            ),
            'error'
        );
    }

    public function cargoPermissoesGet(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->authorization->rolePermissions($request->int('id') ?? 0),
            'error'
        );
    }

    public function cargoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        return $d->result(
            fn() => $d->authorization->saveRole(
                $id,
                $request->string('nome'),
                $request->string('descricao') ?: null
            ),
            'error'
        );
    }

    public function utilizadorCargo(Request $request, AdminApiDependencies $d): ApiResult
    {
        $data = $request->all();
        $roleId = array_key_exists('cargo_id', $data) && $data['cargo_id'] !== null
            ? $request->int('cargo_id')
            : null;
        if (($data['cargo_id'] ?? null) !== null && $roleId === null) {
            return new ApiResult(['error' => 'Cargo invalido.'], 422);
        }

        return $d->result(
            fn() => $d->authorization->assignRole($request->int('id') ?? 0, $roleId),
            'error'
        );
    }

    public function utilizadorEstado(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->authorization->setUserState(
                $request->int('id') ?? 0,
                $request->string('acao')
            ),
            'error'
        );
    }

    public function utilizadorPermissoes(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->authorization->updateUserPermissions(
                $request->int('id') ?? 0,
                $d->normalizedPermissions($request->all()['permissoes'] ?? [])
            ),
            'error'
        );
    }

    public function utilizadorSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = [
            'nome' => $request->string('nome'),
            'telefone' => $request->string('telefone') ?: null,
        ];

        $escopo = $request->string('escopo');
        if (in_array($escopo, ['erp', 'escola'], true)) {
            $payload['escopo'] = $escopo;
        }

        if (!$id) {
            $payload['email'] = $request->string('email');
            $payload['password'] = $request->string('password');
        }

        return $d->result(
            fn() => $d->authorization->saveUser($id, $payload),
            'error'
        );
    }

    public function utilizadorTipo(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->authorization->setUserTipo(
                $request->int('id') ?? 0,
                $request->string('tipo')
            ),
            'error'
        );
    }

    public function utilizadorResetPassword(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->authorization->resetUserPassword(
                $request->int('id') ?? 0,
                $request->string('password')
            ),
            'error'
        );
    }
}
