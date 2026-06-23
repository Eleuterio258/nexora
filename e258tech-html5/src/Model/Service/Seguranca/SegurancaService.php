<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Seguranca;

use E258Tech\Model\Service\OperationalModuleService;

final class SegurancaService extends OperationalModuleService
{
    protected function operations(): array
    {
        return [
            'politica.create' => $this->op('POST',   '/api/seguranca/politicas'),
            'politica.update' => $this->op('PUT',    '/api/seguranca/politicas/{id}'),
            'ip.add'          => $this->op('POST',   '/api/seguranca/ip-allowlist'),
            'ip.remove'       => $this->op('DELETE', '/api/seguranca/ip-allowlist/{id}'),
        ];
    }

    private function op(string $method, string $path): array
    {
        return ['method' => $method, 'path' => $path];
    }
}
