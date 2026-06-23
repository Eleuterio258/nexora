<?php
declare(strict_types=1);

namespace E258Tech\Routing;

use E258Tech\Core\Application;
use E258Tech\Controller\Admin\AdminPageGuard;
use RuntimeException;

final readonly class AdminPageRouter
{
    public function __construct(
        private AdminRoutes $routes,
        private AdminPageGuard $guard,
        private string $viewRoot
    ) {
    }

    public function dispatch(string $route): void
    {
        $definition = $this->routes->definition($route);
        $this->guard->requireAuthenticated();
        $this->guard->requirePermission($definition['permission']);

        $view = $this->viewRoot . '/pages/' . $definition['view'];
        if (!is_file($view)) {
            throw new RuntimeException("View administrativa nao encontrada: $view");
        }

        $app = Application::instance();
        require $view;
    }
}
