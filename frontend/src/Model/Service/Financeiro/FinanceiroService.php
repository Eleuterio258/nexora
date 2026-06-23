<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Financeiro;

use E258Tech\Model\Service\OperationalModuleService;

final class FinanceiroService extends OperationalModuleService
{
    protected function operations(): array
    {
        return [
            'categoria.create'  => $this->op('POST', '/api/financeiro/categorias'),
            'metodo.create'     => $this->op('POST', '/api/financeiro/metodos-pagamento'),
            'receber.create'    => $this->op('POST', '/api/financeiro/contas-receber'),
            'receber.pagar'     => $this->op('POST', '/api/financeiro/contas-receber/{id}/pagamento'),
            'pagar.create'      => $this->op('POST', '/api/financeiro/contas-pagar'),
            'pagar.pagar'       => $this->op('POST', '/api/financeiro/contas-pagar/{id}/pagamento'),
        ];
    }

    private function op(string $method, string $path): array
    {
        return ['method' => $method, 'path' => $path];
    }
}
