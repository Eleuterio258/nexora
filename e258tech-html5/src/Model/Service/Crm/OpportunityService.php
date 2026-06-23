<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Crm;

use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Http\HttpResponse;

final class OpportunityService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    public function save(?int $id, array $payload): array
    {
        if (($payload['titulo'] ?? '') === '') {
            throw new OperationException('O titulo e obrigatorio.');
        }

        $date = $payload['data_fecho_prevista'] ?? null;
        if ($date && !preg_match('/^\d{4}-\d{2}-\d{2}$/', (string) $date)) {
            throw new OperationException('Formato de data invalido.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/crm/oportunidades/$id", $payload)
            : $this->gateway->request('POST', '/api/crm/oportunidades', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar a oportunidade.');

        return [
            'ok' => true,
            'msg' => $id ? 'Oportunidade actualizada com sucesso.' : 'Oportunidade criada com sucesso.',
            'id' => $response->body['id'] ?? $id,
        ];
    }

    public function move(int $id, string $stage): array
    {
        if ($id <= 0 || $stage === '') {
            throw new OperationException('Dados invalidos.');
        }

        $this->assertCanMove($id, $stage);
        $response = $this->gateway->request(
            'PUT',
            "/api/crm/oportunidades/$id/estagio",
            ['estagio' => $stage]
        );
        $this->ensureSuccess($response, 'Erro ao mover a oportunidade.');
        return ['ok' => true];
    }

    public function markLost(int $id, ?string $reason): array
    {
        if ($id <= 0) {
            throw new OperationException('ID invalido.');
        }

        $this->assertOpen($id);
        $response = $this->gateway->request(
            'POST',
            "/api/crm/oportunidades/$id/perder",
            ['motivo_perda' => $reason ?: null]
        );
        $this->ensureSuccess($response, 'Erro ao marcar a oportunidade como perdida.');
        return ['ok' => true];
    }

    public function delete(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('ID invalido.');
        }

        $response = $this->gateway->request('DELETE', "/api/crm/oportunidades/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar a oportunidade.');
        return ['ok' => true];
    }

    private function assertOpen(int $id): void
    {
        $current = $this->gateway->request('GET', "/api/crm/oportunidades/$id");
        $this->ensureSuccess($current, 'Oportunidade nao encontrada.');

        if (in_array($current->body['estagio'] ?? null, ['ganho', 'perdido'], true)) {
            throw new OperationException(
                'Esta oportunidade ja esta fechada e nao pode mudar de estagio.'
            );
        }
    }

    private function assertCanMove(int $id, string $targetStage): void
    {
        $current = $this->gateway->request('GET', "/api/crm/oportunidades/$id");
        $this->ensureSuccess($current, 'Oportunidade nao encontrada.');

        $currentStage = $current->body['estagio'] ?? null;
        if (in_array($currentStage, ['ganho', 'perdido'], true) && $currentStage !== $targetStage) {
            throw new OperationException(
                'Esta oportunidade ja esta fechada e nao pode mudar de estagio.'
            );
        }
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
