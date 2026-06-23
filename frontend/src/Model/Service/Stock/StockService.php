<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Stock;

use E258Tech\Model\Service\OperationalModuleService;

final class StockService extends OperationalModuleService
{
    protected function operations(): array
    {
        return [
            'warehouse.create' => $this->op('POST', '/api/stock/warehouses'),
            'warehouse.update' => $this->op('PUT', '/api/stock/warehouses/{id}'),
            'warehouse.activate' => $this->op('POST', '/api/stock/warehouses/{id}/activar'),
            'warehouse.deactivate' => $this->op('POST', '/api/stock/warehouses/{id}/desactivar'),
            'location.create' => $this->op('POST', '/api/stock/warehouses/{warehouse_id}/locations'),
            'location.update' => $this->op('PUT', '/api/stock/warehouses/{warehouse_id}/locations/{id}'),
            'location.delete' => $this->op('DELETE', '/api/stock/warehouses/{warehouse_id}/locations/{id}'),
            'item.create' => $this->op('POST', '/api/stock/items'),
            'item.minimum' => $this->op('PUT', '/api/stock/items/{id}/minimos'),
            'movement.create' => $this->op('POST', '/api/stock/movements'),
            'adjustment.create' => $this->op('POST', '/api/stock/adjustments'),
            'transfer.create' => $this->op('POST', '/api/stock/transfers'),
            'transfer.confirm' => $this->op('POST', '/api/stock/transfers/{id}/confirmar'),
            'transfer.receive' => $this->op('POST', '/api/stock/transfers/{id}/receber'),
            'transfer.cancel' => $this->op('POST', '/api/stock/transfers/{id}/cancelar'),
            'reservation.create' => $this->op('POST', '/api/stock/reservations'),
            'reservation.release' => $this->op('POST', '/api/stock/reservations/{id}/liberar'),
            'reservation.consume' => $this->op('POST', '/api/stock/reservations/{id}/consumir'),
            'batch.create' => $this->op('POST', '/api/stock/batches'),
            'batch.update' => $this->op('PUT', '/api/stock/batches/{id}'),
            'serial.create' => $this->op('POST', '/api/stock/serials'),
            'serial.status' => $this->op('PUT', '/api/stock/serials/{id}/status'),
            'count.create' => $this->op('POST', '/api/stock/counts'),
            'count.item.create' => $this->op('POST', '/api/stock/counts/{id}/items'),
            'count.item.update' => $this->op('PUT', '/api/stock/counts/{count_id}/items/{id}'),
            'count.close' => $this->op('POST', '/api/stock/counts/{id}/fechar'),
            'count.cancel' => $this->op('POST', '/api/stock/counts/{id}/cancelar'),
            'alert.resolve' => $this->op('POST', '/api/stock/alerts/{id}/resolver'),
            'alert.ignore' => $this->op('POST', '/api/stock/alerts/{id}/ignorar'),
        ];
    }

    private function op(string $method, string $path): array
    {
        return ['method' => $method, 'path' => $path];
    }
}
