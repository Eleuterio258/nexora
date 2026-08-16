<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Faturacao;

use E258Tech\Model\Service\NexoraService;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Contract\NexoraGateway;

final class FaturacaoService extends NexoraService
{
    private const SERIES_TYPES = ['ORC', 'ENC', 'FT', 'FR', 'VD', 'NC', 'RB'];
    private const INVOICE_TYPES = ['normal', 'FR', 'VD', 'proforma'];
    private const QUOTE_ACTIONS = ['enviar', 'aprovar', 'rejeitar'];
    private const ORDER_ACTIONS = ['confirmar', 'cancelar'];
    private const INVOICE_ACTIONS = ['emitir', 'cancelar'];
    private const CREDIT_NOTE_ACTIONS = ['emitir', 'cancelar'];

    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    // ── Series ───────────────────────────────────────────────────────────

    public function createSeries(array $payload): array
    {
        if (!in_array($payload['tipo'] ?? '', self::SERIES_TYPES, true)) {
            throw new OperationException('O tipo de serie e invalido.');
        }
        if (($payload['prefixo'] ?? '') === '') {
            throw new OperationException('O prefixo e obrigatorio.');
        }

        $response = $this->gateway->request('POST', '/api/faturacao/series', $payload);
        $this->ensureSuccess($response, 'Erro ao criar a serie.');

        return ['ok' => true, 'msg' => 'Serie criada com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function setSeriesActive(int $id, bool $ativo): array
    {
        if ($id <= 0) {
            throw new OperationException('Serie invalida.');
        }

        $action = $ativo ? 'activar' : 'desactivar';
        $response = $this->gateway->request('POST', "/api/faturacao/series/$id/$action");
        $this->ensureSuccess($response, 'Erro ao actualizar o estado da serie.');

        return ['ok' => true];
    }

    // ── Orçamentos ───────────────────────────────────────────────────────

    public function createQuote(array $payload): array
    {
        if (($payload['customer_id'] ?? 0) <= 0) {
            throw new OperationException('O cliente e obrigatorio.');
        }

        $response = $this->gateway->request('POST', '/api/faturacao/quotes', $payload);
        $this->ensureSuccess($response, 'Erro ao criar o orcamento.');

        return [
            'ok' => true,
            'msg' => 'Orcamento criado com sucesso.',
            'id' => $response->body['id'] ?? null,
            'numero' => $response->body['numero'] ?? null,
        ];
    }

    public function addQuoteItem(int $quoteId, array $payload): array
    {
        if ($quoteId <= 0) {
            throw new OperationException('Orcamento invalido.');
        }
        $this->ensureLineIsValid($payload);

        $response = $this->gateway->request('POST', "/api/faturacao/quotes/$quoteId/items", $payload);
        $this->ensureSuccess($response, 'Erro ao adicionar o item.');

        return ['ok' => true, 'msg' => 'Item adicionado com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function removeQuoteItem(int $quoteId, int $itemId): array
    {
        if ($quoteId <= 0 || $itemId <= 0) {
            throw new OperationException('Dados invalidos.');
        }

        $response = $this->gateway->request('DELETE', "/api/faturacao/quotes/$quoteId/items/$itemId");
        $this->ensureSuccess($response, 'Erro ao eliminar o item.');

        return ['ok' => true];
    }

    public function setQuoteStatus(int $id, string $action): array
    {
        if ($id <= 0 || !in_array($action, self::QUOTE_ACTIONS, true)) {
            throw new OperationException('Dados invalidos.');
        }

        $response = $this->gateway->request('POST', "/api/faturacao/quotes/$id/$action");
        $this->ensureSuccess($response, 'Erro ao actualizar o estado do orcamento.');

        return ['ok' => true];
    }

    // ── Encomendas ───────────────────────────────────────────────────────

    public function createOrder(array $payload): array
    {
        if (($payload['customer_id'] ?? 0) <= 0) {
            throw new OperationException('O cliente e obrigatorio.');
        }

        $response = $this->gateway->request('POST', '/api/faturacao/orders', $payload);
        $this->ensureSuccess($response, 'Erro ao criar a encomenda.');

        return [
            'ok' => true,
            'msg' => 'Encomenda criada com sucesso.',
            'id' => $response->body['id'] ?? null,
            'numero' => $response->body['numero'] ?? null,
        ];
    }

    public function setOrderStatus(int $id, string $action): array
    {
        if ($id <= 0 || !in_array($action, self::ORDER_ACTIONS, true)) {
            throw new OperationException('Dados invalidos.');
        }

        $response = $this->gateway->request('POST', "/api/faturacao/orders/$id/$action");
        $this->ensureSuccess($response, 'Erro ao actualizar o estado da encomenda.');

        return ['ok' => true];
    }

    // ── Faturas ──────────────────────────────────────────────────────────

    public function createInvoice(array $payload): array
    {
        if (($payload['customer_id'] ?? 0) <= 0) {
            throw new OperationException('O cliente e obrigatorio.');
        }
        if (!in_array($payload['tipo'] ?? 'normal', self::INVOICE_TYPES, true)) {
            throw new OperationException('O tipo de fatura e invalido.');
        }

        $response = $this->gateway->request('POST', '/api/faturacao/invoices', $payload);
        $this->ensureSuccess($response, 'Erro ao criar a fatura.');

        return [
            'ok' => true,
            'msg' => 'Fatura criada com sucesso.',
            'id' => $response->body['id'] ?? null,
            'numero' => $response->body['numero'] ?? null,
        ];
    }

    public function addInvoiceItem(int $invoiceId, array $payload): array
    {
        if ($invoiceId <= 0) {
            throw new OperationException('Fatura invalida.');
        }
        $this->ensureLineIsValid($payload);

        $response = $this->gateway->request('POST', "/api/faturacao/invoices/$invoiceId/items", $payload);
        $this->ensureSuccess($response, 'Erro ao adicionar o item.');

        return ['ok' => true, 'msg' => 'Item adicionado com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function setInvoiceStatus(int $id, string $action): array
    {
        if ($id <= 0 || !in_array($action, self::INVOICE_ACTIONS, true)) {
            throw new OperationException('Dados invalidos.');
        }

        $response = $this->gateway->request('POST', "/api/faturacao/invoices/$id/$action");
        $this->ensureSuccess($response, 'Erro ao actualizar o estado da fatura.');

        return ['ok' => true];
    }

    // ── Recibos ──────────────────────────────────────────────────────────

    public function createReceipt(array $payload): array
    {
        if (($payload['invoice_id'] ?? 0) <= 0) {
            throw new OperationException('A fatura e obrigatoria.');
        }
        if (($payload['valor'] ?? 0) <= 0) {
            throw new OperationException('O valor deve ser superior a zero.');
        }

        $response = $this->gateway->request('POST', '/api/faturacao/receipts', $payload);
        $this->ensureSuccess($response, 'Erro ao registar o recibo.');

        return [
            'ok' => true,
            'msg' => 'Recibo registado com sucesso.',
            'id' => $response->body['id'] ?? null,
            'numero' => $response->body['numero'] ?? null,
        ];
    }

    // ── Notas de crédito ─────────────────────────────────────────────────

    public function createCreditNote(array $payload): array
    {
        if (($payload['customer_id'] ?? 0) <= 0) {
            throw new OperationException('O cliente e obrigatorio.');
        }
        if (($payload['motivo'] ?? '') === '') {
            throw new OperationException('O motivo e obrigatorio.');
        }

        $response = $this->gateway->request('POST', '/api/faturacao/credit-notes', $payload);
        $this->ensureSuccess($response, 'Erro ao criar a nota de credito.');

        return [
            'ok' => true,
            'msg' => 'Nota de credito criada com sucesso.',
            'id' => $response->body['id'] ?? null,
            'numero' => $response->body['numero'] ?? null,
        ];
    }

    public function addCreditNoteItem(int $creditNoteId, array $payload): array
    {
        if ($creditNoteId <= 0) {
            throw new OperationException('Nota de credito invalida.');
        }
        $this->ensureLineIsValid($payload);

        $response = $this->gateway->request('POST', "/api/faturacao/credit-notes/$creditNoteId/items", $payload);
        $this->ensureSuccess($response, 'Erro ao adicionar o item.');

        return ['ok' => true, 'msg' => 'Item adicionado com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function setCreditNoteStatus(int $id, string $action): array
    {
        if ($id <= 0 || !in_array($action, self::CREDIT_NOTE_ACTIONS, true)) {
            throw new OperationException('Dados invalidos.');
        }

        $response = $this->gateway->request('POST', "/api/faturacao/credit-notes/$id/$action");
        $this->ensureSuccess($response, 'Erro ao actualizar o estado da nota de credito.');

        return ['ok' => true];
    }

    private function ensureLineIsValid(array $payload): void
    {
        if (($payload['quantidade'] ?? 0) <= 0) {
            throw new OperationException('A quantidade deve ser superior a zero.');
        }
        if (($payload['preco_unitario'] ?? 0) <= 0) {
            throw new OperationException('O preco unitario deve ser superior a zero.');
        }
    }
}
