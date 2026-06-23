<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Customer;

use E258Tech\Model\Service\NexoraService;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Contract\NexoraGateway;

final class CustomerService extends NexoraService
{
    private const STATUS_ACTIONS = ['activar', 'bloquear', 'desbloquear'];

    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    public function save(?int $id, array $payload): array
    {
        if (($payload['nome'] ?? '') === '') {
            throw new OperationException('O nome e obrigatorio.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/clientes/$id", $payload)
            : $this->gateway->request('POST', '/api/clientes', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o cliente.');

        return [
            'ok' => true,
            'msg' => $id ? 'Cliente actualizado com sucesso.' : 'Cliente criado com sucesso.',
            'id' => $response->body['id'] ?? $id,
        ];
    }

    public function setStatus(int $id, string $action): array
    {
        if ($id <= 0 || !in_array($action, self::STATUS_ACTIONS, true)) {
            throw new OperationException('Dados invalidos.');
        }

        $response = $this->gateway->request('POST', "/api/clientes/$id/$action");
        $this->ensureSuccess($response, 'Erro ao actualizar o estado do cliente.');

        return ['ok' => true];
    }

    public function saveGroup(?int $id, array $payload): array
    {
        if (!$id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '')) {
            throw new OperationException('O codigo e o nome do grupo sao obrigatorios.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/clientes/grupos/$id", $payload)
            : $this->gateway->request('POST', '/api/clientes/grupos', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o grupo.');

        return [
            'ok' => true,
            'msg' => $id ? 'Grupo actualizado com sucesso.' : 'Grupo criado com sucesso.',
            'id' => $response->body['id'] ?? $id,
        ];
    }

    public function saveContact(int $customerId, ?int $contactId, array $payload): array
    {
        if ($customerId <= 0) {
            throw new OperationException('Cliente invalido.');
        }
        if (!$contactId && ($payload['nome'] ?? '') === '') {
            throw new OperationException('O nome do contacto e obrigatorio.');
        }

        $response = $contactId
            ? $this->gateway->request('PUT', "/api/clientes/$customerId/contactos/$contactId", $payload)
            : $this->gateway->request('POST', "/api/clientes/$customerId/contactos", $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o contacto.');

        return ['ok' => true, 'msg' => 'Contacto guardado com sucesso.', 'id' => $response->body['id'] ?? $contactId];
    }

    public function deleteContact(int $customerId, int $contactId): array
    {
        if ($customerId <= 0 || $contactId <= 0) {
            throw new OperationException('Dados invalidos.');
        }

        $response = $this->gateway->request('DELETE', "/api/clientes/$customerId/contactos/$contactId");
        $this->ensureSuccess($response, 'Erro ao eliminar o contacto.');

        return ['ok' => true];
    }

    public function saveAddress(int $customerId, ?int $addressId, array $payload): array
    {
        if ($customerId <= 0) {
            throw new OperationException('Cliente invalido.');
        }
        if (!$addressId && ($payload['endereco'] ?? '') === '') {
            throw new OperationException('O endereco e obrigatorio.');
        }

        $response = $addressId
            ? $this->gateway->request('PUT', "/api/clientes/$customerId/enderecos/$addressId", $payload)
            : $this->gateway->request('POST', "/api/clientes/$customerId/enderecos", $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o endereco.');

        return ['ok' => true, 'msg' => 'Endereco guardado com sucesso.', 'id' => $response->body['id'] ?? $addressId];
    }

    public function deleteAddress(int $customerId, int $addressId): array
    {
        if ($customerId <= 0 || $addressId <= 0) {
            throw new OperationException('Dados invalidos.');
        }

        $response = $this->gateway->request('DELETE', "/api/clientes/$customerId/enderecos/$addressId");
        $this->ensureSuccess($response, 'Erro ao eliminar o endereco.');

        return ['ok' => true];
    }

    public function updateCreditLimit(int $customerId, array $payload): array
    {
        if ($customerId <= 0) {
            throw new OperationException('Cliente invalido.');
        }
        if (!isset($payload['limite']) || (float) $payload['limite'] < 0) {
            throw new OperationException('O limite deve ser um valor positivo.');
        }
        if (($payload['motivo'] ?? '') === '') {
            throw new OperationException('O motivo e obrigatorio.');
        }

        $response = $this->gateway->request('PUT', "/api/clientes/$customerId/credito", $payload);
        $this->ensureSuccess($response, 'Erro ao actualizar o limite de credito.');

        return ['ok' => true, 'msg' => 'Limite de credito actualizado com sucesso.'];
    }

    public function registerPayment(int $customerId, array $payload): array
    {
        if ($customerId <= 0) {
            throw new OperationException('Cliente invalido.');
        }
        if (($payload['metodo'] ?? '') === '') {
            throw new OperationException('O metodo de pagamento e obrigatorio.');
        }
        if (!isset($payload['valor']) || (float) $payload['valor'] <= 0) {
            throw new OperationException('O valor deve ser superior a zero.');
        }

        $response = $this->gateway->request('POST', "/api/clientes/$customerId/pagamentos", $payload);
        $this->ensureSuccess($response, 'Erro ao registar o pagamento.');

        return ['ok' => true, 'msg' => 'Pagamento registado com sucesso.', 'id' => $response->body['id'] ?? null];
    }
}
