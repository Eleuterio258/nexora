<?php
declare(strict_types=1);

namespace E258Tech\Infrastructure\Auth;

use E258Tech\Infrastructure\Nexora\NexoraClient;

final class AdminSession
{
    /** Tempo em segundos antes de revalidar permissões com a API. */
    private const MODULOS_TTL = 300; // 5 minutos

    public function __construct(private readonly NexoraClient $client)
    {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
    }

    public function login(string $email, string $password): array
    {
        $response = $this->client->authenticate($email, $password);
        return ['status' => $response->status, 'body' => $response->body];
    }

    public function store(array $body): void
    {
        $_SESSION['nexora_access_token']    = $body['access_token'] ?? '';
        $_SESSION['nexora_refresh_token']   = $body['refresh_token'] ?? '';
        $_SESSION['nexora_token_expires_at'] = time() + (int) ($body['expires_in'] ?? 900);
        $_SESSION['nexora_tipo']            = $body['tipo'] ?? 'funcionario';
        $_SESSION['nexora_escopos']         = $this->normalizeEscopos($body['escopo'] ?? ($_SESSION['nexora_user']['escopo'] ?? 'erp'));
        $_SESSION['nexora_escopo']          = $this->legacyEscopo($_SESSION['nexora_escopos']);
        $_SESSION['nexora_user']            = $body['user'] ?? [];
        $_SESSION['nexora_modulos']         = $body['modulos'] ?? [];
        $_SESSION['nexora_features']        = $body['features'] ?? [];
        if (($_SESSION['nexora_tipo'] ?? '') === 'aluno' && !empty($body['aluno'])) {
            $_SESSION['portal_aluno_token']      = $body['access_token'] ?? '';
            $_SESSION['portal_aluno_info']       = $body['aluno'];
            $_SESSION['portal_aluno_expires_at'] = time() + (int) ($body['expires_in'] ?? 28800);
        }
        if (($_SESSION['nexora_tipo'] ?? '') === 'encarregado' && !empty($body['encarregado'])) {
            $_SESSION['enc_token']      = $body['access_token'] ?? '';
            $_SESSION['enc_info']       = $body['encarregado'];
            $_SESSION['enc_expires_at'] = time() + (int) ($body['expires_in'] ?? 28800);
        }
        $escoposRaw = is_array($body['escopo'] ?? null) ? $body['escopo'] : [$body['escopo'] ?? ''];
        if (in_array('portal_professor', $escoposRaw, true)) {
            $_SESSION['prof_token']      = $body['access_token'] ?? '';
            $_SESSION['prof_expires_at'] = time() + (int) ($body['expires_in'] ?? 28800);
        }
        // Se features não vieram no login, forçar sync na primeira request
        $_SESSION['nexora_modulos_at']      = empty($_SESSION['nexora_features']) && ($_SESSION['nexora_tipo'] !== 'superadmin')
                                                ? 0
                                                : time();
    }

    public function refresh(): bool
    {
        $refreshToken = (string) ($_SESSION['nexora_refresh_token'] ?? '');
        if ($refreshToken === '') {
            return false;
        }

        $response = $this->client->refresh($refreshToken);
        if ($response->status !== 200 || empty($response->body['access_token'])) {
            return false;
        }

        $_SESSION['nexora_access_token'] = $response->body['access_token'];
        $_SESSION['nexora_token_expires_at'] =
            time() + (int) ($response->body['expires_in'] ?? 900);
        return true;
    }

    /**
     * Recarrega permissões de GET /api/auth/me/acesso.
     * Chamado automaticamente quando o TTL expira.
     * Silencia erros de rede — mantém cache anterior se a API falhar.
     */
    public function syncModulos(): void
    {
        if ($this->isSuperAdmin()) {
            $_SESSION['nexora_modulos_at'] = time();
            return;
        }

        try {
            $resp = $this->client->call('GET', '/api/auth/me/acesso');
            if ($resp['status'] === 200 && isset($resp['body']['modulos'])) {
                $_SESSION['nexora_modulos']    = $resp['body']['modulos'];
                $_SESSION['nexora_features']   = $resp['body']['features'] ?? [];
                $_SESSION['nexora_modulos_at'] = time();
            }
        } catch (\Throwable) {
            // Sem rede ou erro: mantém cache — não interrompe o request
            $_SESSION['nexora_modulos_at'] = time(); // reset TTL para não ficar a tentar em cada request
        }
    }

    public function logout(): void
    {
        $token = (string) ($_SESSION['nexora_access_token'] ?? '');
        if ($token !== '') {
            $this->client->logout($token);
        }
    }

    public function isAuthenticated(): bool
    {
        $token = (string) ($_SESSION['nexora_access_token'] ?? '');
        $expiresAt = (int) ($_SESSION['nexora_token_expires_at'] ?? 0);
        return $token !== '' && $expiresAt > time();
    }

    public function expiresSoon(): bool
    {
        return (int) ($_SESSION['nexora_token_expires_at'] ?? 0) < time() + 30;
    }

