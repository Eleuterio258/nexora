<?php

declare(strict_types=1);

namespace E258Tech\Model\Service\PayCore;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

/**
 * Gestão de descontos do PayCore (/api/v1/discounts).
 */
final class PosDiscountService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    /**
     * Lista todos os descontos.
     *
     * @return array<int, array<string, mixed>>
     */
    public function list(bool $activeOnly = false): array
    {
        $path = '/api/v1/discounts';
        if ($activeOnly) {
            $path .= '?active=true';
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao listar os descontos.');

        return $response->body ?? [];
    }

    /**
     * Busca um desconto pelo ID.
     *
     * @return array<string, mixed>
     */
    public function get(string $id): array
    {
        if ($id === '') {
            throw new OperationException('Desconto invalido.');
        }

        $response = $this->gateway->request('GET', "/api/v1/discounts/$id");
        $this->ensureSuccess($response, 'Erro ao carregar o desconto.');

        return $response->body ?? [];
    }

    /**
     * Cria um novo desconto.
     *
     * @param array<string, mixed> $data
     * @return array<string, mixed>
     */
    public function create(array $data): array
    {
        $payload = $this->normalizePayload($data);

        $response = $this->gateway->request('POST', '/api/v1/discounts', $payload);
        $this->ensureSuccess($response, 'Erro ao criar o desconto.');

        return $response->body ?? [];
    }

    /**
     * Actualiza um desconto existente.
     *
     * @param array<string, mixed> $data
     * @return array<string, mixed>
     */
    public function update(string $id, array $data): array
    {
        if ($id === '') {
            throw new OperationException('Desconto invalido.');
        }

        $payload = $this->normalizePayload($data, true);

        $response = $this->gateway->request('PUT', "/api/v1/discounts/$id", $payload);
        $this->ensureSuccess($response, 'Erro ao actualizar o desconto.');

        return $response->body ?? [];
    }

    /**
     * Remove um desconto (soft delete).
     */
    public function delete(string $id): void
    {
        if ($id === '') {
            throw new OperationException('Desconto invalido.');
        }

        $response = $this->gateway->request('DELETE', "/api/v1/discounts/$id");
        $this->ensureSuccess($response, 'Erro ao remover o desconto.');
    }

    /**
     * Calcula o valor final ao aplicar um desconto num montante.
     *
     * @return array<string, mixed>
     */
    public function apply(string $id, float $amount): array
    {
        if ($id === '') {
            throw new OperationException('Desconto invalido.');
        }
        if ($amount <= 0) {
            throw new OperationException('O montante deve ser superior a zero.');
        }

        $response = $this->gateway->request('POST', "/api/v1/discounts/$id/apply", ['amount' => $amount]);
        $this->ensureSuccess($response, 'Erro ao calcular o desconto.');

        return $response->body ?? [];
    }

    /**
     * Normaliza o payload para criar/editar descontos.
     *
     * @param array<string, mixed> $data
     * @return array<string, mixed>
     */
    private function normalizePayload(array $data, bool $partial = false): array
    {
        $payload = [];

        $fields = [
            'name' => 'name',
            'description' => 'description',
            'type' => 'type',
            'value' => 'value',
            'minAmount' => 'min_amount',
            'maxAmount' => 'max_amount',
            'validFrom' => 'valid_from',
            'validUntil' => 'valid_until',
            'active' => 'active',
        ];

        foreach ($fields as $snake => $camel) {
            if (array_key_exists($camel, $data)) {
                $payload[$camel] = $data[$camel];
            } elseif (array_key_exists($snake, $data)) {
                $payload[$camel] = $data[$snake];
            }
        }

        if (!$partial && empty($payload['name'])) {
            throw new OperationException('O nome do desconto e obrigatorio.');
        }

        if (!$partial && !in_array($payload['type'] ?? '', ['PERCENTAGE', 'FIXED'], true)) {
            throw new OperationException('O tipo de desconto deve ser PERCENTAGE ou FIXED.');
        }

        if (isset($payload['value'])) {
            $payload['value'] = (float) $payload['value'];
        }
        if (isset($payload['min_amount'])) {
            $payload['min_amount'] = $payload['min_amount'] !== null ? (float) $payload['min_amount'] : null;
        }
        if (isset($payload['max_amount'])) {
            $payload['max_amount'] = $payload['max_amount'] !== null ? (float) $payload['max_amount'] : null;
        }

        return $payload;
    }
}
