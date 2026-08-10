<?php

declare(strict_types=1);

namespace E258Tech\Model\Service\PayCore;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

/**
 * Gestão de utilizadores no PayCore (/api/v1/users).
 */
final class UserService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    /**
     * Lista utilizadores do tenant actual.
     *
     * @return array<int, array<string, mixed>>
     */
    public function list(?string $role = null): array
    {
        $path = '/api/v1/users';
        if ($role !== null && $role !== '') {
            $path .= '?' . http_build_query(['role' => $role]);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao listar utilizadores.');

        return $response->body ?? [];
    }

    /**
     * Busca um utilizador pelo ID.
     *
     * @return array<string, mixed>
     */
    public function get(string $id): array
    {
        if ($id === '') {
            throw new OperationException('Utilizador invalido.');
        }

        $response = $this->gateway->request('GET', "/api/v1/users/$id");
        $this->ensureSuccess($response, 'Erro ao carregar o utilizador.');

        return $response->body ?? [];
    }

    /**
     * Cria um novo utilizador.
     *
     * @param array<string, mixed> $data
     * @return array<string, mixed>
     */
    public function create(array $data): array
    {
        $payload = $this->normalizePayload($data);

        if (empty($payload['password'])) {
            throw new OperationException('A palavra-passe e obrigatoria.');
        }

        $response = $this->gateway->request('POST', '/api/v1/users', $payload);
        $this->ensureSuccess($response, 'Erro ao criar o utilizador.');

        return $response->body ?? [];
    }

    /**
     * Actualiza um utilizador.
     *
     * @param array<string, mixed> $data
     * @return array<string, mixed>
     */
    public function update(string $id, array $data): array
    {
        if ($id === '') {
            throw new OperationException('Utilizador invalido.');
        }

        $payload = $this->normalizePayload($data, true);

        $response = $this->gateway->request('PUT', "/api/v1/users/$id", $payload);
        $this->ensureSuccess($response, 'Erro ao actualizar o utilizador.');

        return $response->body ?? [];
    }

    /**
     * Remove um utilizador.
     */
    public function delete(string $id): void
    {
        if ($id === '') {
            throw new OperationException('Utilizador invalido.');
        }

        $response = $this->gateway->request('DELETE', "/api/v1/users/$id");
        $this->ensureSuccess($response, 'Erro ao remover o utilizador.');
    }

    /**
     * Altera a role do utilizador num tenant.
     */
    public function setTenantRole(string $userId, string $tenantId, string $role): array
    {
        if ($userId === '' || $tenantId === '') {
            throw new OperationException('Utilizador ou tenant invalido.');
        }

        $response = $this->gateway->request('PUT', "/api/v1/users/$userId/tenant-role/$tenantId", ['role' => $role]);
        $this->ensureSuccess($response, 'Erro ao alterar a permissao do utilizador.');

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
            'name' => 'name',
            'email' => 'email',
            'password' => 'password',
            'role' => 'role',
            'active' => 'active',
            'phone_number' => 'phoneNumber',
            'two_factor_enabled' => 'twoFactorEnabled',
        ];

        foreach ($fields as $snake => $camel) {
            if (array_key_exists($camel, $data)) {
                $payload[$camel] = $data[$camel];
            } elseif (array_key_exists($snake, $data)) {
                $payload[$camel] = $data[$snake];
            }
        }

        if (!$partial && empty($payload['name'])) {
            throw new OperationException('O nome do utilizador e obrigatorio.');
        }
        if (!$partial && empty($payload['email'])) {
            throw new OperationException('O email e obrigatorio.');
        }
        if (!$partial && empty($payload['role'])) {
            throw new OperationException('O perfil e obrigatorio.');
        }

        if (isset($payload['role'])) {
            $payload['role'] = strtoupper($payload['role']);
            if (!in_array($payload['role'], ['SUPER_ADMIN', 'ADMIN', 'OPERADOR'], true)) {
                throw new OperationException('Perfil invalido. Use SUPER_ADMIN, ADMIN ou OPERADOR.');
            }
        }

        return $payload;
    }
}
