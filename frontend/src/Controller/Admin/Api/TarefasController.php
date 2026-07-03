<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class TarefasController
{
    public function quadroSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->tarefas->saveQuadro(
            $request->int('id'),
            [
                'titulo'    => $request->string('titulo'),
                'descricao' => $request->string('descricao') ?: null,
                'cor'       => $request->string('cor') ?: null,
            ]
        ));
    }

    public function quadroDelete(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->tarefas->deleteQuadro($request->int('id') ?? 0));
    }

    public function quadroArquivar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->tarefas->archiveQuadro($request->int('id') ?? 0));
    }

    public function listaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->tarefas->saveLista(
            $request->int('id'),
            [
                'titulo'    => $request->string('titulo'),
                'quadro_id' => $request->int('quadro_id') ?? 0,
            ]
        ));
    }

    public function listaDelete(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->tarefas->deleteLista($request->int('id') ?? 0));
    }

    public function listaReordenar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->tarefas->reorderListas($request->all()));
    }

    public function cartaoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->tarefas->saveCartao(
            $request->int('id'),
            [
                'titulo'      => $request->string('titulo'),
                'descricao'   => $request->string('descricao') ?: null,
                'lista_id'    => $request->int('lista_id') ?? 0,
                'data_inicio' => $request->string('data_inicio') ?: null,
                'data_fim'    => $request->string('data_fim') ?: null,
                'prioridade'  => $request->string('prioridade') ?: 'media',
            ]
        ));
    }

    public function cartaoMover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->tarefas->moveCartao(
            $request->int('id') ?? 0,
            [
                'lista_id' => $request->int('lista_id') ?? 0,
                'posicao'  => $request->int('posicao') ?? 0,
            ]
        ));
    }

    public function cartaoConcluir(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->tarefas->concludeCartao($request->int('id') ?? 0));
    }

    public function cartaoDelete(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->tarefas->deleteCartao($request->int('id') ?? 0));
    }
}
