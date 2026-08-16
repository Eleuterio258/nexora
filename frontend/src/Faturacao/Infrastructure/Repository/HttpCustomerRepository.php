<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Infrastructure\Repository;

use E258Tech\Faturacao\Domain\Entity\Customer;
use E258Tech\Faturacao\Domain\Repository\CustomerRepositoryInterface;
use E258Tech\Faturacao\Domain\ValueObject\Money;
use E258Tech\Faturacao\Infrastructure\Http\ApiClient;
use RuntimeException;

/**
 * Lê clientes reais da API do backend (GET /api/clientes). Só leitura por
 * agora — a escrita de clientes continua a ser feita directamente no
 * backend/Nexora, não a partir do phc.
 *
 * O saldo (balance) não vem na listagem — vive em clientes.customer_balances
 * no backend, consultado à parte. Por agora fica sempre 0; o phc deixou de
 * ser a fonte de verdade para saldo de cliente assim que passou a ler daqui.
 */
final class HttpCustomerRepository implements CustomerRepositoryInterface
{
    public function __construct(private ApiClient $client)
    {
    }

    public function findAll(): array
    {
        $response = $this->client->get('/api/clientes', ['limit' => 200]);
        $rows = $response['data'] ?? $response;
        if (!is_array($rows)) {
            return [];
        }

        return array_map(fn(array $row) => $this->mapRow($row), $rows);
    }

    public function findById(int $id): ?Customer
    {
        foreach ($this->findAll() as $customer) {
            if ($customer->id() === $id) {
                return $customer;
            }
        }
        return null;
    }

    public function save(Customer $customer): void
    {
        throw new RuntimeException(
            'HttpCustomerRepository é só de leitura — a escrita de clientes ainda não está ligada à API.'
        );
    }

    public function nextId(): int
    {
        throw new RuntimeException(
            'HttpCustomerRepository é só de leitura — não gera identificadores locais.'
        );
    }

    private function mapRow(array $row): Customer
    {
        return new Customer(
            (int) $row['id'],
            (string) ($row['codigo'] ?? ''),
            (string) ($row['nome'] ?? ''),
            (string) ($row['nuit'] ?? ''),
            (string) ($row['telefone'] ?? ''),
            (string) ($row['email'] ?? ''),
            '',
            new Money(0)
        );
    }
}
