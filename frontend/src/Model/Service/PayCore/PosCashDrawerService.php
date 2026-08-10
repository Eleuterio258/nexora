<?php

declare(strict_types=1);

namespace E258Tech\Model\Service\PayCore;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

/**
 * Gestão de sessões de caixa (cash drawers) do PayCore.
 */
final class PosCashDrawerService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    /**
     * Lista todas as sessões de caixa.
     *
     * @return array<int, array<string, mixed>>
     */
    public function list(): array
    {
        $response = $this->gateway->request('GET', '/api/v1/cash-drawers');
        $this->ensureSuccess($response, 'Erro ao listar as sessoes de caixa.');

        return $response->body ?? [];
    }

    /**
     * Busca uma sessão pelo ID.
     *
     * @return array<string, mixed>
     */
    public function get(string $id): array
    {
        if ($id === '') {
            throw new OperationException('Sessao invalida.');
        }

        $response = $this->gateway->request('GET', "/api/v1/cash-drawers/$id");
        $this->ensureSuccess($response, 'Erro ao carregar a sessao de caixa.');

        return $response->body ?? [];
    }

    /**
     * Resumo financeiro de uma sessão.
     *
     * @return array<string, mixed>
     */
    public function summary(string $id): array
    {
        if ($id === '') {
            throw new OperationException('Sessao invalida.');
        }

        $response = $this->gateway->request('GET', "/api/v1/cash-drawers/$id/summary");
        $this->ensureSuccess($response, 'Erro ao carregar o resumo da sessao.');

        return $response->body ?? [];
    }

    /**
     * Abre uma nova sessão de caixa.
     *
     * @param array<string, mixed> $payload
     * @return array<string, mixed>
     */
    public function open(array $payload): array
    {
        $amount = (float) ($payload['initialAmount'] ?? 0);
        if ($amount < 0) {
            throw new OperationException('O valor inicial nao pode ser negativo.');
        }

        $response = $this->gateway->request('POST', '/api/v1/cash-drawers/open', [
            'terminalId' => $payload['terminalId'] ?? null,
            'initialAmount' => $amount,
            'observations' => $payload['observations'] ?? null,
        ]);
        $this->ensureSuccess($response, 'Erro ao abrir a sessao de caixa.');

        return $response->body ?? [];
    }

    /**
     * Fecha uma sessão de caixa.
     *
     * @param array<string, mixed> $payload
     * @return array<string, mixed>
     */
    public function close(string $id, array $payload): array
    {
        if ($id === '') {
            throw new OperationException('Sessao invalida.');
        }

        $finalAmount = (float) ($payload['finalAmount'] ?? 0);
        if ($finalAmount < 0) {
            throw new OperationException('O valor final nao pode ser negativo.');
        }

        $response = $this->gateway->request('POST', "/api/v1/cash-drawers/$id/close", [
            'finalAmount' => $finalAmount,
            'observations' => $payload['observations'] ?? null,
        ]);
        $this->ensureSuccess($response, 'Erro ao fechar a sessao de caixa.');

        return $response->body ?? [];
    }

    /**
     * Lista os movimentos de uma sessão.
     *
     * @return array<int, array<string, mixed>>
     */
    public function movements(string $id): array
    {
        if ($id === '') {
            throw new OperationException('Sessao invalida.');
        }

        $response = $this->gateway->request('GET', "/api/v1/cash-drawers/$id/movements");
        $this->ensureSuccess($response, 'Erro ao carregar os movimentos da sessao.');

        return $response->body ?? [];
    }

    /**
     * Regista um movimento manual na sessão (sangria, suprimento, etc.).
     *
     * @param array<string, mixed> $payload
     * @return array<string, mixed>
     */
    public function addMovement(string $id, array $payload): array
    {
        if ($id === '') {
            throw new OperationException('Sessao invalida.');
        }

        $type = $payload['type'] ?? '';
        if (!in_array($type, ['INFLOW', 'OUTFLOW'], true)) {
            throw new OperationException('O tipo de movimento e invalido.');
        }

        $amount = (float) ($payload['amount'] ?? 0);
        if ($amount <= 0) {
            throw new OperationException('O valor deve ser superior a zero.');
        }

        $description = trim((string) ($payload['description'] ?? ''));
        if ($description === '') {
            throw new OperationException('A descricao e obrigatoria.');
        }

        $response = $this->gateway->request('POST', "/api/v1/cash-drawers/$id/movements", [
            'type' => $type,
            'amount' => $amount,
            'description' => $description,
            'referenceId' => $payload['referenceId'] ?? null,
            'referenceType' => $payload['referenceType'] ?? null,
        ]);
        $this->ensureSuccess($response, 'Erro ao registar o movimento.');

        return $response->body ?? [];
    }
}
