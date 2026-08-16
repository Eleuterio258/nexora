<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Infrastructure\Repository;

use DateTimeImmutable;
use E258Tech\Faturacao\Domain\Entity\Document;
use E258Tech\Faturacao\Domain\Entity\DocumentLine;
use E258Tech\Faturacao\Domain\Repository\DocumentRepositoryInterface;
use E258Tech\Faturacao\Domain\ValueObject\DocumentNumber;
use E258Tech\Faturacao\Domain\ValueObject\DocumentStatus;
use E258Tech\Faturacao\Domain\ValueObject\DocumentType;
use E258Tech\Faturacao\Domain\ValueObject\Money;
use E258Tech\Faturacao\Domain\ValueObject\TaxRate;
use E258Tech\Faturacao\Infrastructure\Http\ApiClient;
use RuntimeException;

/**
 * Junta três recursos separados do backend (quotes, invoices, credit-notes)
 * na abstração unificada "Document" que o resto do phc já conhece — o
 * backend não tem o conceito de "documento genérico", tem orçamento, fatura
 * e nota de crédito como entidades distintas com esquemas próprios.
 *
 * O id do Document interface é um único int; para não colidir entre
 * recursos (uma fatura #5 e uma nota de crédito #5 são registos
 * diferentes), o id exposto ao resto do phc é `id_no_backend * 10 +
 * código_do_recurso` (1=quote, 2=invoice, 3=credit-note) e descodificado
 * em findById().
 *
 * Só leitura: a criação de documentos continua no fluxo local (JSON) até
 * o CreateDocumentUseCase ser reescrito para o protocolo multi-passo do
 * backend (criar rascunho → adicionar itens → emitir).
 */
final class HttpDocumentRepository implements DocumentRepositoryInterface
{
    private const RESOURCE_QUOTE = 1;
    private const RESOURCE_INVOICE = 2;
    private const RESOURCE_CREDIT_NOTE = 3;

    public function __construct(private ApiClient $client)
    {
    }

    public function findAll(): array
    {
        $documents = [];

        foreach ($this->client->get('/api/faturacao/quotes', ['limit' => 200]) as $key => $value) {
            if ($key !== 'data') {
                continue;
            }
            foreach ((array) $value as $row) {
                $documents[] = $this->mapQuoteRow((array) $row);
            }
        }

        $invoicesResponse = $this->client->get('/api/faturacao/invoices', ['limit' => 200]);
        foreach ((array) ($invoicesResponse['data'] ?? []) as $row) {
            $documents[] = $this->mapInvoiceRow((array) $row);
        }

        foreach ($this->client->get('/api/faturacao/credit-notes', ['limit' => 200]) as $key => $value) {
            if ($key !== 'data') {
                continue;
            }
            foreach ((array) $value as $row) {
                $documents[] = $this->mapCreditNoteRow((array) $row);
            }
        }

        return $documents;
    }

    public function findById(int $id): ?Document
    {
        $resource = $id % 10;
        $backendId = intdiv($id, 10);

        try {
            return match ($resource) {
                self::RESOURCE_QUOTE => $this->fetchQuote($backendId),
                self::RESOURCE_INVOICE => $this->fetchInvoice($backendId),
                self::RESOURCE_CREDIT_NOTE => $this->fetchCreditNote($backendId),
                default => null,
            };
        } catch (\E258Tech\Faturacao\Infrastructure\Http\ApiException $e) {
            return null;
        }
    }

    public function findByStatus(DocumentStatus $status): array
    {
        return array_values(array_filter(
            $this->findAll(),
            fn(Document $document) => $document->status()->equals($status)
        ));
    }

    public function save(Document $document): void
    {
        throw new RuntimeException(
            'HttpDocumentRepository é só de leitura — a criação de documentos ainda usa o fluxo local (JSON).'
        );
    }

    public function nextId(): int
    {
        throw new RuntimeException(
            'HttpDocumentRepository é só de leitura — não gera identificadores locais.'
        );
    }

    // ── Orçamentos ───────────────────────────────────────────────────────

