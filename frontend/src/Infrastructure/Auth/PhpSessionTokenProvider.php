<?php
declare(strict_types=1);

namespace E258Tech\Infrastructure\Auth;

use E258Tech\Model\Contract\HttpClient;
use E258Tech\Model\Contract\TokenProvider;
use E258Tech\Infrastructure\Http\HttpClientException;

final class PhpSessionTokenProvider implements TokenProvider
{
    public function __construct(
        private readonly HttpClient $http,
        private readonly string $baseUrl
    ) {
    }

    public function accessToken(bool $forceRefresh = false): string
    {
        $accessToken = (string) ($_SESSION['nexora_access_token'] ?? '');
        $expiresAt = (int) ($_SESSION['nexora_token_expires_at'] ?? 0);

        if (!$forceRefresh && $accessToken !== '' && $expiresAt > time() + 30) {
            return $accessToken;
        }

        $refreshToken = (string) ($_SESSION['nexora_refresh_token'] ?? '');
        if ($refreshToken !== '') {
            $response = $this->http->request(
                'POST',
                $this->baseUrl . '/api/auth/refresh',
                ['refresh_token' => $refreshToken]
            );

            if ($response->status === 200 && !empty($response->body['access_token'])) {
                $_SESSION['nexora_access_token'] = $response->body['access_token'];
                $_SESSION['nexora_token_expires_at'] =
                    time() + max(60, (int) ($response->body['expires_in'] ?? 900));

                return (string) $_SESSION['nexora_access_token'];
            }
        }

        unset(
            $_SESSION['nexora_access_token'],
            $_SESSION['nexora_refresh_token'],
            $_SESSION['nexora_token_expires_at']
        );

        throw new HttpClientException('Sessao Nexora expirada.');
    }
}
