<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class ClientesController
{
    public function clienteContactoDelete(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->customers->deleteContact(
                $request->int('cliente_id') ?? 0,
                $request->int('id') ?? 0
            )
        );
    }

    public function clienteContactoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'nome' => $request->string('nome') ?: null,
            'cargo' => $request->string('cargo') ?: null,
            'telefone' => $request->string('telefone') ?: null,
            'email' => $request->string('email') ?: null,
            'principal' => $request->bool('principal'),
        ];

        return $d->result(
            fn() => $d->customers->saveContact(
                $request->int('cliente_id') ?? 0,
                $request->int('id'),
                $payload
            )
        );
    }

    public function clienteCreditoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'limite' => $request->float('limite') ?? 0,
            'motivo' => $request->string('motivo'),
        ];

        return $d->result(
            fn() => $d->customers->updateCreditLimit($request->int('cliente_id') ?? 0, $payload)
        );
    }

    public function clienteEnderecoDelete(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->customers->deleteAddress(
                $request->int('cliente_id') ?? 0,
                $request->int('id') ?? 0
            )
        );
    }

    public function clienteEnderecoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'tipo' => $request->string('tipo') ?: null,
            'pais' => $request->string('pais') ?: null,
            'provincia' => $request->string('provincia') ?: null,
            'cidade' => $request->string('cidade') ?: null,
            'endereco' => $request->string('endereco') ?: null,
            'codigo_postal' => $request->string('codigo_postal') ?: null,
            'principal' => $request->bool('principal'),
        ];

        return $d->result(
            fn() => $d->customers->saveAddress(
                $request->int('cliente_id') ?? 0,
                $request->int('id'),
                $payload
            )
        );
    }

    public function clienteEstado(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->customers->setStatus(
                $request->int('id') ?? 0,
                $request->string('action')
            )
        );
    }

    public function clienteGrupoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'nome' => $request->string('nome') ?: null,
                'descricao' => $request->string('descricao') ?: null,
                'ativo' => $request->bool('ativo'),
            ]
            : [
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'descricao' => $request->string('descricao') ?: null,
            ];

        return $d->result(fn() => $d->customers->saveGroup($id, $payload));
    }

    public function clientePagamentoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'metodo' => $request->string('metodo'),
            'valor' => $request->float('valor') ?? 0,
            'referencia' => $request->string('referencia') ?: null,
            'observacao' => $request->string('observacao') ?: null,
        ];

        return $d->result(
            fn() => $d->customers->registerPayment($request->int('cliente_id') ?? 0, $payload)
        );
    }

    public function clienteSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = [
            'codigo' => $request->string('codigo') ?: null,
            'nome' => $request->string('nome'),
            'nuit' => $request->string('nuit') ?: null,
            'email' => $request->string('email') ?: null,
            'telefone' => $request->string('telefone') ?: null,
            'customer_group_id' => $request->int('customer_group_id'),
            'observacao' => $request->string('observacao') ?: null,
        ];

        return $d->result(fn() => $d->customers->save($id, $payload));
    }
}