    private function mapQuoteRow(array $row): Document
    {
        $total = Money::fromFloat((float) ($row['total'] ?? 0));
        $date = $this->parseDate($row['created_at'] ?? null) ?? new DateTimeImmutable();
        $dueDate = $this->parseDate($row['validade'] ?? null) ?? $date;

        return new Document(
            ((int) $row['id']) * 10 + self::RESOURCE_QUOTE,
            DocumentNumber::fromRaw(new DocumentType('ORC'), (string) ($row['numero'] ?? '')),
            (int) $row['customer_id'],
            $date,
            $dueDate,
            $total,
            new Money(0),
            new Money(0),
            $total,
            $this->mapQuoteStatus((string) ($row['status'] ?? '')),
            []
        );
    }

    private function fetchQuote(int $backendId): Document
    {
        $response = $this->client->get('/api/faturacao/quotes/' . $backendId);
        $header = $response['orcamento'] ?? [];
        $items = $response['itens'] ?? [];

        $total = Money::fromFloat((float) ($header['total'] ?? 0));
        $tax = Money::fromFloat((float) ($header['imposto_total'] ?? 0));
        $date = $this->parseDate($header['created_at'] ?? null) ?? new DateTimeImmutable();
        $dueDate = $this->parseDate($header['validade'] ?? null) ?? $date;

        return new Document(
            $backendId * 10 + self::RESOURCE_QUOTE,
            DocumentNumber::fromRaw(new DocumentType('ORC'), (string) ($header['numero'] ?? '')),
            (int) ($header['customer_id'] ?? 0),
            $date,
            $dueDate,
            $total->subtract($tax),
            new Money(0),
            $tax,
            $total,
            $this->mapQuoteStatus((string) ($header['status'] ?? '')),
            $this->mapItems($items, hasDiscount: true),
            (string) ($header['observacoes'] ?? '')
        );
    }

    private function mapQuoteStatus(string $status): DocumentStatus
    {
        return new DocumentStatus(match ($status) {
            'enviado', 'aprovado' => 'pending',
            'rejeitado' => 'cancelled',
            'convertido' => 'paid',
            'expirado' => 'overdue',
            default => 'draft',
        });
    }

    // ── Faturas ──────────────────────────────────────────────────────────

    private function mapInvoiceRow(array $row): Document
    {
        $total = Money::fromFloat((float) ($row['total'] ?? 0));
        $tax = Money::fromFloat((float) ($row['imposto_total'] ?? 0));
        $date = $this->parseDate($row['invoice_date'] ?? null) ?? new DateTimeImmutable();
        $dueDate = $this->parseDate($row['due_date'] ?? null) ?? $date;

        return new Document(
            ((int) $row['id']) * 10 + self::RESOURCE_INVOICE,
            DocumentNumber::fromRaw($this->invoiceType((string) ($row['tipo'] ?? 'normal')), (string) ($row['numero'] ?? '')),
            (int) $row['customer_id'],
            $date,
            $dueDate,
            $total->subtract($tax),
            new Money(0),
            $tax,
            $total,
            $this->mapInvoiceStatus((string) ($row['status'] ?? '')),
            []
        );
    }

    private function fetchInvoice(int $backendId): Document
    {
        $response = $this->client->get('/api/faturacao/invoices/' . $backendId);
        $header = $response['fatura'] ?? [];
        $items = $response['itens'] ?? [];

        $total = Money::fromFloat((float) ($header['total'] ?? 0));
        $tax = Money::fromFloat((float) ($header['imposto_total'] ?? 0));
        $date = $this->parseDate($header['invoice_date'] ?? null) ?? new DateTimeImmutable();
        $dueDate = $this->parseDate($header['due_date'] ?? null) ?? $date;

        return new Document(
            $backendId * 10 + self::RESOURCE_INVOICE,
            DocumentNumber::fromRaw($this->invoiceType((string) ($header['tipo'] ?? 'normal')), (string) ($header['numero'] ?? '')),
            (int) ($header['customer_id'] ?? 0),
            $date,
            $dueDate,
            $total->subtract($tax),
            new Money(0),
            $tax,
            $total,
            $this->mapInvoiceStatus((string) ($header['status'] ?? '')),
            $this->mapItems($items, hasDiscount: true),
            (string) ($header['observacoes'] ?? '')
        );
    }

