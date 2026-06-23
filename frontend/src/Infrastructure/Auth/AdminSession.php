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
        $_SESSION['nexora_user']            = $body['user'] ?? [];
        $_SESSION['nexora_modulos']         = $body['modulos'] ?? [];
        $_SESSION['nexora_modulos_at']      = time(); // timestamp da última sincronização
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
        return !empty($_SESSION['nexora_access_token']);
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

    public function can(string $module, string $action = 'ver'): bool
    {
        if ($this->isSuperAdmin()) {
            return true;
        }
        foreach ($_SESSION['nexora_modulos'] ?? [] as $permission) {
            if (($permission['modulo'] ?? '') === $module) {
                return in_array($action, $permission['acoes'] ?? [], true);
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

    public function homeUrl(): string
    {
        // Dashboard acessível a todos os autenticados — destino padrão após login
        return '/nexora/';
    }
}
