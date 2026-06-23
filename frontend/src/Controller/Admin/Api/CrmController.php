<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;
use E258Tech\Infrastructure\Auth\PhpSessionAuthorization;

final class CrmController
{
    public function atividadeConcluir(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->activities->complete($request->int('id') ?? 0));
    }

    public function atividadeSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');
        $action = $id ? 'editar' : 'criar';
        if (!(new PhpSessionAuthorization())->can('crm', $action)) {
            return new ApiResult(['erro' => 'Sem permissao para executar esta acao.'], 403);
        }

        $payload = [
            'lead_id' => $request->int('lead_id'),
            'oportunidade_id' => $request->int('oportunidade_id'),
            'tipo' => $request->string('tipo', 'nota') ?: 'nota',
            'titulo' => $request->string('titulo'),
            'descricao' => $request->string('descricao') ?: null,
            'data_atividade' => $request->string('data_atividade') ?: null,
            'responsavel' => $request->string('responsavel') ?: null,
        ];

        return $d->result(fn() => $d->activities->save($id, $payload));
    }

    public function leadConverter(Request $request, AdminApiDependencies $d): ApiResult
    {
        $createOpportunity = $request->bool('criar_oportunidade');
        $payload = ['criar_oportunidade' => $createOpportunity];

        if ($createOpportunity) {
            $title = $request->string('oportunidade_titulo');
            $value = $request->float('valor_estimado');
            $currency = $request->string('moeda');

            if ($title !== '') {
                $payload['oportunidade_titulo'] = $title;
            }
            if ($value !== null) {
                $payload['valor_estimado'] = $value;
            }
            if ($currency !== '') {
                $payload['moeda'] = $currency;
            }
        }

        return $d->result(
            fn() => $d->leads->convert($request->int('id') ?? 0, $payload)
        );
    }

    public function leadDelete(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->leads->delete($request->int('id') ?? 0));
    }

    public function leadMover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->leads->move(
                $request->int('id') ?? 0,
                $request->string('estado')
            )
        );
    }

    public function leadSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');
        $action = $id ? 'editar' : 'criar';

        $authorization = new PhpSessionAuthorization();
        if (!$authorization->can('crm', $action)) {
            return new ApiResult(['erro' => 'Sem permissao para executar esta acao.'], 403);
        }

        $payload = [
            'nome' => $request->string('nome'),
            'empresa' => $request->string('empresa') ?: null,
            'email' => $request->string('email') ?: null,
            'telefone' => $request->string('telefone') ?: null,
            'origem' => $request->string('origem', 'outro') ?: 'outro',
            'responsavel' => $request->string('responsavel') ?: null,
            'notas' => $request->string('notas') ?: null,
        ];

        return $d->result(fn() => $d->leads->save($id, $payload));
    }

    public function oportunidadeDelete(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->opportunities->delete($request->int('id') ?? 0));
    }

    public function oportunidadeMover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->opportunities->move(
                $request->int('id') ?? 0,
                $request->string('estagio')
            )
        );
    }

    public function oportunidadePerder(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->opportunities->markLost(
                $request->int('id') ?? 0,
                $request->string('motivo_perda') ?: null
            )
        );
    }

    public function oportunidadeSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');
        $action = $id ? 'editar' : 'criar';
        if (!(new PhpSessionAuthorization())->can('crm', $action)) {
            return new ApiResult(['erro' => 'Sem permissao para executar esta acao.'], 403);
        }

        $payload = [
            'titulo' => $request->string('titulo'),
            'lead_id' => $request->int('lead_id'),
            'cliente_id' => $request->int('cliente_id'),
            'valor_estimado' => $request->float('valor_estimado') ?? 0,
            'moeda' => $request->string('moeda', 'MZN') ?: 'MZN',
            'probabilidade' => $request->int('probabilidade') ?? 0,
            'data_fecho_prevista' => $request->string('data_fecho_prevista') ?: null,
            'responsavel' => $request->string('responsavel') ?: null,
            'descricao' => $request->string('descricao') ?: null,
        ];

        return $d->result(fn() => $d->opportunities->save($id, $payload));
    }
}
