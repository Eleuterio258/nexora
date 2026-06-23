<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Tesouraria;

use E258Tech\Model\Service\OperationalModuleService;

final class TesourariaService extends OperationalModuleService
{
    protected function operations(): array
    {
        return [
            'conta.create'          => $this->op('POST', '/api/tesouraria/contas-bancarias'),
            'caixa.create'          => $this->op('POST', '/api/tesouraria/caixas'),
            'movimento.create'      => $this->op('POST', '/api/tesouraria/movimentos'),
            'reconciliacao.create'  => $this->op('POST', '/api/tesouraria/reconciliacoes'),
            'reconciliacao.fechar'  => $this->op('POST', '/api/tesouraria/reconciliacoes/{id}/fechar'),
        ];
    }

    private function op(string $method, string $path): array
    {
        return ['method' => $method, 'path' => $path];
    }
}
