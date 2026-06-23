<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Logistica;

use E258Tech\Model\Service\OperationalModuleService;

final class LogisticaService extends OperationalModuleService
{
    protected function operations(): array
    {
        return [
            'motorista.create'  => $this->op('POST', '/api/delivery-drivers'),
            'viatura.create'    => $this->op('POST', '/api/delivery-vehicles'),
            'rota.create'       => $this->op('POST', '/api/delivery-routes'),
            'estado.create'     => $this->op('POST', '/api/delivery-status'),
            'envio.create'      => $this->op('POST', '/api/shipments'),
            'envio.item'        => $this->op('POST', '/api/shipment-items'),
            'tracking.create'   => $this->op('POST', '/api/delivery-tracking'),
        ];
    }

    private function op(string $method, string $path): array
    {
        return ['method' => $method, 'path' => $path];
    }
}
