<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Recruitment;

use E258Tech\Model\Service\NexoraService;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Contract\NexoraGateway;

final class RecruitmentAdminService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    public function moveApplication(int $id, string $state): array
    {
        if ($id <= 0 || $state === '') {
            throw new OperationException('Dados invalidos.');
        }

        $current = $this->gateway->request('GET', "/api/recrutamento/candidaturas/$id");
        $this->ensureSuccess($current, 'Candidatura nao encontrada.');
        $currentState = $current->body['estado'] ?? null;

        if (in_array($currentState, ['aprovada', 'rejeitada'], true) && $currentState !== $state) {
            throw new OperationException(
                'Esta candidatura ja esta numa fase final e nao pode mudar de estado.'
            );
        }

        $response = $this->gateway->request(
            'PUT',
            "/api/recrutamento/candidaturas/$id/estado",
            ['estado' => $state]
        );
        $this->ensureSuccess($response, 'Erro ao actualizar candidatura.');
        return ['ok' => true];
    }

    public function evaluateApplication(int $id, int $score, ?string $note): array
    {
        if ($id <= 0 || $score < 0 || $score > 5) {
            throw new OperationException('Dados invalidos.');
        }

        $response = $this->gateway->request(
            'POST',
            "/api/recrutamento/candidaturas/$id/avaliar",
            ['score' => $score ?: null, 'nota' => $note ?: null]
        );
        $this->ensureSuccess($response, 'Erro ao avaliar candidatura.');
        return ['ok' => true];
    }

    public function scheduleInterview(int $id, array $payload): array
    {
        if ($id <= 0) {
            throw new OperationException('ID invalido.');
        }

        $response = $this->gateway->request(
            'POST',
            "/api/recrutamento/candidaturas/$id/entrevista",
            $payload
        );
        $this->ensureSuccess($response, 'Erro ao guardar entrevista.');
        return ['ok' => true];
    }

    public function addNote(int $id, string $content): array
    {
        if ($id <= 0 || $content === '') {
            throw new OperationException('Dados invalidos.');
        }

        $response = $this->gateway->request(
            'POST',
            "/api/recrutamento/candidaturas/$id/notas",
            ['conteudo' => $content]
        );
        $this->ensureSuccess($response, 'Erro ao guardar nota.');
        return ['ok' => true];
    }

    public function saveVacancy(?int $id, array $payload): array
    {
        if (($payload['titulo'] ?? '') === '') {
            throw new OperationException('O titulo e obrigatorio.');
        }
        if (($payload['area'] ?? '') === '') {
            throw new OperationException('A area e obrigatoria.');
        }
        if (!empty($payload['prazo']) && !preg_match('/^\d{4}-\d{2}-\d{2}$/', $payload['prazo'])) {
            throw new OperationException('Formato de prazo invalido.');
        }

        $response = $this->gateway->request(
            $id ? 'PUT' : 'POST',
            $id ? "/api/recrutamento/vagas/$id" : '/api/recrutamento/vagas',
            $payload
        );
        $this->ensureSuccess($response, 'Erro ao guardar vaga.');

        return [
            'ok' => true,
            'msg' => $id ? 'Vaga actualizada com sucesso.' : 'Vaga criada com sucesso.',
            'id' => $response->body['id'] ?? $id,
        ];
    }

    public function deleteVacancy(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('ID invalido.');
        }

        $response = $this->gateway->request('DELETE', "/api/recrutamento/vagas/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar vaga.');
        return ['ok' => true];
    }

    public function toggleVacancy(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('ID invalido.');
        }

        $current = $this->gateway->request('GET', "/api/recrutamento/vagas/$id");
        $this->ensureSuccess($current, 'Vaga nao encontrada.');
        $action = empty($current->body['ativa']) ? 'activar' : 'desactivar';

        $response = $this->gateway->request('POST', "/api/recrutamento/vagas/$id/$action");
        $this->ensureSuccess($response, 'Erro ao actualizar vaga.');
        return ['ok' => true, 'ativa' => (bool) ($response->body['ativa'] ?? false)];
    }

    public function saveCustomField(?int $id, array $payload): array
    {
        if (($payload['codigo'] ?? '') === '' || ($payload['label'] ?? '') === '') {
            throw new OperationException('Codigo e label sao obrigatorios.');
        }
        if (!in_array($payload['tipo'] ?? '', ['texto','textarea','numero','data','select','multiselect','checkbox','ficheiro'], true)) {
            throw new OperationException('Tipo de campo invalido.');
        }

        $response = $this->gateway->request(
            $id ? 'PUT' : 'POST',
            $id ? "/api/recrutamento/campos-custom/$id" : '/api/recrutamento/campos-custom',
            $payload
        );
        $this->ensureSuccess($response, 'Erro ao guardar campo customizavel.');
        return ['ok' => true, 'id' => $response->body['id'] ?? $id];
    }

    public function deleteCustomField(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('ID invalido.');
        }
        $response = $this->gateway->request('DELETE', "/api/recrutamento/campos-custom/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar campo customizavel.');
        return ['ok' => true];
    }

    public function saveNotificationConfig(array $payload): array
    {
        $response = $this->gateway->request('PUT', '/api/recrutamento/config-notificacoes', $payload);
        $this->ensureSuccess($response, 'Erro ao guardar configuracao de notificacoes.');
        return ['ok' => true];
    }

    public function markContactAsRead(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('ID invalido.');
        }
        $response = $this->gateway->request('POST', "/api/recrutamento/contactos/$id/lido");
        $this->ensureSuccess($response, 'Erro ao marcar contacto como lido.');
        return ['ok' => true];
    }

    public function contratar(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('ID invalido.');
        }
        $response = $this->gateway->request('POST', "/api/recrutamento/candidaturas/$id/contratar");
        $this->ensureSuccess($response, 'Erro ao contratar candidato.');
        return array_merge(['ok' => true], (array) ($response->body ?? []));
    }
}
