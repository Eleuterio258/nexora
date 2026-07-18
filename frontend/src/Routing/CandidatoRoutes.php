<?php
declare(strict_types=1);

namespace E258Tech\Routing;

use InvalidArgumentException;

/**
 * Rotas do Portal do Candidato (recrutamento).
 *
 * Roteamento público sob o prefixo /carreira/* (e o alias /vagas), separado
 * do ERP/Escola. A autenticação é unificada via /nexora/login — a sessão do
 * candidato vive em PortalCandidatoSession, sem localStorage/Bearer no browser.
 */
final class CandidatoRoutes
{
    private const PAGES = [
        'carreira'                    => ['path' => '/carreira',                    'view' => 'carreira.php'],
        'carreira_vagas'              => ['path' => '/vagas',                       'view' => 'carreira.php'],
        'carreira_estado'             => ['path' => '/carreira/estado',             'view' => 'carreira_estado.php'],
        'carreira_candidato_registar'     => ['path' => '/carreira/candidato/registar',     'view' => 'carreira_registar.php'],
        'carreira_candidato_area'         => ['path' => '/carreira/candidato/area',         'view' => 'candidato/dashboard.php', 'auth' => true],
        'carreira_candidato_candidaturas' => ['path' => '/carreira/candidato/candidaturas', 'view' => 'candidato/candidaturas.php', 'auth' => true],
        'carreira_candidato_mensagens'    => ['path' => '/carreira/candidato/mensagens',    'view' => 'candidato/mensagens.php', 'auth' => true],
        'carreira_candidato_perfil'       => ['path' => '/carreira/candidato/perfil',       'view' => 'candidato/perfil.php', 'auth' => true],
    ];

    public function resolveByPath(string $path): ?string
    {
        $clean = rtrim($path, '/') ?: '/';
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
            ?? throw new InvalidArgumentException("Rota de candidato desconhecida: $name");
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
     * URL do login unificado (/nexora/login), já apontado para regressar à
     * área do candidato — ou a outro destino interno — depois de autenticar.
     */
    public function loginUrl(string $next = '/carreira/candidato/area'): string
    {
        return '/nexora/login?next=' . urlencode($next);
    }
}
