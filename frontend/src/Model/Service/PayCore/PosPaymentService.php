<?php

declare(strict_types=1);

namespace E258Tech\Model\Service\PayCore;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

/**
 * Pagamentos móveis e transações POS no PayCore.
 *
 * O backend PayCore não possui integração directa com operadoras (M-Pesa/eMola).
 * O método de pagamento móvel é representado por `WALLET`. Este service cria a
 * transação e permite verificar o seu estado por referência.
 */
final class PosPaymentService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    /**
     * Cria uma transação de venda.
     *
     * @param array<int, array<string, mixed>> $items
     * @param array<string, mixed> $options
     * @return array<string, mixed>
     */
    public function createSale(array $items, array $options = []): array
    {
        if (empty($items)) {
            throw new OperationException('O carrinho esta vazio.');
        }

        $payload = [
            'paymentMethod' => $options['paymentMethod'] ?? 'CASH',
            'paymentType' => $options['paymentType'] ?? null,
            'installments' => $options['installments'] ?? 1,
            'items' => array_values(array_map(static fn(array $item): array => [
                'name' => $item['name'] ?? 'Produto',
                'quantity' => (int) ($item['quantity'] ?? 1),
                'price' => (float) ($item['price'] ?? 0),
                'discount' => (float) ($item['discount'] ?? 0),
            ], $items)),
            'discount' => (float) ($options['discount'] ?? 0),
            'surcharge' => (float) ($options['surcharge'] ?? 0),
            'type' => $options['type'] ?? 'SALE',
        ];

        if (!empty($options['operatorId'])) {
            $payload['operatorId'] = $options['operatorId'];
        }
        if (!empty($options['terminalId'])) {
            $payload['terminalId'] = $options['terminalId'];
        }

        $response = $this->gateway->request('POST', '/api/v1/transactions', $payload);
        $this->ensureSuccess($response, 'Erro ao registar a transacao.');

        return $response->body ?? [];
    }

    /**
     * Cria uma transação com pagamento móvel (WALLET).
     *
     * @param array<int, array<string, mixed>> $items
     * @param array<string, mixed> $options
     * @return array<string, mixed>
     */
    public function createMobilePayment(array $items, array $options = []): array
    {
        $options['paymentMethod'] = 'WALLET';
        $options['paymentType'] = $this->normalizeGateway($options['gateway'] ?? 'WALLET');

        $transaction = $this->createSale($items, $options);

        // Simula metadados de pagamento móvel enquanto não há gateway real.
        $transaction['_mobile_payment'] = [
            'gateway' => $options['gateway'] ?? 'M-Pesa',
            'phone' => $options['phone'] ?? null,
            'reference' => $transaction['reference'] ?? null,
            'status' => $transaction['status'] ?? 'PENDING',
            'instructions' => 'Confirme a transacao no seu telemovel. O estado sera actualizado automaticamente.',
        ];

        return $transaction;
    }

    /**
     * Verifica o estado de uma transação por referência.
     */
    public function statusByReference(string $reference): array
    {
        if ($reference === '') {
            throw new OperationException('Referencia invalida.');
        }

        $response = $this->gateway->request('GET', '/api/v1/transactions/reference/' . urlencode($reference));
        $this->ensureSuccess($response, 'Erro ao verificar o estado do pagamento.');

        return $response->body ?? [];
    }

    /**
     * Normaliza o nome do gateway para o backend.
     */
    private function normalizeGateway(string $gateway): string
    {
        return match (strtolower($gateway)) {
            'm-pesa', 'mpesa' => 'M-PESA',
            'e-mola', 'emola' => 'E-MOLA',
            'm-mola', 'mmola' => 'M-MOLA',
            default => 'WALLET',
        };
    }
}
