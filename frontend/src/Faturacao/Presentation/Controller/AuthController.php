<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Presentation\Controller;

use E258Tech\Faturacao\Infrastructure\Auth\AuthSession;
use E258Tech\Faturacao\Infrastructure\Http\ApiClient;
use E258Tech\Faturacao\Infrastructure\Http\ApiException;

final class AuthController
{
    public function __construct(
        private ApiClient $apiClient,
        private AuthSession $session,
        private string $viewDirectory
    ) {
    }

    public function showLogin(): void
    {
        if ($this->session->isAuthenticated()) {
            header('Location: /');
            exit;
        }
        $error = null;
        require $this->viewDirectory . '/login.php';
    }

    public function login(): void
    {
        $email = (string) ($_POST['email'] ?? '');
        $password = (string) ($_POST['password'] ?? '');

        if ($email === '' || $password === '') {
            $error = 'Indique o e-mail e a palavra-passe.';
            require $this->viewDirectory . '/login.php';
            return;
        }

        try {
            $response = $this->apiClient->post('/api/auth/login', [
                'email' => $email,
                'password' => $password,
            ]);
            $accessToken = (string) ($response['access_token'] ?? '');
            $refreshToken = (string) ($response['refresh_token'] ?? '');
            $userName = (string) ($response['user']['nome'] ?? $email);

            if ($accessToken === '') {
                throw new ApiException('A API não devolveu um token de acesso.', 500);
            }

            $this->session->store($accessToken, $refreshToken, $userName);
            header('Location: /');
            exit;
        } catch (ApiException $e) {
            $error = $e->isUnauthorized()
                ? 'Credenciais inválidas.'
                : $e->getMessage();
            require $this->viewDirectory . '/login.php';
        }
    }

    public function logout(): void
    {
        $this->session->clear();
        header('Location: /login');
        exit;
    }
}
