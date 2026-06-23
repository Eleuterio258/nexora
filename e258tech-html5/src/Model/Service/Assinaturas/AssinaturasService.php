<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Assinaturas;

use E258Tech\Model\Service\OperationalModuleService;

final class AssinaturasService extends OperationalModuleService
{
    protected function operations(): array
    {
        return [
            'plano.create'       => $this->op('POST', '/api/assinaturas/planos'),
            'plano.update'       => $this->op('PUT',  '/api/assinaturas/planos/{id}'),
            'assinatura.create'  => $this->op('POST', '/api/assinaturas/subscriptions'),
            'assinatura.cancelar' => $this->op('POST', '/api/assinaturas/subscriptions/{id}/cancelar'),
            'assinatura.renovar' => $this->op('POST', '/api/assinaturas/subscriptions/{id}/renovar'),
        ];
    }

    private function op(string $method, string $path): array
    {
        return ['method' => $method, 'path' => $path];
    }
}
