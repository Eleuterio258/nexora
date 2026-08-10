<?php

declare(strict_types=1);

namespace E258Tech\Model\Service\PayCore;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

/**
 * Dados operacionais do dashboard consumindo o backend PayCore (/api/v1).
 */
final class DashboardService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    /**
     * Relatório de transações do período.
     *
     * @return array<string, mixed>
     */
    public function transactionReport(string $from, string $to): array
    {
        $response = $this->gateway->request(
            'GET',
            '/api/v1/transactions/report?' . http_build_query(['startDate' => $from, 'endDate' => $to])
        );
        $this->ensureSuccess($response, 'Erro ao carregar o relatorio de vendas.');

        return $response->body ?? [];
    }

    /**
     * Lista de caixas abertas/fechadas recentes.
     *
     * @return array<int, array<string, mixed>>
     */
    public function cashDrawers(int $limit = 5): array
    {
        $response = $this->gateway->request('GET', '/api/v1/cash-drawers');
        $this->ensureSuccess($response, 'Erro ao carregar as sessoes de caixa.');

        $items = $response->body ?? [];
        return array_slice($items, 0, $limit);
    }

    /**
     * Produtos com stock baixo.
     *
     * @return array<int, array<string, mixed>>
     */
    public function lowStock(int $limit = 5): array
    {
        $response = $this->gateway->request('GET', '/api/v1/products/low-stock');
        $this->ensureSuccess($response, 'Erro ao carregar alertas de stock.');

        $items = $response->body ?? [];
        return array_slice($items, 0, $limit);
    }

    /**
     * Últimas transações aprovadas.
     *
     * @return array<int, array<string, mixed>>
     */
    public function recentTransactions(int $limit = 5): array
    {
        $response = $this->gateway->request('GET', '/api/v1/transactions');
        $this->ensureSuccess($response, 'Erro ao carregar as transacoes.');

        $items = $response->body ?? [];
        $approved = array_filter($items, static fn(array $t): bool => ($t['status'] ?? '') === 'APPROVED');
        return array_slice($approved, 0, $limit);
    }

    /**
     * Resume as vendas do dia e do mês, juntamente com métodos de pagamento.
     *
     * @return array<string, mixed>
     */
    public function summary(): array
    {
        $today = date('Y-m-d');
        $firstDayOfMonth = date('Y-m-01');

        $todayReport = $this->transactionReport($today, $today);
        $monthReport = $this->transactionReport($firstDayOfMonth, $today);

        return [
            'vendas_hoje' => $todayReport['summary']['netTotal'] ?? 0,
            'vendas_mes' => $monthReport['summary']['netTotal'] ?? 0,
            'transacoes_hoje' => $todayReport['summary']['totalTransactions'] ?? 0,
            'transacoes_mes' => $monthReport['summary']['totalTransactions'] ?? 0,
            'por_metodo' => $todayReport['byPaymentMethod'] ?? [],
        ];
    }
}
