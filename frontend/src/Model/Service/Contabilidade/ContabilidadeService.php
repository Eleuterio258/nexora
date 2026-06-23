<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Contabilidade;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

final class ContabilidadeService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    public function listAccountTypes(array $filters = []): array
    {
        $path = '/api/contabilidade/account-types';
        if ($filters) {
            $path .= '?' . http_build_query($filters);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter os tipos de conta.');

        return $response->body ?? [];
    }

    public function saveAccountType(?int $id, array $payload): array
    {
        if (! $id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '')) {
            throw new OperationException('O código e o nome do tipo de conta são obrigatórios.');
        }
        if (! $id && (($payload['classe'] ?? '') === '' || ($payload['natureza'] ?? '') === '')) {
            throw new OperationException('A classe e a natureza do tipo de conta são obrigatórias.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/contabilidade/account-types/$id", $payload)
            : $this->gateway->request('POST', '/api/contabilidade/account-types', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o tipo de conta.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Tipo de conta actualizado com sucesso.' : 'Tipo de conta criado com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function deleteAccountType(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Tipo de conta inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/contabilidade/account-types/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar o tipo de conta.');

        return ['ok' => true, 'msg' => 'Tipo de conta eliminado com sucesso.'];
    }

    public function listAccounts(array $filters = []): array
    {
        $path = '/api/contabilidade/accounts';
        if ($filters) {
            $path .= '?' . http_build_query($filters);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter o plano de contas.');

        return $response->body ?? [];
    }

    public function saveAccount(?int $id, array $payload): array
    {
        if (! $id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '')) {
            throw new OperationException('O código e o nome da conta são obrigatórios.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/contabilidade/accounts/$id", $payload)
            : $this->gateway->request('POST', '/api/contabilidade/accounts', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar a conta.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Conta actualizada com sucesso.' : 'Conta criada com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function deleteAccount(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Conta inválida.');
        }

        $response = $this->gateway->request('DELETE', "/api/contabilidade/accounts/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar a conta.');

        return ['ok' => true, 'msg' => 'Conta eliminada com sucesso.'];
    }

    public function listFiscalYears(): array
    {
        $response = $this->gateway->request('GET', '/api/contabilidade/fiscal-years');
        $this->ensureSuccess($response, 'Erro ao obter os anos fiscais.');

        return $response->body ?? [];
    }

    public function getFiscalYear(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Ano fiscal inválido.');
        }

        $response = $this->gateway->request('GET', "/api/contabilidade/fiscal-years/$id");
        $this->ensureSuccess($response, 'Erro ao obter o ano fiscal.');

        return $response->body ?? [];
    }

    public function saveFiscalYear(?int $id, array $payload): array
    {
        if (! $id && (($payload['ano'] ?? 0) === 0 || ($payload['data_inicio'] ?? '') === '' || ($payload['data_fim'] ?? '') === '')) {
            throw new OperationException('O ano, a data de início e a data de fim são obrigatórios.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/contabilidade/fiscal-years/$id", $payload)
            : $this->gateway->request('POST', '/api/contabilidade/fiscal-years', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o ano fiscal.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Ano fiscal actualizado com sucesso.' : 'Ano fiscal criado com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function closeFiscalYear(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Ano fiscal inválido.');
        }

        $response = $this->gateway->request('POST', "/api/contabilidade/fiscal-years/$id/fechar");
        $this->ensureSuccess($response, 'Erro ao encerrar o ano fiscal.');

        return ['ok' => true, 'msg' => 'Ano fiscal encerrado com sucesso.'];
    }

    public function listFiscalPeriods(array $filters = []): array
    {
        $path = '/api/contabilidade/fiscal-periods';
        if ($filters) {
            $path .= '?' . http_build_query($filters);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter os períodos fiscais.');

        return $response->body ?? [];
    }

    public function openFiscalPeriod(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Período fiscal inválido.');
        }

        $response = $this->gateway->request('POST', "/api/contabilidade/fiscal-periods/$id/abrir");
        $this->ensureSuccess($response, 'Erro ao reabrir o período fiscal.');

        return ['ok' => true, 'msg' => 'Período fiscal reaberto com sucesso.'];
    }

    public function closeFiscalPeriod(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Período fiscal inválido.');
        }

        $response = $this->gateway->request('POST', "/api/contabilidade/fiscal-periods/$id/fechar");
        $this->ensureSuccess($response, 'Erro ao encerrar o período fiscal.');

        return ['ok' => true, 'msg' => 'Período fiscal encerrado com sucesso.'];
    }

    public function listJournals(): array
    {
        $response = $this->gateway->request('GET', '/api/contabilidade/journals');
        $this->ensureSuccess($response, 'Erro ao obter os diários.');

        return $response->body ?? [];
    }

    public function saveJournal(?int $id, array $payload): array
    {
        if (! $id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '' || ($payload['tipo'] ?? '') === '')) {
            throw new OperationException('O código, o nome e o tipo do diário são obrigatórios.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/contabilidade/journals/$id", $payload)
            : $this->gateway->request('POST', '/api/contabilidade/journals', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o diário.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Diário actualizado com sucesso.' : 'Diário criado com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function listJournalEntries(array $filters = []): array
    {
        $path = '/api/contabilidade/journal-entries';
        if ($filters) {
            $path .= '?' . http_build_query($filters);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter os lançamentos.');

        return $response->body ?? [];
    }

    public function getJournalEntry(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Lançamento inválido.');
        }

        $response = $this->gateway->request('GET', "/api/contabilidade/journal-entries/$id");
        $this->ensureSuccess($response, 'Erro ao obter o lançamento.');

        return $response->body ?? [];
    }

    public function createJournalEntry(array $payload): array
    {
        if (($payload['accounting_journal_id'] ?? 0) === 0 || ($payload['fiscal_period_id'] ?? 0) === 0
            || ($payload['entry_date'] ?? '') === '' || ($payload['descricao'] ?? '') === '') {
            throw new OperationException('O diário, o período, a data e a descrição são obrigatórios.');
        }
        if (count($payload['linhas'] ?? []) < 2) {
            throw new OperationException('O lançamento deve ter pelo menos duas linhas.');
        }

        $response = $this->gateway->request('POST', '/api/contabilidade/journal-entries', $payload);
        $this->ensureSuccess($response, 'Erro ao criar o lançamento.');

        return [
            'ok'     => true,
            'msg'    => 'Lançamento criado com sucesso.',
            'id'     => $response->body['id'] ?? null,
            'numero' => $response->body['numero'] ?? null,
        ];
    }

    public function updateJournalEntry(int $id, array $payload): array
    {
        if ($id <= 0) {
            throw new OperationException('Lançamento inválido.');
        }
        if (count($payload['linhas'] ?? []) < 2) {
            throw new OperationException('O lançamento deve ter pelo menos duas linhas.');
        }

        $response = $this->gateway->request('PUT', "/api/contabilidade/journal-entries/$id", $payload);
        $this->ensureSuccess($response, 'Erro ao actualizar o lançamento.');

        return ['ok' => true, 'msg' => 'Lançamento actualizado com sucesso.'];
    }

    public function reverseJournalEntry(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Lançamento inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/contabilidade/journal-entries/$id");
        $this->ensureSuccess($response, 'Erro ao estornar o lançamento.');

        return [
            'ok'     => true,
            'msg'    => 'Lançamento estornado com sucesso.',
            'id'     => $response->body['id'] ?? null,
            'numero' => $response->body['numero'] ?? null,
        ];
    }

    public function addJournalEntryLine(int $id, array $payload): array
    {
        if ($id <= 0) {
            throw new OperationException('Lançamento inválido.');
        }
        if (($payload['account_id'] ?? 0) === 0) {
            throw new OperationException('A conta é obrigatória.');
        }

        $response = $this->gateway->request('POST', "/api/contabilidade/journal-entries/$id/lines", $payload);
        $this->ensureSuccess($response, 'Erro ao adicionar a linha ao lançamento.');

        return ['ok' => true, 'msg' => 'Linha adicionada com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function listTaxGroups(array $filters = []): array
    {
        $path = '/api/contabilidade/tax-groups';
        if ($filters) {
            $path .= '?' . http_build_query($filters);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter os grupos de imposto.');

        return $response->body ?? [];
    }

    public function saveTaxGroup(?int $id, array $payload): array
    {
        if (! $id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '')) {
            throw new OperationException('O código e o nome do grupo são obrigatórios.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/contabilidade/tax-groups/$id", $payload)
            : $this->gateway->request('POST', '/api/contabilidade/tax-groups', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o grupo de imposto.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Grupo de imposto actualizado com sucesso.' : 'Grupo de imposto criado com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function listTaxes(array $filters = []): array
    {
        $path = '/api/contabilidade/taxes';
        if ($filters) {
            $path .= '?' . http_build_query($filters);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter as taxas.');

        return $response->body ?? [];
    }

    public function getTax(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Taxa inválida.');
        }

        $response = $this->gateway->request('GET', "/api/contabilidade/taxes/$id");
        $this->ensureSuccess($response, 'Erro ao obter a taxa.');

        return $response->body ?? [];
    }

    public function saveTax(?int $id, array $payload): array
    {
        if (! $id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '')) {
            throw new OperationException('O código e o nome da taxa são obrigatórios.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/contabilidade/taxes/$id", $payload)
            : $this->gateway->request('POST', '/api/contabilidade/taxes', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar a taxa.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Taxa actualizada com sucesso.' : 'Taxa criada com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function addTaxRule(int $id, array $payload): array
    {
        if ($id <= 0) {
            throw new OperationException('Taxa inválida.');
        }
        if (($payload['taxa'] ?? null) === null) {
            throw new OperationException('A taxa da faixa é obrigatória.');
        }

        $response = $this->gateway->request('POST', "/api/contabilidade/taxes/$id/rules", $payload);
        $this->ensureSuccess($response, 'Erro ao adicionar a faixa de taxa.');

        return ['ok' => true, 'msg' => 'Faixa adicionada com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function listTaxTransactions(array $filters = []): array
    {
        $path = '/api/contabilidade/tax-transactions';
        if ($filters) {
            $path .= '?' . http_build_query($filters);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter as transações de imposto.');

        return $response->body ?? [];
    }

    public function registerTaxTransaction(array $payload): array
    {
        if (($payload['tax_id'] ?? null) === null
            || ($payload['referencia_tipo'] ?? '') === ''
            || ($payload['transaction_date'] ?? '') === ''
        ) {
            throw new OperationException('A taxa, o tipo de referência e a data são obrigatórios.');
        }

        $response = $this->gateway->request('POST', '/api/contabilidade/tax-transactions', $payload);
        $this->ensureSuccess($response, 'Erro ao registar a transação de imposto.');

        return [
            'ok'  => true,
            'msg' => 'Transação de imposto registada com sucesso.',
            'id'  => $response->body['id'] ?? null,
        ];
    }

    public function listFixedAssets(array $filters = []): array
    {
        $path = '/api/contabilidade/fixed-assets';
        if ($filters) {
            $path .= '?' . http_build_query($filters);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter os ativos fixos.');

        return $response->body ?? [];
    }

    public function getFixedAsset(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Ativo fixo inválido.');
        }

        $response = $this->gateway->request('GET', "/api/contabilidade/fixed-assets/$id");
        $this->ensureSuccess($response, 'Erro ao obter o ativo fixo.');

        return $response->body ?? [];
    }

    public function getFixedAssetSchedule(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Ativo fixo inválido.');
        }

        $response = $this->gateway->request('GET', "/api/contabilidade/fixed-assets/$id/schedule");
        $this->ensureSuccess($response, 'Erro ao obter o plano de amortização.');

        return $response->body ?? [];
    }

    public function saveFixedAsset(?int $id, array $payload): array
    {
        if (! $id && (($payload['chart_account_id'] ?? 0) === 0
            || ($payload['depreciation_account_id'] ?? 0) === 0
            || ($payload['accumulated_depreciation_account_id'] ?? 0) === 0
            || ($payload['codigo'] ?? '') === ''
            || ($payload['nome'] ?? '') === ''
            || ($payload['data_aquisicao'] ?? '') === ''
            || ($payload['valor_aquisicao'] ?? 0) <= 0
            || ($payload['vida_util_meses'] ?? 0) <= 0
        )) {
            throw new OperationException('A conta, as contas de amortização, o código, o nome, a data de aquisição, o valor de aquisição e a vida útil são obrigatórios.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/contabilidade/fixed-assets/$id", $payload)
            : $this->gateway->request('POST', '/api/contabilidade/fixed-assets', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o ativo fixo.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Ativo fixo actualizado com sucesso.' : 'Ativo fixo criado com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function disposeFixedAsset(int $id, array $payload): array
    {
        if ($id <= 0) {
            throw new OperationException('Ativo fixo inválido.');
        }
        if (($payload['data_alienacao'] ?? '') === '') {
            throw new OperationException('A data de alienação é obrigatória.');
        }

        $response = $this->gateway->request('POST', "/api/contabilidade/fixed-assets/$id/alienar", $payload);
        $this->ensureSuccess($response, 'Erro ao alienar o ativo fixo.');

        return ['ok' => true, 'msg' => 'Ativo fixo alienado com sucesso.'];
    }

    public function listDepreciationEntries(array $filters = []): array
    {
        $path = '/api/contabilidade/depreciation';
        if ($filters) {
            $path .= '?' . http_build_query($filters);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter as amortizações.');

        return $response->body ?? [];
    }

    public function processDepreciation(array $payload): array
    {
        if (($payload['fiscal_period_id'] ?? 0) === 0 || ($payload['accounting_journal_id'] ?? 0) === 0) {
            throw new OperationException('O período fiscal e o diário são obrigatórios.');
        }

        $response = $this->gateway->request('POST', '/api/contabilidade/depreciation/processar', $payload);
        $this->ensureSuccess($response, 'Erro ao processar as amortizações.');

        return [
            'ok'                 => true,
            'msg'                => 'Amortizações processadas com sucesso.',
            'id'                 => $response->body['id'] ?? null,
            'numero'             => $response->body['numero'] ?? null,
            'ativos_processados' => $response->body['ativos_processados'] ?? 0,
        ];
    }

    public function cancelDepreciation(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Amortização inválida.');
        }

        $response = $this->gateway->request('POST', "/api/contabilidade/depreciation/$id/cancelar");
        $this->ensureSuccess($response, 'Erro ao cancelar a amortização.');

        return ['ok' => true, 'msg' => 'Amortização cancelada com sucesso.'];
    }

    public function listBudgets(array $filters = []): array
    {
        $path = '/api/contabilidade/budgets';
        if ($filters) {
            $path .= '?' . http_build_query($filters);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter os orçamentos.');

        return $response->body ?? [];
    }

    public function saveBudget(?int $id, array $payload): array
    {
        if (! $id && (($payload['chart_account_id'] ?? 0) === 0 || ($payload['fiscal_year_id'] ?? 0) === 0)) {
            throw new OperationException('A conta e o ano fiscal são obrigatórios.');
        }
        if (($payload['valor_orcamentado'] ?? null) === null) {
            throw new OperationException('O valor orçamentado é obrigatório.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/contabilidade/budgets/$id", $payload)
            : $this->gateway->request('POST', '/api/contabilidade/budgets', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o orçamento.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Orçamento actualizado com sucesso.' : 'Orçamento criado com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function deleteBudget(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Orçamento inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/contabilidade/budgets/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar o orçamento.');

        return ['ok' => true, 'msg' => 'Orçamento eliminado com sucesso.'];
    }

    public function getBudgetVsRealizado(int $fiscalYearId, ?int $mes = null): array
    {
        if ($fiscalYearId <= 0) {
            throw new OperationException('Ano fiscal inválido.');
        }

        $query = ['fiscal_year_id' => $fiscalYearId];
        if ($mes !== null) {
            $query['mes'] = $mes;
        }

        $response = $this->gateway->request('GET', '/api/contabilidade/budgets/vs-realizado?' . http_build_query($query));
        $this->ensureSuccess($response, 'Erro ao obter o orçado vs realizado.');

        return $response->body ?? [];
    }

    public function listPeriodClosings(array $filters = []): array
    {
        $path = '/api/contabilidade/period-closings';
        if ($filters) {
            $path .= '?' . http_build_query($filters);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter os encerramentos de período.');

        return $response->body ?? [];
    }

    public function getPeriodClosing(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Encerramento inválido.');
        }

        $response = $this->gateway->request('GET', "/api/contabilidade/period-closings/$id");
        $this->ensureSuccess($response, 'Erro ao obter o encerramento de período.');

        return $response->body ?? [];
    }

    public function startPeriodClosing(int $fiscalPeriodId): array
    {
        if ($fiscalPeriodId <= 0) {
            throw new OperationException('Período fiscal inválido.');
        }

        $response = $this->gateway->request('POST', '/api/contabilidade/period-closings', ['fiscal_period_id' => $fiscalPeriodId]);
        $this->ensureSuccess($response, 'Erro ao iniciar o encerramento do período.');

        return [
            'ok'  => true,
            'msg' => 'Processo de encerramento iniciado com sucesso.',
            'id'  => $response->body['id'] ?? null,
        ];
    }

    public function runPeriodClosingChecks(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Encerramento inválido.');
        }

        $response = $this->gateway->request('POST', "/api/contabilidade/period-closings/$id/verificar");
        $this->ensureSuccess($response, 'Erro ao executar as verificações.');

        return [
            'ok'     => true,
            'msg'    => 'Verificações executadas com sucesso.',
            'status' => $response->body['status'] ?? null,
            'checks' => $response->body['checks'] ?? [],
        ];
    }

    public function confirmPeriodClosing(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Encerramento inválido.');
        }

        $response = $this->gateway->request('POST', "/api/contabilidade/period-closings/$id/encerrar");
        $this->ensureSuccess($response, 'Erro ao confirmar o encerramento do período.');

        return ['ok' => true, 'msg' => 'Período encerrado com sucesso.'];
    }

    public function reopenPeriodClosing(int $id, string $justificacao): array
    {
        if ($id <= 0) {
            throw new OperationException('Encerramento inválido.');
        }
        if (trim($justificacao) === '') {
            throw new OperationException('A justificação é obrigatória.');
        }

        $response = $this->gateway->request('POST', "/api/contabilidade/period-closings/$id/reabrir", ['justificacao' => $justificacao]);
        $this->ensureSuccess($response, 'Erro ao reabrir o encerramento do período.');

        return ['ok' => true, 'msg' => 'Encerramento reaberto com sucesso.'];
    }

    public function getTrialBalance(array $params = []): array
    {
        $path = '/api/contabilidade/reports/trial-balance';
        if ($params) {
            $path .= '?' . http_build_query($params);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter o balancete geral.');

        return $response->body ?? [];
    }

    public function getBalanceSheet(array $params = []): array
    {
        $path = '/api/contabilidade/reports/balance-sheet';
        if ($params) {
            $path .= '?' . http_build_query($params);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter o balanço.');

        return $response->body ?? [];
    }

    public function getIncomeStatement(array $params): array
    {
        if (($params['data_inicio'] ?? '') === '' || ($params['data_fim'] ?? '') === '') {
            throw new OperationException('O intervalo de datas é obrigatório.');
        }

        $response = $this->gateway->request('GET', '/api/contabilidade/reports/income-statement?' . http_build_query($params));
        $this->ensureSuccess($response, 'Erro ao obter a demonstração de resultados.');

        return $response->body ?? [];
    }

    public function getGeneralLedger(array $params): array
    {
        if ((int) ($params['chart_account_id'] ?? 0) <= 0) {
            throw new OperationException('A conta é obrigatória.');
        }

        $response = $this->gateway->request('GET', '/api/contabilidade/reports/general-ledger?' . http_build_query($params));
        $this->ensureSuccess($response, 'Erro ao obter o razão geral.');

        return $response->body ?? [];
    }

    public function getDepreciationSummary(array $params): array
    {
        if ((int) ($params['fiscal_period_id'] ?? 0) <= 0 && (int) ($params['fiscal_year_id'] ?? 0) <= 0) {
            throw new OperationException('Indique o período ou o ano fiscal.');
        }

        $response = $this->gateway->request('GET', '/api/contabilidade/reports/depreciation-summary?' . http_build_query($params));
        $this->ensureSuccess($response, 'Erro ao obter o resumo de amortizações.');

        return $response->body ?? [];
    }

    public function getBudgetExecution(int $fiscalYearId): array
    {
        if ($fiscalYearId <= 0) {
            throw new OperationException('Ano fiscal inválido.');
        }

        $response = $this->gateway->request('GET', '/api/contabilidade/reports/budget-execution?' . http_build_query(['fiscal_year_id' => $fiscalYearId]));
        $this->ensureSuccess($response, 'Erro ao obter a execução orçamental.');

        return $response->body ?? [];
    }

    public function generateReport(string $tipo, array $parametros = []): array
    {
        if (trim($tipo) === '') {
            throw new OperationException('O tipo de relatório é obrigatório.');
        }

        $response = $this->gateway->request('POST', '/api/contabilidade/reports/generate', [
            'tipo'       => $tipo,
            'parametros' => $parametros,
        ]);
        $this->ensureSuccess($response, 'Erro ao gerar o relatório.');

        return [
            'ok'       => true,
            'msg'      => 'Relatório gerado com sucesso.',
            'id'       => $response->body['id'] ?? null,
            'conteudo' => $response->body['conteudo'] ?? [],
        ];
    }

    public function listReports(array $filters = []): array
    {
        $path = '/api/contabilidade/reports';
        if ($filters) {
            $path .= '?' . http_build_query($filters);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter o histórico de relatórios.');

        return $response->body ?? [];
    }

    public function getReport(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Relatório inválido.');
        }

        $response = $this->gateway->request('GET', "/api/contabilidade/reports/$id");
        $this->ensureSuccess($response, 'Erro ao obter o relatório.');

        return $response->body ?? [];
    }
}
