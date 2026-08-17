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

        // O backend exige um activation_code e nunca o gera: é a password da
        // conta do terminal, guardada em bcrypt. Sem ele o pedido era recusado
        // com 400 e nenhum terminal podia ser criado pelo ERP.
        $activationCode = trim((string) ($payload['activation_code'] ?? ''));
        if ($activationCode === '') {
            $activationCode = self::gerarCodigoActivacao();
        }
        $payload['activation_code'] = $activationCode;

        $response = $this->gateway->request('POST', '/api/pos/terminais', $payload);
        $this->ensureSuccess($response, 'Erro ao criar o terminal.');

        return [
            'ok' => true,
            'msg' => 'Terminal criado com sucesso.',
            'id' => $response->body['id'] ?? null,
            // Devolvido para ser mostrado uma única vez: a partir daqui só
            // existe como hash no servidor e não há como o recuperar.
            'activation_code' => $activationCode,
        ];
    }

    /**
     * Código de activação legível: três grupos de quatro, sem caracteres que
     * se confundam a ler de um papel (0/O, 1/I). Autentica o terminal durante
     * 30 dias, por isso não são quatro dígitos.
     */
    private static function gerarCodigoActivacao(): string
    {
        $alfabeto = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        $grupos = [];

        for ($g = 0; $g < 3; $g++) {
            $grupo = '';
            for ($i = 0; $i < 4; $i++) {
                $grupo .= $alfabeto[random_int(0, strlen($alfabeto) - 1)];
            }
            $grupos[] = $grupo;
        }

        return implode('-', $grupos);
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

    public function cancelSale(int $id, string $reason = ''): array
    {
        if ($id <= 0) {
            throw new OperationException('Venda invalida.');
        }

        $payload = [];
        if ($reason !== '') {
            $payload['reason'] = $reason;
        }

        $response = $this->gateway->request('POST', "/api/pos/sales/$id/cancelar", $payload);
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

    // ── Terminais ───────────────────────────────────────────────────────────

    public function listTerminais(array $filters = []): array
    {
        $query = http_build_query($filters);
        $response = $this->gateway->request('GET', '/api/pos/terminais' . ($query ? '?' . $query : ''));
        $this->ensureSuccess($response, 'Erro ao listar terminais.');
        return $response->body ?? [];
    }

    public function getTerminal(int $id): array
    {
        $response = $this->gateway->request('GET', "/api/pos/terminais/$id");
        $this->ensureSuccess($response, 'Erro ao obter terminal.');
        return $response->body ?? [];
    }

    public function updateTerminal(int $id, array $payload): array
    {
        if (trim((string) ($payload['nome'] ?? '')) === '') {
            throw new OperationException('O nome do terminal e obrigatorio.');
        }

        $response = $this->gateway->request('PUT', "/api/pos/terminais/$id", $payload);
        $this->ensureSuccess($response, 'Erro ao actualizar o terminal.');

        return ['ok' => true];
    }

    public function deleteTerminal(int $id): array
    {
        $response = $this->gateway->request('DELETE', "/api/pos/terminais/$id");
        $this->ensureSuccess($response, 'Erro ao remover o terminal.');

        return ['ok' => true];
    }

    public function toggleTerminal(int $id, bool $active): array
    {
        $action = $active ? 'activar' : 'desactivar';
        $response = $this->gateway->request('POST', "/api/pos/terminais/$id/$action");
        $this->ensureSuccess($response, 'Erro ao alterar estado do terminal.');

        return ['ok' => true];
    }

    // ── Sessões ─────────────────────────────────────────────────────────────

    public function listSessoes(array $filters = []): array
    {
        $query = http_build_query($filters);
        $response = $this->gateway->request('GET', '/api/pos/sessoes' . ($query ? '?' . $query : ''));
        $this->ensureSuccess($response, 'Erro ao listar sessoes.');
        return $response->body ?? [];
    }

    public function getSessao(int $id): array
    {
        $response = $this->gateway->request('GET', "/api/pos/sessoes/$id");
        $this->ensureSuccess($response, 'Erro ao obter sessao.');
        return $response->body ?? [];
    }

    public function getSessaoAtual(): array
    {
        $response = $this->gateway->request('GET', '/api/pos/sessoes/atual');
        $this->ensureSuccess($response, 'Erro ao obter sessao actual.');
        return $response->body ?? [];
    }

    public function getFechoSessao(int $id): array
    {
        $response = $this->gateway->request('GET', "/api/pos/sessoes/$id/fecho");
        $this->ensureSuccess($response, 'Erro ao obter fecho de caixa.');
        return $response->body ?? [];
    }

    // ── Vendas ──────────────────────────────────────────────────────────────

    public function listVendas(array $filters = []): array
    {
        $query = http_build_query($filters);
        $response = $this->gateway->request('GET', '/api/pos/sales' . ($query ? '?' . $query : ''));
        $this->ensureSuccess($response, 'Erro ao listar vendas.');
        return $response->body ?? [];
    }

    public function getVenda(int $id): array
    {
        $response = $this->gateway->request('GET', "/api/pos/sales/$id");
        $this->ensureSuccess($response, 'Erro ao obter venda.');
        return $response->body ?? [];
    }



    public function getRecibo(int $id): array
    {
        $response = $this->gateway->request('GET', "/api/pos/sales/$id/recibo");
        $this->ensureSuccess($response, 'Erro ao obter recibo.');
        return $response->body ?? [];
    }

    // ── Catálogo POS ────────────────────────────────────────────────────────

    public function listCatalogo(): array
    {
        $response = $this->gateway->request('GET', '/api/pos/catalogo');
        $this->ensureSuccess($response, 'Erro ao listar catálogo POS.');
        return $response->body ?? [];
    }

    // ── Descontos POS ───────────────────────────────────────────────────────

    public function listDescontos(): array
    {
        $response = $this->gateway->request('GET', '/api/pos/descontos');
        $this->ensureSuccess($response, 'Erro ao listar descontos.');
        return $response->body ?? [];
    }

    public function createDesconto(array $payload): array
    {
        if (trim((string) ($payload['nome'] ?? '')) === '') {
            throw new OperationException('O nome do desconto é obrigatório.');
        }
        if (($payload['valor'] ?? -1) < 0) {
            throw new OperationException('O valor do desconto é inválido.');
        }

        $response = $this->gateway->request('POST', '/api/pos/descontos', $payload);
        $this->ensureSuccess($response, 'Erro ao criar desconto.');

        return ['ok' => true, 'id' => $response->body['id'] ?? null];
    }

    public function updateDesconto(int $id, array $payload): array
    {
        if ($id <= 0) {
            throw new OperationException('Desconto inválido.');
        }

        $response = $this->gateway->request('PUT', "/api/pos/descontos/$id", $payload);
        $this->ensureSuccess($response, 'Erro ao actualizar desconto.');

        return ['ok' => true];
    }

    public function deleteDesconto(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Desconto inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/pos/descontos/$id");
        $this->ensureSuccess($response, 'Erro ao remover desconto.');

        return ['ok' => true];
    }

    // ── Configuração POS ────────────────────────────────────────────────────

    public function getConfiguracao(): array
    {
        $response = $this->gateway->request('GET', '/api/pos/configuracao');
        $this->ensureSuccess($response, 'Erro ao obter configuração POS.');
        return $response->body ?? [];
    }

    public function saveConfiguracao(array $payload): array
    {
        $iva = (float) ($payload['iva_padrao'] ?? 17);
        if ($iva < 0 || $iva > 100) {
            throw new OperationException('IVA padrão inválido.');
        }

        $response = $this->gateway->request('PUT', '/api/pos/configuracao', $payload);
        $this->ensureSuccess($response, 'Erro ao guardar configuração POS.');

        return ['ok' => true];
    }
}
