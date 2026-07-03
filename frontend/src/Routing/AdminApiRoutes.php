<?php
declare(strict_types=1);

namespace E258Tech\Routing;

use E258Tech\Routing\Api\AuthApiRoutes;
use E258Tech\Routing\Api\ComercialApiRoutes;
use E258Tech\Routing\Api\CrmRecrutamentoApiRoutes;
use E258Tech\Routing\Api\EmpresaClientesApiRoutes;
use E258Tech\Routing\Api\FinanceiroApiRoutes;
use E258Tech\Routing\Api\RhApiRoutes;
use E258Tech\Routing\Api\SistemaApiRoutes;
use E258Tech\Routing\Api\AssinaturaDigitalApiRoutes;
use InvalidArgumentException;

final class AdminApiRoutes
{
    private static ?array $all = null;

    private static function all(): array
    {
        return self::$all ??= array_merge(
            AuthApiRoutes::endpoints(),
            EmpresaClientesApiRoutes::endpoints(),
            ComercialApiRoutes::endpoints(),
            FinanceiroApiRoutes::endpoints(),
            RhApiRoutes::endpoints(),
            AssinaturaDigitalApiRoutes::endpoints(),
            CrmRecrutamentoApiRoutes::endpoints(),
            SistemaApiRoutes::endpoints(),
        );
    }

    public function definition(string $name): array
    {
        return self::all()[$name]
            ?? throw new InvalidArgumentException("Endpoint de API administrativo desconhecido: $name");
    }

    public function names(): array
    {
        return array_keys(self::all());
    }

    public function path(string $name): string
    {
        $this->definition($name);
        return "/nexora/api/$name";
    }
}
