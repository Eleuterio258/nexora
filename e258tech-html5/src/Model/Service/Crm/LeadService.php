<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Crm;

use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Http\HttpResponse;

final class LeadService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    public function save(?int $id, array $payload): array
    {
        if (($payload['nome'] ?? '') === '') {
            throw new OperationException('O nome e obrigatorio.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/crm/leads/$id", $payload)
            : $this->gateway->request('POST', '/api/crm/leads', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o lead.');

        return [
            'ok' => true,
            'msg' => $id ? 'Lead actualizado com sucesso.' : 'Lead criado com sucesso.',
            'id' => $response->body['id'] ?? $id,
        ];
    }

    public function move(int $id, string $state): array
    {
        if ($id <= 0 || $state === '') {
            throw new OperationException('Dados invalidos.');
        }

        $current = $this->gateway->request('GET', "/api/crm/leads/$id");
        $this->ensureSuccess($current, 'Lead nao encontrado.');

        if (($current->body['estado'] ?? null) === 'convertido' && $state !== 'convertido') {
            throw new OperationException('Este lead ja foi convertido e o estado esta bloqueado.');
        }

        $response = $this->gateway->request(
            'PUT',
            "/api/crm/leads/$id/estado",
            ['estado' => $state]
        );
        $this->ensureSuccess($response, 'Erro ao mover o lead.');
        return ['ok' => true];
    }

    public function delete(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('ID invalido.');
        }

        $response = $this->gateway->request('DELETE', "/api/crm/leads/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar o lead.');
        return ['ok' => true];
    }

    public function convert(int $id, array $payload): array
    {
        if ($id <= 0) {
            throw new OperationException('ID invalido.');
        }

        $response = $this->gateway->request('POST', "/api/crm/leads/$id/converter", $payload);
        $this->ensureSuccess($response, 'Erro ao converter lead.');

        return [
            'ok' => true,
            'cliente_id' => $response->body['cliente_id'] ?? null,
            'oportunidade_id' => $response->body['oportunidade_id'] ?? null,
        ];
    }

    private function ensureSuccess(HttpResponse $response, string $fallback): void
    {
        if (!$response->successful()) {
            throw new OperationException(
                (string) ($response->body['erro'] ?? $fallback),
                $response->status
            );
        }
    }
}
