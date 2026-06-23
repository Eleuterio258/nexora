<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\MultiMoeda;

use E258Tech\Model\Service\OperationalModuleService;

final class MultiMoedaService extends OperationalModuleService
{
    protected function operations(): array
    {
        return [
            'moeda.create'  => $this->op('POST',   '/api/multi-moeda/moedas'),
            'taxa.create'   => $this->op('POST',   '/api/multi-moeda/taxas-cambio'),
            'tenant.add'    => $this->op('POST',   '/api/multi-moeda/tenant-moedas'),
            'tenant.remove' => $this->op('DELETE', '/api/multi-moeda/tenant-moedas/{id}'),
            'converter'     => $this->op('POST',   '/api/multi-moeda/converter'),
        ];
    }

    private function op(string $method, string $path): array
    {
        return ['method' => $method, 'path' => $path];
    }
}
