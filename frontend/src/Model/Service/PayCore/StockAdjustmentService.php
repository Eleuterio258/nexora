<?php

declare(strict_types=1);

namespace E258Tech\Model\Service\PayCore;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

/**
 * Ajustes de stock e histórico de movimentos no PayCore.
 */
final class StockAdjustmentService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    /**
     * Ajusta o stock de um produto.
     *
     * @param array<string, mixed> $data
     * @return array<string, mixed>
     */
    public function adjust(string $productId, array $data): array
    {
        if ($productId === '') {
            throw new OperationException('Produto invalido.');
        }

        $quantity = (int) ($data['quantity'] ?? 0);
        if ($quantity === 0) {
            throw new OperationException('A quantidade deve ser diferente de zero.');
        }

        $type = $data['type'] ?? 'MANUAL_ADJUSTMENT';
        $validTypes = ['SALE', 'REVERSAL', 'MANUAL_ADJUSTMENT', 'PURCHASE', 'LOSS', 'TRANSFER'];
        if (!in_array($type, $validTypes, true)) {
            throw new OperationException('Tipo de ajuste invalido.');
        }

        $reason = trim((string) ($data['reason'] ?? ''));
        if ($reason === '') {
            throw new OperationException('O motivo do ajuste e obrigatorio.');
        }

        $payload = [
            'quantity' => $quantity,
            'type' => $type,
            'reason' => $reason,
            'referenceNumber' => $data['reference_number'] ?? $data['referenceNumber'] ?? null,
        ];

        $response = $this->gateway->request('POST', "/api/v1/products/$productId/stock/adjust", $payload);
        $this->ensureSuccess($response, 'Erro ao ajustar o stock.');

        return $response->body ?? [];
    }

    /**
     * Histórico de movimentos de stock de um produto.
     *
     * @return array<int, array<string, mixed>>
     */
    public function logs(string $productId): array
    {
        if ($productId === '') {
            throw new OperationException('Produto invalido.');
        }

        $response = $this->gateway->request('GET', "/api/v1/products/$productId/stock/logs");
        $this->ensureSuccess($response, 'Erro ao carregar o historico de stock.');

        return $response->body ?? [];
    }
}
