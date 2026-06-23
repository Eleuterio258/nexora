<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class ContabilidadeController
{
    public function contabAmortizacaoCancelar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->contabilidade->cancelDepreciation($request->int('id') ?? 0));
    }

    public function contabAmortizacaoProcessar(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'fiscal_period_id' => $request->int('fiscal_period_id'),
            'accounting_journal_id' => $request->int('accounting_journal_id'),
        ];

        return $d->result(fn() => $d->contabilidade->processDepreciation($payload));
    }

    public function contabAnoFiscalFechar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->contabilidade->closeFiscalYear($request->int('id') ?? 0));
    }

    public function contabAnoFiscalSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'data_inicio' => $request->string('data_inicio') ?: null,
                'data_fim' => $request->string('data_fim') ?: null,
            ]
            : [
                'ano' => $request->int('ano'),
                'data_inicio' => $request->string('data_inicio'),
                'data_fim' => $request->string('data_fim'),
            ];

        return $d->result(fn() => $d->contabilidade->saveFiscalYear($id, $payload));
    }

    public function contabAtivoFixoAlienar(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'data_alienacao' => $request->string('data_alienacao'),
            'valor_alienacao' => $request->float('valor_alienacao') ?? 0,
        ];

        return $d->result(fn() => $d->contabilidade->disposeFixedAsset($request->int('id') ?? 0, $payload));
    }

    public function contabAtivoFixoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'nome' => $request->string('nome') ?: null,
                'depreciation_account_id' => $request->int('depreciation_account_id'),
                'accumulated_depreciation_account_id' => $request->int('accumulated_depreciation_account_id'),
                'valor_residual' => $request->float('valor_residual'),
                'vida_util_meses' => $request->int('vida_util_meses'),
            ]
            : [
                'chart_account_id' => $request->int('chart_account_id'),
                'depreciation_account_id' => $request->int('depreciation_account_id'),
                'accumulated_depreciation_account_id' => $request->int('accumulated_depreciation_account_id'),
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'data_aquisicao' => $request->string('data_aquisicao'),
                'valor_aquisicao' => $request->float('valor_aquisicao'),
                'valor_residual' => $request->float('valor_residual') ?? 0,
                'vida_util_meses' => $request->int('vida_util_meses'),
                'metodo' => $request->string('metodo') ?: null,
            ];

        return $d->result(fn() => $d->contabilidade->saveFixedAsset($id, $payload));
    }

    public function contabContaRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->contabilidade->deleteAccount($request->int('id') ?? 0));
    }

    public function contabContaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'parent_id' => $request->int('parent_id'),
                'codigo' => $request->string('codigo') ?: null,
                'nome' => $request->string('nome') ?: null,
                'account_type_id' => $request->int('account_type_id'),
                'aceita_lancamento' => $request->bool('aceita_lancamento'),
                'ativo' => $request->bool('ativo'),
            ]
            : [
                'parent_id' => $request->int('parent_id'),
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'account_type_id' => $request->int('account_type_id'),
                'aceita_lancamento' => $request->bool('aceita_lancamento'),
            ];

        return $d->result(fn() => $d->contabilidade->saveAccount($id, $payload));
    }

    public function contabDiarioSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'nome' => $request->string('nome') ?: null,
                'tipo' => $request->string('tipo') ?: null,
                'ativo' => $request->has('ativo') ? $request->bool('ativo') : null,
            ]
            : [
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'tipo' => $request->string('tipo'),
            ];

        return $d->result(fn() => $d->contabilidade->saveJournal($id, $payload));
    }

    public function contabEncerramentoConfirmar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->contabilidade->confirmPeriodClosing($request->int('id') ?? 0));
    }

    public function contabEncerramentoIniciar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->contabilidade->startPeriodClosing($request->int('fiscal_period_id') ?? 0));
    }

    public function contabEncerramentoReabrir(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->contabilidade->reopenPeriodClosing(
            $request->int('id') ?? 0,
            $request->string('justificacao')
        ));
    }

    public function contabEncerramentoVerificar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->contabilidade->runPeriodClosingChecks($request->int('id') ?? 0));
    }

    public function contabGrupoImpostoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'codigo' => $request->string('codigo') ?: null,
                'nome' => $request->string('nome') ?: null,
                'ativo' => $request->has('ativo') ? $request->bool('ativo') : null,
            ]
            : [
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
            ];

        return $d->result(fn() => $d->contabilidade->saveTaxGroup($id, $payload));
    }

    public function contabLancamentoEstornar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->contabilidade->reverseJournalEntry($request->int('id') ?? 0));
    }

    public function contabLancamentoLinhaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id') ?? 0;

        $payload = [
            'account_id' => $request->int('account_id') ?? 0,
            'descricao' => $request->string('descricao') ?: null,
            'debit' => $request->float('debit') ?? 0,
            'credit' => $request->float('credit') ?? 0,
        ];

        return $d->result(fn() => $d->contabilidade->addJournalEntryLine($id, $payload));
    }

    public function contabLancamentoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');
        $data = $request->all();

        $linhas = array_map(static function (array $linha): array {
            return [
                'account_id' => (int) ($linha['account_id'] ?? 0),
                'descricao' => isset($linha['descricao']) && $linha['descricao'] !== '' ? (string) $linha['descricao'] : null,
                'debit' => (float) ($linha['debit'] ?? 0),
                'credit' => (float) ($linha['credit'] ?? 0),
            ];
        }, $data['linhas'] ?? []);

        if ($id) {
            $payload = [
                'entry_date' => $request->string('entry_date') ?: null,
                'descricao' => $request->string('descricao') ?: null,
                'linhas' => $linhas,
            ];

            return $d->result(fn() => $d->contabilidade->updateJournalEntry($id, $payload));
        }

        $payload = [
            'accounting_journal_id' => $request->int('accounting_journal_id') ?? 0,
            'fiscal_period_id' => $request->int('fiscal_period_id') ?? 0,
            'entry_date' => $request->string('entry_date'),
            'descricao' => $request->string('descricao'),
            'referencia_tipo' => $request->string('referencia_tipo') ?: null,
            'referencia_id' => $request->int('referencia_id'),
            'linhas' => $linhas,
        ];

        return $d->result(fn() => $d->contabilidade->createJournalEntry($payload));
    }

    public function contabOrcamentoRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->contabilidade->deleteBudget($request->int('id') ?? 0));
    }

    public function contabOrcamentoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'valor_orcamentado' => $request->float('valor_orcamentado'),
            ]
            : [
                'chart_account_id' => $request->int('chart_account_id'),
                'fiscal_year_id' => $request->int('fiscal_year_id'),
                'mes' => $request->int('mes'),
                'valor_orcamentado' => $request->float('valor_orcamentado'),
            ];

        return $d->result(fn() => $d->contabilidade->saveBudget($id, $payload));
    }

    public function contabPeriodoAbrir(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->contabilidade->openFiscalPeriod($request->int('id') ?? 0));
    }

    public function contabPeriodoFechar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->contabilidade->closeFiscalPeriod($request->int('id') ?? 0));
    }

    public function contabRegraTaxaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id') ?? 0;

        $payload = [
            'valor_minimo' => $request->float('valor_minimo') ?? 0,
            'valor_maximo' => $request->float('valor_maximo'),
            'taxa' => $request->float('taxa') ?? 0,
            'ordem' => $request->int('ordem') ?? 0,
        ];

        return $d->result(fn() => $d->contabilidade->addTaxRule($id, $payload));
    }

    public function contabRelatorioGerar(Request $request, AdminApiDependencies $d): ApiResult
    {
        $tipo = $request->string('tipo');
        $parametros = $request->all()['parametros'] ?? [];

        return $d->result(fn() => $d->contabilidade->generateReport($tipo, is_array($parametros) ? $parametros : []));
    }

    public function contabTaxaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'codigo' => $request->string('codigo') ?: null,
                'nome' => $request->string('nome') ?: null,
                'taxa' => $request->float('taxa'),
                'tipo' => $request->string('tipo') ?: null,
                'tax_group_id' => $request->int('tax_group_id'),
                'ativo' => $request->has('ativo') ? $request->bool('ativo') : null,
            ]
            : [
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'taxa' => $request->float('taxa') ?? 0,
                'tipo' => $request->string('tipo') ?: 'iva',
                'tax_group_id' => $request->int('tax_group_id'),
            ];

        return $d->result(fn() => $d->contabilidade->saveTax($id, $payload));
    }

    public function contabTransacaoImpostoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'tax_id' => $request->int('tax_id'),
            'referencia_tipo' => $request->string('referencia_tipo'),
            'referencia_id' => $request->int('referencia_id'),
            'fiscal_period_id' => $request->int('fiscal_period_id'),
            'base_tributavel' => $request->float('base_tributavel') ?? 0,
            'taxa_aplicada' => $request->float('taxa_aplicada'),
            'transaction_date' => $request->string('transaction_date'),
        ];

        return $d->result(fn() => $d->contabilidade->registerTaxTransaction($payload));
    }

    public function contabTipoContaRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->contabilidade->deleteAccountType($request->int('id') ?? 0));
    }

    public function contabTipoContaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'codigo' => $request->string('codigo') ?: null,
                'nome' => $request->string('nome') ?: null,
                'classe' => $request->string('classe') ?: null,
                'natureza' => $request->string('natureza') ?: null,
                'ativo' => $request->bool('ativo'),
            ]
            : [
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'classe' => $request->string('classe'),
                'natureza' => $request->string('natureza'),
            ];

        return $d->result(fn() => $d->contabilidade->saveAccountType($id, $payload));
    }
}
