<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Notificacoes;

use E258Tech\Model\Service\OperationalModuleService;

final class NotificacoesService extends OperationalModuleService
{
    protected function operations(): array
    {
        return [
            'canal.create'      => $this->op('POST', '/api/notificacoes/canais'),
            'template.create'   => $this->op('POST', '/api/notificacoes/templates'),
            'template.update'   => $this->op('PUT',  '/api/notificacoes/templates/{id}'),
            'mensagem.send'     => $this->op('POST', '/api/notificacoes/mensagens'),
        ];
    }

    private function op(string $method, string $path): array
    {
        return ['method' => $method, 'path' => $path];
    }
}
