<?php
declare(strict_types=1);

namespace E258Tech\Infrastructure\Auth;

/**
 * Gere a sessão PHP do portal do candidato.
 * Armazena o token do candidato separadamente da sessão do admin,
 * tal como o Portal do Aluno (ver PortalAlunoSession).
 */
final class PortalCandidatoSession
{
    private const TOKEN_KEY   = 'candidato_token';
    private const INFO_KEY    = 'candidato_info';
    private const EXPIRES_KEY = 'candidato_expires_at';

    public function __construct()
    {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
    }

    public function store(array $body): void
    {
        $_SESSION[self::TOKEN_KEY]   = $body['access_token'] ?? '';
        $_SESSION[self::INFO_KEY]    = $body['candidato'] ?? [];
        $_SESSION[self::EXPIRES_KEY] = time() + (int) ($body['expires_in'] ?? 2592000);
    }

    public function token(): string
    {
        return (string) ($_SESSION[self::TOKEN_KEY] ?? '');
    }

    public function candidato(): array
    {
        return (array) ($_SESSION[self::INFO_KEY] ?? []);
    }

    public function isAuthenticated(): bool
    {
        $token     = $this->token();
        $expiresAt = (int) ($_SESSION[self::EXPIRES_KEY] ?? 0);
        return $token !== '' && $expiresAt > time();
    }

    public function destroy(): void
    {
        unset(
            $_SESSION[self::TOKEN_KEY],
            $_SESSION[self::INFO_KEY],
            $_SESSION[self::EXPIRES_KEY]
        );
    }

    public function requireAuthenticated(string $loginPath = '/nexora/login?next=/carreira/candidato/area'): void
    {
        if (!$this->isAuthenticated()) {
            header('Location: ' . $loginPath);
            exit;
        }
    }
}
