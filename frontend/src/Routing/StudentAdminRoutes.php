<?php
declare(strict_types=1);

namespace E258Tech\Routing;

use InvalidArgumentException;

/**
 * Rotas de gestão do Portal do Aluno / módulo Aluno.
 *
 * Roteamento independente sob o prefixo /aluno/*, separado do Painel Escolar
 * e do ERP, mas pode reutilizar o layout escola quando $_escolarPanel = true.
 */
final class StudentAdminRoutes
{
    private const PAGES = [
        'aluno_portal'   => ['path' => '/aluno',        'view' => 'aluno_portal.php', 'permission' => 'gestao-escolar'],
        'aluno_alunos'   => ['path' => '/aluno/alunos', 'view' => 'aluno_portal.php', 'permission' => 'gestao-escolar'],
    ];

    public function resolveByPath(string $path): ?string
    {
        $clean = rtrim($path, '/');
        foreach (self::PAGES as $name => $def) {
            if (rtrim($def['path'], '/') === $clean) {
                return $name;
            }
        }
        return null;
    }

    public function definition(string $name): array
    {
        return self::PAGES[$name]
            ?? throw new InvalidArgumentException("Rota de aluno desconhecida: $name");
    }

    public function names(): array
    {
        return array_keys(self::PAGES);
    }

    public function path(string $name, array $query = []): string
    {
        $path = $this->definition($name)['path'];

        $query = array_filter(
            $query,
            static fn(mixed $value): bool => $value !== null && $value !== ''
        );

        return $path . ($query ? '?' . http_build_query($query) : '');
    }

    /**
     * Gera o breadcrumb base para views do módulo Aluno.
     * No Painel Escolar (/escola/*) o layout já imprime "Escola" como raiz.
     * No ERP (/nexora/*) retorna prefixo "Admin > Aluno".
     */
    public function alunoBreadcrumb(array $tail): array
    {
        if (!empty($GLOBALS['_escolarPanel'])) {
            return $tail;
        }
        return array_merge([['Admin', '/nexora/'], ['Aluno', '/aluno']], $tail);
    }
}
