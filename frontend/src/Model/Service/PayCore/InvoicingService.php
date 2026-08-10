<?php

declare(strict_types=1);

namespace E258Tech\Model\Service\PayCore;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

/**
 * Gestão de transações como documentos fiscais no PayCore.
 *
 * O backend PayCore ainda não possui documentos fiscais (facturas, notas de
 * crédito, etc.). Esta camada expõe as transações (/api/v1/transactions) como
 * documentos de venda, permitindo listar, visualizar, estornar e cancelar.
 */
final class InvoicingService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    /**
     * Lista transações com filtros.
     *
     * @param array<string, mixed> $filters
     * @return array<int, array<string, mixed>>
     */
    public function list(array $filters = []): array
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
        $this->ensureSuccess($response, 'Erro ao listar as transaccoes.');

        return $response->body ?? [];
    }

    /**
     * Busca uma transação pelo ID.
     *
     * @return array<string, mixed>
     */
    public function get(string $id): array
    {
        if ($id === '') {
            throw new OperationException('Transaccao invalida.');
        }

        $response = $this->gateway->request('GET', "/api/v1/transactions/$id");
        $this->ensureSuccess($response, 'Erro ao carregar a transaccao.');

        return $response->body ?? [];
    }

    /**
     * Busca uma transação por referência.
     *
     * @return array<string, mixed>
     */
    public function getByReference(string $reference): array
    {
        if ($reference === '') {
            throw new OperationException('Referencia invalida.');
        }

        $response = $this->gateway->request('GET', '/api/v1/transactions/reference/' . urlencode($reference));
        $this->ensureSuccess($response, 'Erro ao carregar a transaccao.');

        return $response->body ?? [];
    }

    /**
     * Estorna uma transação.
     *
     * @return array<string, mixed>
     */
    public function reverse(string $id, string $reason): array
    {
        if ($id === '') {
            throw new OperationException('Transaccao invalida.');
        }
        if (trim($reason) === '') {
            throw new OperationException('O motivo do estorno e obrigatorio.');
        }

        $response = $this->gateway->request('POST', "/api/v1/transactions/$id/reverse", ['reason' => $reason]);
        $this->ensureSuccess($response, 'Erro ao estornar a transaccao.');

        return $response->body ?? [];
    }

    /**
     * Cancela uma transação.
     *
     * @return array<string, mixed>
     */
    public function cancel(string $id, string $reason): array
    {
        if ($id === '') {
            throw new OperationException('Transaccao invalida.');
        }
        if (trim($reason) === '') {
            throw new OperationException('O motivo do cancelamento e obrigatorio.');
        }

        $response = $this->gateway->request('POST', "/api/v1/transactions/$id/cancel", ['reason' => $reason]);
        $this->ensureSuccess($response, 'Erro ao cancelar a transaccao.');

        return $response->body ?? [];
    }
}