    private function invoiceType(string $tipo): DocumentType
    {
        return new DocumentType(match ($tipo) {
            'proforma' => 'PP',
            'FR' => 'FR',
            'VD' => 'VD',
            default => 'FT',
        });
    }

    private function mapInvoiceStatus(string $status): DocumentStatus
    {
        return new DocumentStatus(match ($status) {
            'emitida', 'parcialmente_paga' => 'pending',
            'paga' => 'paid',
            'cancelada' => 'cancelled',
            'vencida' => 'overdue',
            default => 'draft',
        });
    }

    // ── Notas de crédito ─────────────────────────────────────────────────

    private function mapCreditNoteRow(array $row): Document
    {
        $total = Money::fromFloat((float) ($row['total'] ?? 0));
        $date = $this->parseDate($row['created_at'] ?? null) ?? new DateTimeImmutable();

        return new Document(
            ((int) $row['id']) * 10 + self::RESOURCE_CREDIT_NOTE,
            DocumentNumber::fromRaw(new DocumentType('NC'), (string) ($row['numero'] ?? '')),
            (int) $row['customer_id'],
            $date,
            $date,
            $total,
            new Money(0),
            new Money(0),
            $total,
            $this->mapCreditNoteStatus((string) ($row['status'] ?? '')),
            []
        );
    }

    private function fetchCreditNote(int $backendId): Document
    {
        $response = $this->client->get('/api/faturacao/credit-notes/' . $backendId);
        $header = $response['nota_credito'] ?? [];
        $items = $response['itens'] ?? [];

        $subtotal = Money::fromFloat((float) ($header['subtotal'] ?? 0));
        $tax = Money::fromFloat((float) ($header['imposto_total'] ?? 0));
        $total = Money::fromFloat((float) ($header['total'] ?? 0));
        $date = $this->parseDate($header['credit_date'] ?? null) ?? new DateTimeImmutable();

        return new Document(
            $backendId * 10 + self::RESOURCE_CREDIT_NOTE,
            DocumentNumber::fromRaw(new DocumentType('NC'), (string) ($header['numero'] ?? '')),
            (int) ($header['customer_id'] ?? 0),
            $date,
            $date,
            $subtotal,
            new Money(0),
            $tax,
            $total,
            $this->mapCreditNoteStatus((string) ($header['status'] ?? '')),
            $this->mapItems($items, hasDiscount: false),
            (string) ($header['observacoes'] ?? ''),
            (string) ($header['motivo'] ?? '')
        );
    }

    private function mapCreditNoteStatus(string $status): DocumentStatus
    {
        return new DocumentStatus(match ($status) {
            'emitida' => 'pending',
            'paga' => 'paid',
            'cancelada' => 'cancelled',
            default => 'draft',
        });
    }

    // ── Auxiliares partilhados ───────────────────────────────────────────

    /**
     * @param array<int, array<string, mixed>> $items
     * @return DocumentLine[]
     */
    private function mapItems(array $items, bool $hasDiscount): array
    {
        return array_map(function (array $item) use ($hasDiscount) {
            return new DocumentLine(
                isset($item['product_id']) && $item['product_id'] !== null ? (int) $item['product_id'] : null,
                (string) ($item['descricao'] ?? ''),
                (float) ($item['quantidade'] ?? 1),
                Money::fromFloat((float) ($item['preco_unitario'] ?? 0)),
                $hasDiscount ? (float) ($item['desconto_percent'] ?? 0) : 0.0,
                TaxRate::fromFloat((float) ($item['imposto_percent'] ?? 0))
            );
        }, $items);
    }

    private function parseDate(mixed $value): ?DateTimeImmutable
    {
        if (!is_string($value) || $value === '') {
            return null;
        }
        try {
            return new DateTimeImmutable($value);
        } catch (\Exception) {
            return null;
        }
    }
}
