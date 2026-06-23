<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Purchase;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

final class PurchaseService extends NexoraService
{
    private const DOCUMENT_PATHS = [
        'request' => '/api/purchase-requests',
        'order' => '/api/purchase-orders',
        'receipt' => '/api/purchase-receipts',
        'return' => '/api/purchase-returns',
        'invoice' => '/api/purchase-invoices',
        'payment' => '/api/purchase-payments',
    ];

    private const ITEM_PATHS = [
        'request' => '/api/purchase-request-items',
        'order' => '/api/purchase-order-items',
        'receipt' => '/api/purchase-receipt-items',
        'return' => '/api/purchase-return-items',
        'invoice' => '/api/purchase-invoice-items',
        'payment' => '/api/purchase-payment-items',
    ];

    public function list(string $type, array $filters = []): array
    {
        $path = $this->path(self::DOCUMENT_PATHS, $type);
        $filters = array_filter($filters, static fn(mixed $value): bool => $value !== null && $value !== '');
        if ($filters) {
            $path .= '?' . http_build_query($filters);
        }
        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter documentos de compras.');
        return $response->body ?? [];
    }

    public function createDocument(string $type, array $payload): array
    {
        $path = $this->path(self::DOCUMENT_PATHS, $type);
        if (($payload['numero'] ?? '') === '') {
            throw new OperationException('O numero do documento e obrigatorio.');
        }

        $response = $this->gateway->request('POST', $path, $payload);
        $this->ensureSuccess($response, 'Erro ao criar o documento de compras.');

        return [
            'ok' => true,
            'msg' => 'Documento criado com sucesso.',
            'id' => $response->body['id'] ?? null,
        ];
    }

    public function addItem(string $type, array $payload): array
    {
        $path = $this->path(self::ITEM_PATHS, $type);
        $response = $this->gateway->request('POST', $path, $payload);
        $this->ensureSuccess($response, 'Erro ao adicionar o item.');

        return [
            'ok' => true,
            'msg' => 'Item adicionado com sucesso.',
            'id' => $response->body['id'] ?? null,
        ];
    }

    private function path(array $paths, string $type): string
    {
        if (!isset($paths[$type])) {
            throw new OperationException('Tipo de documento de compras invalido.');
        }
        return $paths[$type];
    }

    public function __construct(private readonly NexoraGateway $gateway)
    {
    }
}
