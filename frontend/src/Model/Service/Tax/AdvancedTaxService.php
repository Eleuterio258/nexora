<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Tax;

use E258Tech\Model\Service\OperationalModuleService;

final class AdvancedTaxService extends OperationalModuleService
{
    protected function operations(): array
    {
        return [
            'regime.create' => $this->op('POST', '/api/impostos/regimes'),
            'exemption.create' => $this->op('POST', '/api/impostos/isencoes'),
            'exemption.update' => $this->op('PUT', '/api/impostos/isencoes/{id}'),
            'exemption.delete' => $this->op('DELETE', '/api/impostos/isencoes/{id}'),
            'withholding.create' => $this->op('POST', '/api/impostos/retencoes'),
            'return.create' => $this->op('POST', '/api/impostos/declaracoes'),
            'return.submit' => $this->op('POST', '/api/impostos/declaracoes/{id}/submeter'),
            'certificate.create' => $this->op('POST', '/api/impostos/certificados'),
        ];
    }

    private function op(string $method, string $path): array
    {
        return ['method' => $method, 'path' => $path];
    }
}
