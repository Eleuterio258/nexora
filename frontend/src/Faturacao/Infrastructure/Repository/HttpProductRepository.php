<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Infrastructure\Repository;

use E258Tech\Faturacao\Domain\Entity\Product;
use E258Tech\Faturacao\Domain\Repository\ProductRepositoryInterface;
use E258Tech\Faturacao\Domain\ValueObject\Money;
use E258Tech\Faturacao\Domain\ValueObject\TaxRate;
use E258Tech\Faturacao\Infrastructure\Http\ApiClient;
use RuntimeException;

/**
 * Lê produtos reais da API do backend (GET /api/produtos). Só leitura por
 * agora. A listagem do backend não devolve unidade (só product_unit_id, sem
 * o nome) nem stock (fica noutro módulo) — ficam com um valor por omissão
 * em vez de uma segunda chamada por produto.
 */
final class HttpProductRepository implements ProductRepositoryInterface
{
    public function __construct(private ApiClient $client)
    {
    }

    public function findAll(): array
    {
        $response = $this->client->get('/api/produtos', ['limit' => 200]);
        $rows = $response['data'] ?? $response;
        if (!is_array($rows)) {
            return [];
        }

        return array_map(fn(array $row) => $this->mapRow($row), $rows);
    }

    public function findById(int $id): ?Product
    {
        foreach ($this->findAll() as $product) {
            if ($product->id() === $id) {
                return $product;
            }
        }
        return null;
    }

    public function save(Product $product): void
    {
        throw new RuntimeException(
            'HttpProductRepository é só de leitura — a escrita de produtos ainda não está ligada à API.'
        );
    }

    public function nextId(): int
    {
        throw new RuntimeException(
            'HttpProductRepository é só de leitura — não gera identificadores locais.'
        );
    }

    private function mapRow(array $row): Product
    {
        $preco = $row['preco_venda'] ?? 0;

        return new Product(
            (int) $row['id'],
            (string) ($row['codigo'] ?? ''),
            (string) ($row['nome'] ?? ''),
            'Un.',
            Money::fromFloat((float) $preco),
            TaxRate::fromFloat((float) ($row['iva_percentual'] ?? 0)),
            null,
            (bool) ($row['ativo'] ?? true)
        );
    }
}
