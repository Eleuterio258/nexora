<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Aprovacao;

use E258Tech\Model\Service\OperationalModuleService;

final class AprovacaoService extends OperationalModuleService
{
    protected function operations(): array
    {
        return [
            'flows.listar'       => ['method' => 'GET',    'path' => '/api/aprovacoes/flows'],
            'flows.criar'        => ['method' => 'POST',   'path' => '/api/aprovacoes/flows'],
            'flows.obter'        => ['method' => 'GET',    'path' => '/api/aprovacoes/flows/{id}'],
            'flows.save'         => ['method' => 'PUT',    'path' => '/api/aprovacoes/flows/{id}'],
            'flows.delete'       => ['method' => 'DELETE', 'path' => '/api/aprovacoes/flows/{id}'],
            'requests.listar'    => ['method' => 'GET',    'path' => '/api/aprovacoes/requests'],
            'requests.pendentes' => ['method' => 'GET',    'path' => '/api/aprovacoes/requests/pendentes-meu-cargo'],
            'requests.obter'     => ['method' => 'GET',    'path' => '/api/aprovacoes/requests/{id}'],
            'requests.decidir'   => ['method' => 'POST',   'path' => '/api/aprovacoes/requests/{id}/decidir'],
            'requests.cancelar'  => ['method' => 'POST',   'path' => '/api/aprovacoes/requests/{id}/cancelar'],
        ];
    }
}
