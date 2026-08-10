<?php

declare(strict_types=1);

namespace E258Tech\Model\Service\PayCore;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

/**
 * Gestão de terminais POS no PayCore (/api/v1/terminals/admin).
 */
final class TerminalAdminService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    /**
     * Lista terminais do tenant.
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

        $path = '/api/v1/terminals/admin';
        if ($query) {
            $path .= '?' . http_build_query($query);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao listar terminais.');

        $body = $response->body ?? [];
        return $body['data'] ?? $body ?? [];
    }

    /**
     * Estatísticas de terminais.
     *
     * @return array<string, mixed>
     */
    public function stats(): array
    {
        $response = $this->gateway->request('GET', '/api/v1/terminals/admin/stats');
        $this->ensureSuccess($response, 'Erro ao carregar estatisticas dos terminais.');

        return $response->body ?? [];
    }

    /**
     * Busca um terminal pelo ID.
     *
     * @return array<string, mixed>
     */
    public function get(string $id): array
    {
        if ($id === '') {
            throw new OperationException('Terminal invalido.');
        }

        $response = $this->gateway->request('GET', "/api/v1/terminals/admin/$id");
        $this->ensureSuccess($response, 'Erro ao carregar o terminal.');

        $body = $response->body ?? [];
        return $body['data'] ?? $body ?? [];
    }

    /**
     * Cria um terminal.
     *
     * @param array<string, mixed> $data
     * @return array<string, mixed>
     */
    public function create(array $data): array
    {
        $payload = $this->normalizePayload($data);

        $response = $this->gateway->request('POST', '/api/v1/terminals/admin', $payload);
        $this->ensureSuccess($response, 'Erro ao criar o terminal.');

        $body = $response->body ?? [];
        return $body['data'] ?? $body ?? [];
    }

    /**
     * Actualiza um terminal.
     *
     * @param array<string, mixed> $data
     * @return array<string, mixed>
     */
    public function update(string $id, array $data): array
    {
        if ($id === '') {
            throw new OperationException('Terminal invalido.');
        }

        $payload = $this->normalizePayload($data, true);

        $response = $this->gateway->request('PUT', "/api/v1/terminals/admin/$id", $payload);
        $this->ensureSuccess($response, 'Erro ao actualizar o terminal.');

        $body = $response->body ?? [];
        return $body['data'] ?? $body ?? [];
    }

    /**
     * Actualiza o estado de um terminal.
     */
    public function updateStatus(string $id, string $status): array
    {
        if ($id === '') {
            throw new OperationException('Terminal invalido.');
        }
        if (!in_array($status, ['ACTIVE', 'INACTIVE', 'BLOCKED', 'MAINTENANCE', 'OFFLINE'], true)) {
            throw new OperationException('Estado invalido.');
        }

        $response = $this->gateway->request('PUT', "/api/v1/terminals/admin/$id/status", ['status' => $status]);
        $this->ensureSuccess($response, 'Erro ao alterar o estado do terminal.');

        $body = $response->body ?? [];
        return $body['data'] ?? $body ?? [];
    }

    /**
     * Remove um terminal.
     */
    public function delete(string $id): void
    {
        if ($id === '') {
            throw new OperationException('Terminal invalido.');
        }

        $response = $this->gateway->request('DELETE', "/api/v1/terminals/admin/$id");
        $this->ensureSuccess($response, 'Erro ao remover o terminal.');
    }

    /**
     * @param array<string, mixed> $data
     * @return array<string, mixed>
     */
    private function normalizePayload(array $data, bool $partial = false): array
    {
        $payload = [];

        $fields = [
            'serial_number' => 'serialNumber',
            'name' => 'name',
            'description' => 'description',
            'model' => 'model',
            'manufacturer' => 'manufacturer',
            'settings' => 'settings',
        ];

        foreach ($fields as $snake => $camel) {
            if (array_key_exists($camel, $data)) {
                $payload[$camel] = $data[$camel];
            } elseif (array_key_exists($snake, $data)) {
                $payload[$camel] = $data[$snake];
            }
        }

        if (!$partial && empty($payload['serialNumber'])) {
            throw new OperationException('O numero de serie e obrigatorio.');
        }
        if (!$partial && empty($payload['name'])) {
            throw new OperationException('O nome do terminal e obrigatorio.');
        }

        return $payload;
    }
}