    /**
     * Verdadeiro se o cache de módulos deve ser refrescado.
     * Verifica o TTL local (5 min) E se o admin actualizou permissões desde o último sync.
     */
    public function modulosExpirados(): bool
    {
        // TTL expirou
        $lastSync = (int) ($_SESSION['nexora_modulos_at'] ?? 0);
        if ((time() - $lastSync) >= self::MODULOS_TTL) {
            return true;
        }

        // Admin actualizou permissões depois do último sync → refresh imediato
        $permUpdatedAt = (int) ($_SESSION['nexora_perm_server_ts'] ?? 0);
        if ($permUpdatedAt > $lastSync) {
            return true;
        }

        return false;
    }

    /**
     * Actualiza o timestamp do servidor (permissoes_atualizadas_em) na sessão.
     * Chamado ao fazer login e ao fazer sync.
     */
    public function refreshPermTimestamp(): void
    {
        try {
            $resp = $this->client->call('GET', '/api/auth/me/perm-ts');
            if ($resp['status'] === 200 && isset($resp['body']['ts'])) {
                $_SESSION['nexora_perm_server_ts'] = (int) $resp['body']['ts'];
            }
        } catch (\Throwable) {
            // silencioso — não interrompe o request
        }
    }

    public function clear(): void
    {
        $_SESSION = [];
        if (session_status() === PHP_SESSION_ACTIVE) {
            session_destroy();
        }
    }

    public function user(): array
    {
        return $_SESSION['nexora_user'] ?? [];
    }

    public function isSuperAdmin(): bool
    {
        return ($_SESSION['nexora_tipo'] ?? '') === 'superadmin';
    }

    public function isProfessor(): bool
    {
        return $this->hasEscopo('portal_professor');
    }

    public function token(): string
    {
        return (string) ($_SESSION['nexora_access_token'] ?? '');
    }

    public function escopo(): string
    {
        return $_SESSION['nexora_escopo'] ?? 'erp';
    }

    public function escopos(): array
    {
        return $_SESSION['nexora_escopos'] ?? [$this->escopo()];
    }

    public function isErpOnly(): bool
    {
        return $this->escopo() === 'erp';
    }

    public function isSchoolOnly(): bool
    {
        return $this->escopo() === 'escola';
    }

    public function isBoth(): bool
    {
        return false;
    }

    public function hasEscopo(string $escopo): bool
    {
        if ($this->isSuperAdmin() && $escopo === 'superadmin') {
            return true;
        }
        return in_array($escopo, $this->escopos(), true);
    }

    public function can(string $module, string $action = 'ver'): bool
    {
        if ($this->isSuperAdmin()) {
            return true;
        }
        foreach ($_SESSION['nexora_modulos'] ?? [] as $permission) {
            if (($permission['modulo'] ?? '') === $module) {
                $acoes = $permission['acoes'] ?? [];
                return in_array($action, $acoes, true) || in_array('*', $acoes, true);
            }
        }
        return false;
    }

    /** Verdadeiro se o utilizador tem o módulo com qualquer acção (sem depender do nome da acção). */
    public function canModule(string $module): bool
    {
        if ($this->isSuperAdmin()) {
            return true;
        }
        foreach ($_SESSION['nexora_modulos'] ?? [] as $permission) {
            if (($permission['modulo'] ?? '') === $module && !empty($permission['acoes'])) {
                return true;
            }
        }
        return false;
    }

    /**
     * Verdadeiro se a funcionalidade está activa para o tenant do utilizador.
     * Superadmin tem acesso implícito a todas as features.
     */
    public function canFeature(string $feature): bool
    {
        if ($this->isSuperAdmin()) {
            return true;
        }
        return in_array($feature, $_SESSION['nexora_features'] ?? [], true);
    }

    public function homeUrl(): string
    {
        return '/nexora/destino';
    }

    public function defaultDestinationUrl(): string
    {
        if ($this->isSuperAdmin()) {
            return '/nexora/superadmin';
        }
        if ($this->isProfessor()) {
            return '/portal/professor';
        }
        if ($this->isSchoolOnly()) {
            return '/escola';
        }
        if ($this->hasEscopo('portal_aluno')) {
            return '/portal/aluno';
        }
        if ($this->hasEscopo('portal_encarregado')) {
            return '/portal/encarregado';
        }
        return '/nexora/';
    }

    private function normalizeEscopos(mixed $escopo): array
    {
        if (is_array($escopo)) {
            $escopos = array_values(array_unique(array_filter(
                array_map('strval', $escopo),
                static fn(string $value): bool => in_array($value, ['erp', 'escola', 'portal_aluno', 'portal_encarregado', 'portal_professor', 'superadmin'], true)
            )));
            return $escopos ?: ['erp'];
        }
        return match ((string) $escopo) {
            'escola'              => ['escola'],
            'portal_aluno'        => ['portal_aluno'],
            'portal_encarregado'  => ['portal_encarregado'],
            'portal_professor'    => ['portal_professor'],
            'superadmin'          => ['superadmin'],
            default               => ['erp'],
        };
    }

    private function legacyEscopo(array $escopos): string
    {
        if (in_array('superadmin', $escopos, true)) {
            return 'superadmin';
        }
        if (in_array('portal_aluno', $escopos, true)) {
            return 'portal_aluno';
        }
        if (in_array('portal_encarregado', $escopos, true)) {
            return 'portal_encarregado';
        }
        if (in_array('portal_professor', $escopos, true)) {
            return 'portal_professor';
        }
        $hasEscola = in_array('escola', $escopos, true);
        return $hasEscola ? 'escola' : 'erp';
    }
}
