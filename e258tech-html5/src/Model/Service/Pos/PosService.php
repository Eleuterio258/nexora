<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Pos;

use E258Tech\Model\Service\NexoraService;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Contract\NexoraGateway;

final class PosService extends NexoraService
{
    private const PAGAMENTO_TIPOS = ['numerario', 'transferencia', 'tpa', 'mpesa', 'emola', 'outro'];

    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    public function createTerminal(array $payload): array
    {
        if (trim((string) ($payload['codigo'] ?? '')) === '') {
            throw new OperationException('O codigo do terminal e obrigatorio.');
        }
        if (trim((string) ($payload['nome'] ?? '')) === '') {
            throw new OperationException('O nome do terminal e obrigatorio.');
        }

        $response = $this->gateway->request('POST', '/api/pos/terminais', $payload);
        $this->ensureSuccess($response, 'Erro ao criar o terminal.');

        return ['ok' => true, 'msg' => 'Terminal criado com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function addCatalogItem(array $payload): array
    {
        if (($payload['product_id'] ?? 0) <= 0) {
            throw new OperationException('O produto e obrigatorio.');
        }
        if (($payload['preco_venda'] ?? -1) < 0) {
            throw new OperationException('O preco de venda e invalido.');
        }

        $response = $this->gateway->request('POST', '/api/pos/catalogo', $payload);
        $this->ensureSuccess($response, 'Erro ao adicionar ao catalogo.');

        return ['ok' => true, 'msg' => 'Produto adicionado ao catalogo POS.', 'id' => $response->body['id'] ?? null];
    }

    public function removeCatalogItem(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Item invalido.');
        }

        $response = $this->gateway->request('DELETE', "/api/pos/catalogo/$id");
        $this->ensureSuccess($response, 'Erro ao remover do catalogo.');

        return ['ok' => true];
    }

    public function openSession(array $payload): array
    {
        if (($payload['terminal_id'] ?? 0) <= 0) {
            throw new OperationException('O terminal e obrigatorio.');
        }

        $response = $this->gateway->request('POST', '/api/pos/sessoes', $payload);
        $this->ensureSuccess($response, 'Erro ao abrir a sessao de caixa.');

        return ['ok' => true, 'msg' => 'Sessao de caixa aberta.', 'id' => $response->body['id'] ?? null];
    }

    public function closeSession(int $id, array $payload): array
    {
        if ($id <= 0) {
            throw new OperationException('Sessao invalida.');
        }

        $response = $this->gateway->request('POST', "/api/pos/sessoes/$id/fechar", $payload);
        $this->ensureSuccess($response, 'Erro ao fechar a sessao de caixa.');

        return [
            'ok' => true,
            'valor_esperado' => $response->body['valor_esperado'] ?? null,
            'diferenca' => $response->body['diferenca'] ?? null,
        ];
    }

    public function createSale(array $payload): array
    {
        if (($payload['pos_session_id'] ?? 0) <= 0) {
            throw new OperationException('A sessao de caixa e obrigatoria.');
        }
        if (empty($payload['itens'])) {
            throw new OperationException('A venda deve ter pelo menos um item.');
        }
        if (empty($payload['pagamentos'])) {
            throw new OperationException('A venda deve ter pelo menos um pagamento.');
        }
        foreach ($payload['pagamentos'] as $pagamento) {
            if (!in_array($pagamento['tipo'] ?? '', self::PAGAMENTO_TIPOS, true)) {
                throw new OperationException('Tipo de pagamento invalido.');
            }
        }

        $response = $this->gateway->request('POST', '/api/pos/sales', $payload);
        $this->ensureSuccess($response, 'Erro ao registar a venda.');

        return [
            'ok' => true,
            'id' => $response->body['id'] ?? null,
            'numero' => $response->body['numero'] ?? null,
            'total' => $response->body['total'] ?? null,
            'troco' => $response->body['troco'] ?? null,
        ];
    }

    public function cancelSale(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Venda invalida.');
        }

        $response = $this->gateway->request('POST', "/api/pos/sales/$id/cancelar");
        $this->ensureSuccess($response, 'Erro ao cancelar a venda.');

        return ['ok' => true];
    }

    public function searchProdutos(string $q, ?int $warehouseId): array
    {
        if (trim($q) === '') {
            return [];
        }

        $query = ['q' => $q];
        if ($warehouseId !== null && $warehouseId > 0) {
            $query['warehouse_id'] = $warehouseId;
        }

        $response = $this->gateway->request('GET', '/api/pos/produtos?' . http_build_query($query));
        $this->ensureSuccess($response, 'Erro ao pesquisar produtos.');

        return $response->body ?? [];
    }
}
