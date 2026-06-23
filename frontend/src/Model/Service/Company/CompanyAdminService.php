<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Company;

use E258Tech\Model\Service\NexoraService;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Contract\NexoraGateway;

final class CompanyAdminService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    public function updateCompany(int $id, array $payload): array
    {
        if ($id <= 0 || ($payload['nome'] ?? '') === '') {
            throw new OperationException('Empresa e nome sao obrigatorios.');
        }
        if (!in_array($payload['status'] ?? '', ['ativa', 'suspensa', 'inativa'], true)) {
            throw new OperationException('Estado invalido.');
        }

        $response = $this->gateway->request('PUT', "/api/companies/$id", $payload);
        $this->ensureSuccess($response, 'Erro ao actualizar empresa.');
        return ['ok' => true, 'msg' => 'Dados da empresa actualizados com sucesso.'];
    }

    public function updateTaxInfo(int $id, array $payload): array
    {
        if ($id <= 0 || ($payload['nuit'] ?? '') === '') {
            throw new OperationException('Empresa e NUIT sao obrigatorios.');
        }
        $date = $payload['inicio_atividade'] ?? null;
        if ($date && !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            throw new OperationException('Formato de data invalido para o inicio de atividade.');
        }

        $response = $this->gateway->request('PUT', "/api/companies/$id/tax-info", $payload);
        $this->ensureSuccess($response, 'Erro ao guardar dados fiscais.');
        return ['ok' => true, 'msg' => 'Dados fiscais guardados com sucesso.'];
    }

    public function createBranch(int $id, array $payload): array
    {
        if ($id <= 0 || ($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '') {
            throw new OperationException('Empresa, codigo e nome sao obrigatorios.');
        }
        $response = $this->gateway->request('POST', "/api/companies/$id/branches", $payload);
        $this->ensureSuccess($response, 'Erro ao criar filial.');
        return [
            'ok' => true,
            'msg' => 'Filial criada com sucesso.',
            'id' => $response->body['id'] ?? null,
        ];
    }

    public function setBranchState(int $id, int $branchId, string $status): array
    {
        if ($id <= 0 || $branchId <= 0 || !in_array($status, ['ativa', 'inativa'], true)) {
            throw new OperationException('Pedido invalido.');
        }
        $response = $this->gateway->request(
            'PUT',
            "/api/companies/$id/branches/$branchId",
            ['status' => $status]
        );
        $this->ensureSuccess($response, 'Erro ao actualizar filial.');
        return ['ok' => true];
    }

    public function createLicense(int $id, array $payload): array
    {
        if ($id <= 0 || !in_array($payload['plano'] ?? '', ['starter', 'professional', 'enterprise'], true)) {
            throw new OperationException('Empresa ou plano invalido.');
        }
        foreach (['inicia_em', 'expira_em'] as $field) {
            $date = $payload[$field] ?? null;
            if (($field === 'inicia_em' && !$date) || ($date && !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date))) {
                throw new OperationException('Data de licenca invalida.');
            }
        }

        $response = $this->gateway->request('POST', "/api/companies/$id/licenses", $payload);
        $this->ensureSuccess($response, 'Erro ao criar licenca.');
        return [
            'ok' => true,
            'msg' => 'Licenca adicionada com sucesso.',
            'id' => $response->body['id'] ?? null,
        ];
    }
}
