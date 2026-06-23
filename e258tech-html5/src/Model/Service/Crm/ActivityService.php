<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Crm;

use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Http\HttpResponse;

final class ActivityService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    public function save(?int $id, array $payload): array
    {
        if (($payload['titulo'] ?? '') === '') {
            throw new OperationException('O titulo e obrigatorio.');
        }

        if (empty($payload['lead_id']) && empty($payload['oportunidade_id'])) {
            throw new OperationException('Indique lead_id ou oportunidade_id.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/crm/atividades/$id", $payload)
            : $this->gateway->request('POST', '/api/crm/atividades', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar a atividade.');

        return [
            'ok' => true,
            'msg' => $id ? 'Atividade actualizada com sucesso.' : 'Atividade criada com sucesso.',
            'id' => $response->body['id'] ?? $id,
        ];
    }

    public function complete(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('ID invalido.');
        }

        $response = $this->gateway->request('POST', "/api/crm/atividades/$id/concluir");
        $this->ensureSuccess($response, 'Erro ao concluir a atividade.');
        return ['ok' => true];
    }

    public function delete(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('ID invalido.');
        }

        $response = $this->gateway->request('DELETE', "/api/crm/atividades/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar a atividade.');
        return ['ok' => true];
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
