<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin;

use E258Tech\Controller\Admin\Api;
use E258Tech\Core\ApplicationContainer;
use E258Tech\Http\ApiResult;
use E258Tech\Infrastructure\Auth\PhpSessionAuthorization;
use E258Tech\Model\Service\Authorization\AuthorizationAdminService;
use E258Tech\Model\Service\School\SchoolService;

final readonly class AdminApiRuntime
{
    public AdminApiDependencies $dependencies;

    public function __construct(ApplicationContainer $app)
    {
        $gateway = $app->nexora;
        $this->dependencies = new AdminApiDependencies(
            new AdminApiKernel(
                new PhpSessionAuthorization(),
                $app->request,
                $app->security
            ),
            $gateway,
            new AuthorizationAdminService($gateway),
            new SchoolService($gateway),
            $app->id,
        );
    }

    public function result(callable $operation, string $errorKey = 'erro'): ApiResult
    {
        return $this->dependencies->result($operation, $errorKey);
    }

    public function normalizedPermissions(mixed $items): array
    {
        return $this->dependencies->normalizedPermissions($items);
    }

    public function dispatch(string $action): never
    {
        $routes = new \E258Tech\Routing\AdminApiRoutes();
        $def = $routes->definition($action);
        $controller = $this->resolveController($def['module']);
        $method = lcfirst(str_replace('_', '', ucwords($action, '_')));
        $httpMethod = $def['method'] ?? 'POST';
        $this->dependencies->kernel->handle(
            $def['module'],
            $def['action'],
            fn(\E258Tech\Http\Request $request): \E258Tech\Http\ApiResult
                => $controller->$method($request, $this->dependencies),
            $httpMethod
        );
    }

    private function resolveController(string $module): object
    {
        return match ($module) {
            'auth'           => new Api\AuthController(),
            'autorizacao'    => new Api\AutorizacaoController(),
            'gestao-escolar' => new Api\GestaoEscolarController(),
            default          => throw new \InvalidArgumentException("Controller nao encontrado para modulo: $module"),
        };
    }
}
