<?php

declare(strict_types=1);

namespace E258Tech\Model\Service\PayCore;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

/**
 * Gestão de categorias de produtos no PayCore (/api/v1/categories).
 */
final class StockCategoryService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    /**
     * Lista todas as categorias.
     *
     * @return array<int, array<string, mixed>>
     */
    public function list(bool $activeOnly = false): array
    {
        $path = '/api/v1/categories';
        if ($activeOnly) {
            $path .= '?active=true';
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao listar as categorias.');

        return $response->body ?? [];
    }

    /**
     * Busca uma categoria pelo ID.
     *
     * @return array<string, mixed>
     */
    public function get(string $id): array
    {
        if ($id === '') {
            throw new OperationException('Categoria invalida.');
        }

        $response = $this->gateway->request('GET', "/api/v1/categories/$id");
        $this->ensureSuccess($response, 'Erro ao carregar a categoria.');

        return $response->body ?? [];
    }

    /**
     * Cria uma nova categoria.
     *
     * @param array<string, mixed> $data
     * @return array<string, mixed>
     */
    public function create(array $data): array
    {
        $payload = $this->normalizePayload($data);

        $response = $this->gateway->request('POST', '/api/v1/categories', $payload);
        $this->ensureSuccess($response, 'Erro ao criar a categoria.');

        return $response->body ?? [];
    }

    /**
     * Actualiza uma categoria.
     *
     * @param array<string, mixed> $data
     * @return array<string, mixed>
     */
    public function update(string $id, array $data): array
    {
        if ($id === '') {
            throw new OperationException('Categoria invalida.');
        }

        $payload = $this->normalizePayload($data, true);

        $response = $this->gateway->request('PUT', "/api/v1/categories/$id", $payload);
        $this->ensureSuccess($response, 'Erro ao actualizar a categoria.');

        return $response->body ?? [];
    }

    /**
     * Remove uma categoria.
     */
    public function delete(string $id): void
    {
        if ($id === '') {
            throw new OperationException('Categoria invalida.');
        }

        $response = $this->gateway->request('DELETE', "/api/v1/categories/$id");
        $this->ensureSuccess($response, 'Erro ao remover a categoria.');
    }

    /**
     * @param array<string, mixed> $data
     * @return array<string, mixed>
     */
    private function normalizePayload(array $data, bool $partial = false): array
    {
        $payload = [];

        $fields = [
            'name' => 'name',
            'description' => 'description',
            'icon' => 'icon',
            'color' => 'color',
            'order' => 'order_index',
            'active' => 'active',
        ];

        foreach ($fields as $snake => $camel) {
            if (array_key_exists($camel, $data)) {
                $payload[$camel] = $data[$camel];
            } elseif (array_key_exists($snake, $data)) {
                $payload[$camel] = $data[$snake];
            }
        }

        if (isset($payload['order_index'])) {
            $payload['order_index'] = (int) $payload['order_index'];
        }

        if (!$partial && empty($payload['name'])) {
            throw new OperationException('O nome da categoria e obrigatorio.');
        }

        return $payload;
    }
}
