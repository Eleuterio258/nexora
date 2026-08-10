<?php

declare(strict_types=1);

namespace E258Tech\Model\Service\PayCore;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

/**
 * Relatórios de transações e fecho de caixa do PayCore.
 */
final class PosTransactionReportService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    /**
     * Relatório de transações por período.
     *
     * @return array<string, mixed>
     */
    public function byPeriod(string $from, string $to): array
    {
        if ($from === '' || $to === '') {
            throw new OperationException('O periodo e obrigatorio.');
        }

        $response = $this->gateway->request(
            'GET',
            '/api/v1/transactions/report?' . http_build_query(['startDate' => $from, 'endDate' => $to])
        );
        $this->ensureSuccess($response, 'Erro ao carregar o relatorio de transacoes.');

        return $response->body ?? [];
    }

    /**
     * Lista transações com filtros opcionais.
     *
     * @param array<string, mixed> $filters
     * @return array<int, array<string, mixed>>
     */
    public function transactions(array $filters = []): array
    {
        $query = array_filter(
            $filters,
            static fn(mixed $value): bool => $value !== null && $value !== ''
        );

        $path = '/api/v1/transactions';
        if ($query) {
            $path .= '?' . http_build_query($query);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao listar as transacoes.');

        return $response->body ?? [];
    }
}
