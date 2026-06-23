<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Product;

use E258Tech\Model\Service\NexoraService;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Contract\NexoraGateway;

final class ProductService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    public function saveCategory(?int $id, array $payload): array
    {
        if (!$id && ($payload['nome'] ?? '') === '') {
            throw new OperationException('O nome da categoria e obrigatorio.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/produtos/categorias/$id", $payload)
            : $this->gateway->request('POST', '/api/produtos/categorias', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar a categoria.');

        return [
            'ok' => true,
            'msg' => $id ? 'Categoria actualizada com sucesso.' : 'Categoria criada com sucesso.',
            'id' => $response->body['id'] ?? $id,
        ];
    }

    public function deleteCategory(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Categoria invalida.');
        }

        $response = $this->gateway->request('DELETE', "/api/produtos/categorias/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar a categoria.');

        return ['ok' => true];
    }

    public function saveBrand(?int $id, array $payload): array
    {
        if (!$id && ($payload['nome'] ?? '') === '') {
            throw new OperationException('O nome da marca e obrigatorio.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/produtos/marcas/$id", $payload)
            : $this->gateway->request('POST', '/api/produtos/marcas', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar a marca.');

        return [
            'ok' => true,
            'msg' => $id ? 'Marca actualizada com sucesso.' : 'Marca criada com sucesso.',
            'id' => $response->body['id'] ?? $id,
        ];
    }

    public function saveUnit(?int $id, array $payload): array
    {
        if (!$id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '')) {
            throw new OperationException('O codigo e o nome da unidade sao obrigatorios.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/produtos/unidades/$id", $payload)
            : $this->gateway->request('POST', '/api/produtos/unidades', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar a unidade.');

        return [
            'ok' => true,
            'msg' => $id ? 'Unidade actualizada com sucesso.' : 'Unidade criada com sucesso.',
            'id' => $response->body['id'] ?? $id,
        ];
    }

    public function saveProduct(?int $id, array $payload): array
    {
        if (!$id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '')) {
            throw new OperationException('O codigo e o nome do produto sao obrigatorios.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/produtos/$id", $payload)
            : $this->gateway->request('POST', '/api/produtos', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o produto.');

        return [
            'ok' => true,
            'msg' => $id ? 'Produto actualizado com sucesso.' : 'Produto criado com sucesso.',
            'id' => $response->body['id'] ?? $id,
        ];
    }

    public function setPrice(int $productId, array $payload): array
    {
        if ($productId <= 0) {
            throw new OperationException('Produto invalido.');
        }
        if (!isset($payload['valor']) || (float) $payload['valor'] < 0) {
            throw new OperationException('O valor do preco deve ser positivo.');
        }

        $response = $this->gateway->request('POST', "/api/produtos/$productId/precos", $payload);
        $this->ensureSuccess($response, 'Erro ao guardar o preco.');

        return ['ok' => true, 'msg' => 'Preco guardado com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function createVariant(int $productId, array $payload): array
    {
        if ($productId <= 0) {
            throw new OperationException('Produto invalido.');
        }
        if (($payload['sku'] ?? '') === '') {
            throw new OperationException('O SKU da variante e obrigatorio.');
        }

        $response = $this->gateway->request('POST', "/api/produtos/$productId/variantes", $payload);
        $this->ensureSuccess($response, 'Erro ao guardar a variante.');

        return ['ok' => true, 'msg' => 'Variante criada com sucesso.', 'id' => $response->body['id'] ?? null];
    }
}
