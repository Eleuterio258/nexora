<?php

declare(strict_types=1);

namespace E258Tech\Model\Service\PayCore;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

/**
 * Gestão de produtos e stock no PayCore (/api/v1/products).
 */
final class StockProductService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    /**
     * Lista todos os produtos.
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

        $path = '/api/v1/products';
        if ($query) {
            $path .= '?' . http_build_query($query);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao listar os produtos.');

        return $response->body ?? [];
    }

    /**
     * Busca um produto pelo ID.
     *
     * @return array<string, mixed>
     */
    public function get(string $id): array
    {
        if ($id === '') {
            throw new OperationException('Produto invalido.');
        }

        $response = $this->gateway->request('GET', "/api/v1/products/$id");
        $this->ensureSuccess($response, 'Erro ao carregar o produto.');

        return $response->body ?? [];
    }

    /**
     * Busca um produto por código de barras.
     *
     * @return array<string, mixed>
     */
    public function findByBarcode(string $barcode): array
    {
        if ($barcode === '') {
            throw new OperationException('Codigo de barras invalido.');
        }

        $response = $this->gateway->request('GET', '/api/v1/products/barcode/' . urlencode($barcode));
        $this->ensureSuccess($response, 'Erro ao buscar o produto por codigo de barras.');

        return $response->body ?? [];
    }

    /**
     * Cria um novo produto.
     *
     * @param array<string, mixed> $data
     * @return array<string, mixed>
     */
    public function create(array $data): array
    {
        $payload = $this->normalizePayload($data);

        $response = $this->gateway->request('POST', '/api/v1/products', $payload);
        $this->ensureSuccess($response, 'Erro ao criar o produto.');

        return $response->body ?? [];
    }

    /**
     * Actualiza um produto.
     *
     * @param array<string, mixed> $data
     * @return array<string, mixed>
     */
    public function update(string $id, array $data): array
    {
        if ($id === '') {
            throw new OperationException('Produto invalido.');
        }

        $payload = $this->normalizePayload($data, true);

        $response = $this->gateway->request('PUT', "/api/v1/products/$id", $payload);
        $this->ensureSuccess($response, 'Erro ao actualizar o produto.');

        return $response->body ?? [];
    }

    /**
     * Remove um produto.
     */
    public function delete(string $id): void
    {
        if ($id === '') {
            throw new OperationException('Produto invalido.');
        }

        $response = $this->gateway->request('DELETE', "/api/v1/products/$id");
        $this->ensureSuccess($response, 'Erro ao remover o produto.');
    }

    /**
     * Lista produtos com stock baixo.
     *
     * @return array<int, array<string, mixed>>
     */
    public function lowStock(): array
    {
        $response = $this->gateway->request('GET', '/api/v1/products/low-stock');
        $this->ensureSuccess($response, 'Erro ao carregar alertas de stock.');

        return $response->body ?? [];
    }

    /**
     * @param array<string, mixed> $data
     * @return array<string, mixed>
     */
    private function normalizePayload(array $data, bool $partial = false): array
    {
        $payload = [];

        $fields = [
            'category_id' => 'category_id',
            'name' => 'name',
            'description' => 'description',
            'price' => 'price',
            'cost_price' => 'cost_price',
            'barcode' => 'barcode',
            'sku' => 'sku',
            'image_url' => 'image_url',
            'unit' => 'unit',
            'stock' => 'stock',
            'min_stock' => 'min_stock',
            'active' => 'active',
        ];

        foreach ($fields as $snake => $camel) {
            if (array_key_exists($camel, $data)) {
                $payload[$camel] = $data[$camel];
            } elseif (array_key_exists($snake, $data)) {
                $payload[$camel] = $data[$snake];
            }
        }

        if (isset($payload['price'])) {
            $payload['price'] = (float) $payload['price'];
        }
        if (isset($payload['cost_price'])) {
            $payload['cost_price'] = (float) $payload['cost_price'];
        }
        if (isset($payload['stock'])) {
            $payload['stock'] = (int) $payload['stock'];
        }
        if (isset($payload['min_stock'])) {
            $payload['min_stock'] = (int) $payload['min_stock'];
        }

        if (!$partial && empty($payload['name'])) {
            throw new OperationException('O nome do produto e obrigatorio.');
        }

        return $payload;
    }
}
