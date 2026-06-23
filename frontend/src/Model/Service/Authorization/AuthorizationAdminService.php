<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Authorization;

use E258Tech\Model\Service\NexoraService;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Contract\NexoraGateway;

final class AuthorizationAdminService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    public function saveRole(?int $id, string $name, ?string $description): array
    {
        if ($name === '') {
            throw new OperationException('O nome e obrigatorio.');
        }

        $response = $this->gateway->request(
            $id ? 'PUT' : 'POST',
            $id ? "/api/auth/cargos/$id" : '/api/auth/cargos',
            ['nome' => $name, 'descricao' => $description]
        );
        $this->ensureSuccess($response, 'Erro ao guardar cargo.');

        return [
            'ok' => true,
            'msg' => $id ? 'Cargo actualizado com sucesso.' : 'Cargo criado com sucesso.',
            'id' => $response->body['id'] ?? $id,
        ];
    }

    public function setRoleState(int $id, bool $active): array
    {
        if ($id <= 0) {
            throw new OperationException('Pedido invalido.');
        }
        $action = $active ? 'activar' : 'desactivar';
        $response = $this->gateway->request('POST', "/api/auth/cargos/$id/$action");
        $this->ensureSuccess($response, 'Erro ao actualizar estado.');
        return ['ok' => true];
    }

    public function rolePermissions(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Pedido invalido.');
        }
        $response = $this->gateway->request('GET', "/api/auth/cargos/$id/permissoes");
        $this->ensureSuccess($response, 'Erro ao obter permissoes do cargo.');
        return ['ok' => true, 'permissoes' => $response->body ?? []];
    }

    public function updateRolePermissions(int $id, array $permissions): array
    {
        return $this->updatePermissions("/api/auth/cargos/$id/permissoes", $id, $permissions);
    }

    public function saveUser(?int $id, array $payload): array
    {
        if (($payload['nome'] ?? '') === '') {
            throw new OperationException('O nome e obrigatorio.');
        }

        if (!$id) {
            if (!filter_var($payload['email'] ?? '', FILTER_VALIDATE_EMAIL)) {
                throw new OperationException('Email invalido.');
            }
            if (strlen((string) ($payload['password'] ?? '')) < 8) {
                throw new OperationException('A palavra-passe deve ter pelo menos 8 caracteres.');
            }
        }

        $response = $this->gateway->request(
            $id ? 'PUT' : 'POST',
            $id ? "/api/auth/utilizadores/$id" : '/api/auth/utilizadores',
            $payload
        );
        $this->ensureSuccess($response, 'Erro ao guardar utilizador.');
        return [
            'ok' => true,
            'msg' => $id ? 'Utilizador actualizado com sucesso.' : 'Utilizador criado com sucesso.',
            'id' => $response->body['id'] ?? $id,
        ];
    }

    public function setUserState(int $id, string $action): array
    {
        if ($id <= 0 || !in_array($action, ['activar', 'bloquear', 'desactivar'], true)) {
            throw new OperationException('Pedido invalido.');
        }
        $response = $this->gateway->request('POST', "/api/auth/utilizadores/$id/$action");
        $this->ensureSuccess($response, 'Erro ao actualizar estado.');
        return ['ok' => true, 'estado' => $response->body['estado'] ?? null];
    }

    public function assignRole(int $id, ?int $roleId): array
    {
        if ($id <= 0) {
            throw new OperationException('Pedido invalido.');
        }
        $response = $this->gateway->request(
            'PUT',
            "/api/auth/utilizadores/$id/cargo",
            ['cargo_id' => $roleId]
        );
        $this->ensureSuccess($response, 'Erro ao atribuir cargo.');
        return ['ok' => true];
    }

    public function updateUserPermissions(int $id, array $permissions): array
    {
        return $this->updatePermissions("/api/auth/utilizadores/$id/permissoes", $id, $permissions);
    }

    public function setUserTipo(int $id, string $tipo): array
    {
        if ($id <= 0 || !in_array($tipo, ['funcionario', 'superadmin'], true)) {
            throw new OperationException('Dados inválidos.');
        }
        $response = $this->gateway->request('PUT', "/api/auth/utilizadores/$id/tipo", ['tipo' => $tipo]);
        $this->ensureSuccess($response, 'Erro ao alterar o tipo de utilizador.');
        return ['ok' => true, 'msg' => 'Tipo actualizado. O utilizador deve fazer login novamente.'];
    }

    public function resetUserPassword(int $id, string $password): array
    {
        if ($id <= 0 || strlen($password) < 8) {
            throw new OperationException('A senha deve ter pelo menos 8 caracteres.');
        }
        $response = $this->gateway->request('POST', "/api/auth/utilizadores/$id/reset-password", ['password' => $password]);
        $this->ensureSuccess($response, 'Erro ao redefinir a senha.');
        return ['ok' => true, 'msg' => 'Senha redefinida com sucesso.'];
    }

    public function revokeSessions(?int $id, bool $all): array
    {
        if (!$all && (!$id || $id <= 0)) {
            throw new OperationException('Pedido invalido.');
        }
        $path = $all ? '/api/auth/sessoes/revogar-todas' : "/api/auth/sessoes/$id/revogar";
        $response = $this->gateway->request('POST', $path);
        $this->ensureSuccess($response, 'Erro ao revogar sessao.');
        return ['ok' => true];
    }

    private function updatePermissions(string $path, int $id, array $permissions): array
    {
        if ($id <= 0) {
            throw new OperationException('Pedido invalido.');
        }
        $response = $this->gateway->request('PUT', $path, ['permissoes' => $permissions]);
        $this->ensureSuccess($response, 'Erro ao guardar permissoes.');
        return ['ok' => true];
    }
}
