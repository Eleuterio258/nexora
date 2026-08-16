<?php

declare(strict_types=1);

namespace PHC\Infrastructure\Auth;

/**
 * Envolve a sessão nativa do PHP para guardar o token da API do backend.
 * O phc não tem identidade própria — autentica-se sempre como um
 * utilizador real do Nexora, o access_token devolvido pelo /api/auth/login
 * é a única credencial usada em todos os pedidos subsequentes.
 */
final class AuthSession
{
    private const KEY = 'phc_auth';

    public function __construct()
    {
        if (session_status() !== PHP_SESSION_ACTIVE) {
            session_start();
        }
    }

    public function isAuthenticated(): bool
    {
        return $this->accessToken() !== null;
    }

    public function accessToken(): ?string
    {
        return $_SESSION[self::KEY]['access_token'] ?? null;
    }

    public function userName(): ?string
    {
        return $_SESSION[self::KEY]['user_name'] ?? null;
    }

    public function refreshToken(): ?string
    {
        return $_SESSION[self::KEY]['refresh_token'] ?? null;
    }

    public function store(string $accessToken, string $refreshToken, string $userName): void
    {
        $_SESSION[self::KEY] = [
            'access_token'  => $accessToken,
            'refresh_token' => $refreshToken,
            'user_name'     => $userName,
        ];
    }

    /**
     * Actualiza só o access_token depois de um refresh — /api/auth/refresh
     * não devolve um novo refresh_token nem o utilizador, só a credencial
     * de curta duração.
     */
    public function updateAccessToken(string $accessToken): void
    {
        if (isset($_SESSION[self::KEY])) {
            $_SESSION[self::KEY]['access_token'] = $accessToken;
        }
    }

    public function clear(): void
    {
        unset($_SESSION[self::KEY]);
    }
}
