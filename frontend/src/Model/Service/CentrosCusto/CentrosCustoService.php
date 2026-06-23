<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\CentrosCusto;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

final class CentrosCustoService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    public function listCostCenters(array $filters = []): array
    {
        $path = '/api/centros-custo/cost-centers';
        if ($filters) {
            $path .= '?' . http_build_query($filters);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter os centros de custo.');

        return $response->body ?? [];
    }

    public function getCostCenter(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Centro de custo inválido.');
        }

        $response = $this->gateway->request('GET', "/api/centros-custo/cost-centers/$id");
        $this->ensureSuccess($response, 'Erro ao obter o centro de custo.');

        return $response->body ?? [];
    }

    public function saveCostCenter(?int $id, array $payload): array
    {
        if (! $id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '')) {
            throw new OperationException('O código e o nome do centro de custo são obrigatórios.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/centros-custo/cost-centers/$id", $payload)
            : $this->gateway->request('POST', '/api/centros-custo/cost-centers', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o centro de custo.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Centro de custo actualizado com sucesso.' : 'Centro de custo criado com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function deleteCostCenter(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Centro de custo inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/centros-custo/cost-centers/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar o centro de custo.');

        return ['ok' => true, 'msg' => 'Centro de custo eliminado com sucesso.'];
    }

    public function listBudgets(array $filters = []): array
    {
        $path = '/api/centros-custo/budgets';
        if ($filters) {
            $path .= '?' . http_build_query($filters);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter os orçamentos.');

        return $response->body ?? [];
    }

    public function saveBudget(?int $id, array $payload): array
    {
        if (! $id && (($payload['cost_center_id'] ?? 0) === 0 || ($payload['ano'] ?? 0) === 0)) {
            throw new OperationException('O centro de custo e o ano são obrigatórios.');
        }
        if (($payload['valor_orcamentado'] ?? null) === null) {
            throw new OperationException('O valor orçamentado é obrigatório.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/centros-custo/budgets/$id", $payload)
            : $this->gateway->request('POST', '/api/centros-custo/budgets', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o orçamento.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Orçamento actualizado com sucesso.' : 'Orçamento criado com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function deleteBudget(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Orçamento inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/centros-custo/budgets/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar o orçamento.');

        return ['ok' => true, 'msg' => 'Orçamento eliminado com sucesso.'];
    }

    public function getBudgetVsRealizado(int $ano, ?int $mes = null, ?int $costCenterId = null): array
    {
        if ($ano <= 0) {
            throw new OperationException('O ano é obrigatório.');
        }

        $query = ['ano' => $ano];
        if ($mes !== null) {
            $query['mes'] = $mes;
        }
        if ($costCenterId !== null) {
            $query['cost_center_id'] = $costCenterId;
        }

        $response = $this->gateway->request('GET', '/api/centros-custo/budgets/vs-realizado?' . http_build_query($query));
        $this->ensureSuccess($response, 'Erro ao obter o orçado vs realizado.');

        return $response->body ?? [];
    }

    public function listAllocations(array $filters = []): array
    {
        $path = '/api/centros-custo/allocations';
        if ($filters) {
            $path .= '?' . http_build_query($filters);
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter as alocações.');

        return $response->body ?? [];
    }

    public function getAllocation(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Alocação inválida.');
        }

        $response = $this->gateway->request('GET', "/api/centros-custo/allocations/$id");
        $this->ensureSuccess($response, 'Erro ao obter a alocação.');

        return $response->body ?? [];
    }

    public function createAllocation(array $payload): array
    {
        if (($payload['cost_center_id'] ?? 0) === 0
            || ($payload['source_service'] ?? '') === ''
            || ($payload['source_type'] ?? '') === ''
            || ($payload['source_id'] ?? 0) === 0
            || ($payload['valor'] ?? null) === null
        ) {
            throw new OperationException('O centro de custo, a origem e o valor são obrigatórios.');
        }

        $response = $this->gateway->request('POST', '/api/centros-custo/allocations', $payload);
        $this->ensureSuccess($response, 'Erro ao registar a alocação.');

        return [
            'ok'  => true,
            'msg' => 'Alocação registada com sucesso.',
            'id'  => $response->body['id'] ?? null,
        ];
    }
}
