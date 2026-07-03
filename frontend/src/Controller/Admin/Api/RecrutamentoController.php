<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class RecrutamentoController
{
    public function vagaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $data = $request->all();
        $filterList = static fn(string $key): array => array_values(array_filter(
            array_map('trim', (array) ($data[$key] ?? []))
        ));

        return $d->result(fn() => $d->recruitment->saveVacancy($id, [
            'titulo' => $request->string('titulo'),
            'area' => $request->string('area'),
            'tipo' => $request->string('tipo', 'Estagio'),
            'regime' => $request->string('regime', 'Presencial'),
            'local' => $request->string('local'),
            'num_vagas' => max(1, $request->int('num_vagas') ?? 1),
            'prazo' => $request->string('prazo') ?: null,
            'ativa' => $request->has('ativa'),
            'descricao' => $request->string('descricao'),
            'sobre_funcao' => $request->string('sobre_funcao') ?: null,
            'responsabilidades' => $filterList('responsabilidades'),
            'req_obrigatorios' => $filterList('req_obrigatorios'),
            'req_preferenciais' => $filterList('req_preferenciais'),
            'oferece' => $filterList('oferece'),
        ]));
    }

    public function vagaDelete(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->recruitment->deleteVacancy($request->int('id') ?? 0));
    }

    public function vagaToggle(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->recruitment->toggleVacancy($request->int('id') ?? 0));
    }

    public function candidaturaAvaliar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->recruitment->evaluateApplication(
                $request->int('id') ?? 0,
                $request->int('score') ?? 0,
                $request->string('nota') ?: null
            )
        );
    }

    public function candidaturaMover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->recruitment->moveApplication(
                $request->int('id') ?? 0,
                $request->string('estado')
            )
        );
    }

    public function entrevistaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $format = $request->string('formato');
        return $d->result(
            fn() => $d->recruitment->scheduleInterview(
                $request->int('id') ?? 0,
                [
                    'data' => $request->string('data'),
                    'formato' => $format ?: null,
                    'local' => $format ?: null,
                    'link' => $request->string('link') ?: null,
                    'notas' => $request->string('notas') ?: null,
                ]
            )
        );
    }

    public function notaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->recruitment->addNote(
                $request->int('id') ?? 0,
                $request->string('conteudo')
            )
        );
    }

    public function recrutamentoCampoCustomSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');
        $opcoes = array_values(array_filter(array_map('trim', explode("\n", $request->string('opcoes')))));

        return $d->result(fn() => $d->recruitment->saveCustomField($id, [
            'codigo' => $request->string('codigo'),
            'label' => $request->string('label'),
            'tipo' => $request->string('tipo', 'texto'),
            'opcoes' => $opcoes,
            'obrigatorio' => $request->bool('obrigatorio'),
            'ordem' => $request->int('ordem') ?? 0,
            'ativo' => $request->bool('ativo'),
        ]));
    }

    public function recrutamentoCampoCustomDelete(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->recruitment->deleteCustomField($request->int('id') ?? 0));
    }

    public function recrutamentoNotificacoesSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->recruitment->saveNotificationConfig([
            'canal_email' => $request->bool('canal_email'),
            'canal_sms' => $request->bool('canal_sms'),
            'notificar_candidatura_recebida' => $request->bool('notificar_candidatura_recebida'),
            'notificar_em_analise' => $request->bool('notificar_em_analise'),
            'notificar_entrevista_agendada' => $request->bool('notificar_entrevista_agendada'),
            'notificar_aprovada' => $request->bool('notificar_aprovada'),
            'notificar_rejeitada' => $request->bool('notificar_rejeitada'),
        ]));
    }

    public function recrutamentoContactoLido(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->recruitment->markContactAsRead($request->int('id') ?? 0));
    }

    public function candidaturaContratar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->recruitment->contratar($request->int('id') ?? 0));
    }
}
