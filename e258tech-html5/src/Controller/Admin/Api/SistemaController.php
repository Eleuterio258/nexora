<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class SistemaController
{
    public function sistemaCidadeSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'country_id' => $request->int('country_id'),
            'nome' => $request->string('nome'),
        ];

        return $d->result(fn() => $d->sistema->createCity($payload));
    }

    public function sistemaEmailTemplateSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'codigo' => $request->string('codigo'),
            'assunto' => $request->string('assunto'),
            'corpo' => $request->string('corpo'),
        ];

        return $d->result(fn() => $d->sistema->createEmailTemplate($payload));
    }

    public function sistemaIdiomaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'codigo' => $request->string('codigo'),
            'nome' => $request->string('nome'),
        ];

        return $d->result(fn() => $d->sistema->createLanguage($payload));
    }

    public function sistemaIntegracaoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'codigo' => $request->string('codigo'),
            'nome' => $request->string('nome'),
            'configuracao' => $request->string('configuracao') ?: null,
        ];

        return $d->result(fn() => $d->sistema->createIntegration($payload));
    }

    public function sistemaMoedaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'codigo' => $request->string('codigo'),
            'nome' => $request->string('nome'),
            'simbolo' => $request->string('simbolo') ?: null,
        ];

        return $d->result(fn() => $d->sistema->createCurrency($payload));
    }

    public function sistemaPaisSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'codigo' => $request->string('codigo'),
            'nome' => $request->string('nome'),
        ];

        return $d->result(fn() => $d->sistema->createCountry($payload));
    }

    public function sistemaSettingSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'chave' => $request->string('chave'),
            'valor' => $request->string('valor') ?: null,
            'escopo' => $request->string('escopo') ?: 'tenant',
        ];

        return $d->result(fn() => $d->sistema->saveSetting($payload));
    }

    public function sistemaSmsTemplateSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'codigo' => $request->string('codigo'),
            'corpo' => $request->string('corpo'),
        ];

        return $d->result(fn() => $d->sistema->createSmsTemplate($payload));
    }

    public function sistemaTaxaCambioSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'from_currency_id' => $request->int('from_currency_id') ?? 0,
            'to_currency_id' => $request->int('to_currency_id') ?? 0,
            'rate' => $request->float('rate') ?? 0,
            'rate_date' => $request->string('rate_date') ?: null,
        ];

        return $d->result(fn() => $d->sistema->createExchangeRate($payload));
    }
}
