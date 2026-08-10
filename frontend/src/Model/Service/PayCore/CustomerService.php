<?php

declare(strict_types=1);

namespace E258Tech\Model\Service\PayCore;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Service\NexoraService;

/**
 * Gestão de clientes no PayCore.
 *
 * O backend PayCore ainda nao possui um modulo de clientes. Este service
 * constroi uma lista de clientes a partir dos campos disponiveis nas
 * transacoes (customer_email, customer_name, etc.) quando existirem.
 */
final class CustomerService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    /**
     * Lista clientes derivados das transacoes.
     *
     * @return array<int, array<string, mixed>>
     */
    public function list(): array
    {
        $response = $this->gateway->request('GET', '/api/v1/transactions');
        $this->ensureSuccess($response, 'Erro ao listar transaccoes para clientes.');

        $transactions = $response->body ?? [];
        $customers = [];

        foreach ($transactions as $t) {
            $email = $t['customer_email'] ?? $t['customerEmail'] ?? null;
            $name = $t['customer_name'] ?? $t['customerName'] ?? null;
            $phone = $t['customer_phone'] ?? $t['customerPhone'] ?? null;
            $nif = $t['customer_nif'] ?? $t['customerNif'] ?? null;

            if ($email === null && $name === null && $phone === null) {
                continue;
            }

            $key = strtolower(trim((string) ($email ?? $phone ?? $name)));
            if ($key === '') {
                continue;
            }

            if (!isset($customers[$key])) {
                $customers[$key] = [
                    'email' => $email,
                    'name' => $name,
                    'phone' => $phone,
                    'nif' => $nif,
                    'transactions' => [],
                    'total_spent' => 0,
                ];
            }

            $customers[$key]['transactions'][] = $t;
            $customers[$key]['total_spent'] += (float) ($t['total'] ?? 0);
        }

        return array_values($customers);
    }

    /**
     * Historico de transacoes de um cliente (por email).
     *
     * @return array<int, array<string, mixed>>
     */
    public function transactions(string $email): array
    {
        $response = $this->gateway->request('GET', '/api/v1/transactions');
        $this->ensureSuccess($response, 'Erro ao listar transaccoes do cliente.');

        $transactions = $response->body ?? [];
        return array_filter($transactions, static fn(array $t): bool =>
            strtolower((string) ($t['customer_email'] ?? $t['customerEmail'] ?? '')) === strtolower($email)
        );
    }
}
