<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\SuperAdmin;

use E258Tech\Model\Service\NexoraService;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Contract\NexoraGateway;

final class SuperAdminService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    // Dashboard
    public function dashboard(): array
    {
        $response = $this->gateway->request('GET', '/api/superadmin/dashboard');
        $this->ensureSuccess($response, 'Erro ao carregar dashboard.');
        return $response->body;
    }

    // Tenants
    public function listTenants(array $filters = []): array
    {
        $query = http_build_query(array_filter($filters));
        $response = $this->gateway->request('GET', '/api/superadmin/tenants' . ($query ? '?' . $query : ''));
        $this->ensureSuccess($response, 'Erro ao listar tenants.');
        return $response->body;
    }

    public function getTenant(int $id): array
    {
        $response = $this->gateway->request('GET', "/api/superadmin/tenants/$id");
        $this->ensureSuccess($response, 'Erro ao obter tenant.');
        return $response->body;
    }

    public function saveTenant(int $id, array $payload): array
    {
        if (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '') {
            throw new OperationException('Codigo e nome sao obrigatorios.');
        }

        if ($id > 0) {
            $response = $this->gateway->request('PUT', "/api/superadmin/tenants/$id", $payload);
        } else {
            $response = $this->gateway->request('POST', '/api/superadmin/tenants', $payload);
        }
        $this->ensureSuccess($response, 'Erro ao guardar tenant.');
        return ['ok' => true, 'data' => $response->body];
    }

    public function deleteTenant(int $id): array
    {
        $response = $this->gateway->request('DELETE', "/api/superadmin/tenants/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar tenant.');
        return ['ok' => true];
    }

    public function criarFuncionarioTenant(int $tenantId, array $payload): array
    {
        if (($payload['nome_completo'] ?? '') === '') {
            throw new OperationException('O nome completo é obrigatório.');
        }
        $response = $this->gateway->request('POST', "/api/superadmin/tenants/$tenantId/funcionarios", $payload);
        $this->ensureSuccess($response, 'Erro ao criar funcionário.');
        return ['ok' => true, 'msg' => 'Funcionário criado com sucesso.', 'data' => $response->body];
    }

    public function proximoNumeroFuncionarioTenant(int $tenantId): array
    {
        $response = $this->gateway->request('GET', "/api/superadmin/tenants/$tenantId/funcionarios/proximo-numero");
        $this->ensureSuccess($response, 'Erro ao obter o próximo número de funcionário.');
        return $response->body ?? [];
    }

    public function changeTenantStatus(int $id, string $status): array
    {
        $map = [
            'suspenso' => 'suspender',
            'ativo' => 'reativar',
            'inativo' => 'inativar',
        ];
        if (!isset($map[$status])) {
            throw new OperationException('Estado invalido.');
        }
        $response = $this->gateway->request('POST', "/api/superadmin/tenants/$id/{$map[$status]}");
        $this->ensureSuccess($response, 'Erro ao alterar estado do tenant.');
        return ['ok' => true, 'data' => $response->body];
    }

    // Planos
    public function listPlans(): array
    {
        $response = $this->gateway->request('GET', '/api/superadmin/plans');
        $this->ensureSuccess($response, 'Erro ao listar planos.');
        return $response->body;
    }

    public function savePlan(int $id, array $payload): array
    {
        if (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '') {
            throw new OperationException('Codigo e nome sao obrigatorios.');
        }

        if ($id > 0) {
            $response = $this->gateway->request('PUT', "/api/superadmin/plans/$id", $payload);
        } else {
            $response = $this->gateway->request('POST', '/api/superadmin/plans', $payload);
        }
        $this->ensureSuccess($response, 'Erro ao guardar plano.');
        return ['ok' => true, 'data' => $response->body];
    }

    public function deletePlan(int $id): array
    {
        $response = $this->gateway->request('DELETE', "/api/superadmin/plans/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar plano.');
        return ['ok' => true];
    }

    // Modulos
    public function listAvailableModules(): array
    {
        $response = $this->gateway->request('GET', '/api/superadmin/modules/disponiveis');
        $this->ensureSuccess($response, 'Erro ao listar modulos disponiveis.');
        return $response->body;
    }

    public function listTenantModules(int $tenantId): array
    {
        $response = $this->gateway->request('GET', "/api/superadmin/modules/tenants/$tenantId");
        $this->ensureSuccess($response, 'Erro ao listar modulos do tenant.');
        return $response->body;
    }

    public function updateTenantModule(int $tenantId, string $modulo, bool $ativo, array $config = []): array
    {
        $response = $this->gateway->request('POST', "/api/superadmin/modules/tenants/$tenantId/$modulo", [
            'ativo' => $ativo,
            'config' => $config,
        ]);
        $this->ensureSuccess($response, 'Erro ao actualizar modulo do tenant.');
        return ['ok' => true, 'data' => $response->body];
    }

    public function resetTenantModules(int $tenantId): array
    {
        $response = $this->gateway->request('POST', "/api/superadmin/modules/tenants/$tenantId/reset");
        $this->ensureSuccess($response, 'Erro ao resetar modulos do tenant.');
        return ['ok' => true];
    }

    // Utilizadores globais
    public function listGlobalUsers(array $filters = []): array
    {
        $query = http_build_query(array_filter($filters));
        $response = $this->gateway->request('GET', '/api/superadmin/utilizadores' . ($query ? '?' . $query : ''));
        $this->ensureSuccess($response, 'Erro ao listar utilizadores.');
        return $response->body;
    }

    // Configuracoes globais
    public function listGlobalSettings(): array
    {
        $response = $this->gateway->request('GET', '/api/superadmin/settings');
        $this->ensureSuccess($response, 'Erro ao listar configuracoes globais.');
        return $response->body;
    }

    public function saveGlobalSetting(string $chave, ?string $valor, ?string $descricao = null): array
    {
        $response = $this->gateway->request('PUT', '/api/superadmin/settings', [
            'chave' => $chave,
            'valor' => $valor,
            'descricao' => $descricao,
        ]);
        $this->ensureSuccess($response, 'Erro ao guardar configuracao global.');
        return ['ok' => true, 'data' => $response->body];
    }
}
