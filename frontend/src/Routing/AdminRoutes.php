<?php
declare(strict_types=1);

namespace E258Tech\Routing;

use E258Tech\Routing\Pages\ComercialPageRoutes;
use E258Tech\Routing\Pages\FinanceiroPageRoutes;
use E258Tech\Routing\Pages\RhPageRoutes;
use E258Tech\Routing\Pages\SistemaPageRoutes;

final class AdminRoutes
{
    private static ?array $pages = null;

    private static function pages(): array
    {
        return self::$pages ??= array_merge(
            ComercialPageRoutes::pages(),
            FinanceiroPageRoutes::pages(),
            RhPageRoutes::pages(),
            SistemaPageRoutes::pages(),
        );
    }

    private readonly SchoolAdminRoutes $schoolRoutes;
    private readonly StudentAdminRoutes $studentRoutes;

    public function __construct()
    {
        $this->schoolRoutes  = new SchoolAdminRoutes();
        $this->studentRoutes = new StudentAdminRoutes();
    }

    public function resolveByPath(string $path): ?string
    {
        $clean = rtrim($path, '/');
        foreach (self::pages() as $name => $def) {
            if (rtrim($def['path'], '/') === $clean) {
                return $name;
            }
        }
        return $this->schoolRoutes->resolveByPath($path);
    }

    public function definition(string $name): array
    {
        if (isset(self::pages()[$name])) {
            return self::pages()[$name];
        }
        return $this->schoolRoutes->definition($name);
    }

    public function names(): array
    {
        return array_merge(array_keys(self::pages()), $this->schoolRoutes->names());
    }

    public function path(string $name, array $query = []): string
    {
        if (isset(self::pages()[$name])) {
            $path = self::pages()[$name]['path'];
        } else {
            return $this->schoolRoutes->path($name, $query);
        }

        $query = array_filter(
            $query,
            static fn(mixed $value): bool => $value !== null && $value !== ''
        );

        return $path . ($query ? '?' . http_build_query($query) : '');
    }

    public function escolarBreadcrumb(array $tail): array
    {
        return $this->schoolRoutes->escolarBreadcrumb($tail);
    }

    public function alunoBreadcrumb(array $tail): array
    {
        return $this->studentRoutes->alunoBreadcrumb($tail);
    }

    public function api(string $name): string
    {
        return (new AdminApiRoutes())->path($name);
    }

    public function apiNames(): array
    {
        return (new AdminApiRoutes())->names();
    }
}
