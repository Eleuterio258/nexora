<?php
declare(strict_types=1);

namespace E258Tech\Controller\Portal;

use E258Tech\Infrastructure\Auth\PortalAlunoSession;
use E258Tech\Infrastructure\Http\CurlHttpClient;

final class PortalAlunoController
{
    private CurlHttpClient $http;

    public function __construct(private readonly string $apiBase)
    {
        $this->http = new CurlHttpClient();
    }

    // ── Auth ──────────────────────────────────────────────────────────────────

    public function login(PortalAlunoSession $session): void
    {
        $csrfToken = $this->generateCsrfToken();

        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            $this->renderLogin('', $csrfToken);
            return;
        }

        if (!$this->validateCsrfToken((string) ($_POST['_csrf'] ?? ''))) {
            $this->renderLogin('Pedido inválido. Recarregue a página e tente novamente.', $this->generateCsrfToken());
            return;
        }

        $email    = trim((string) ($_POST['email'] ?? ''));
        $password = (string) ($_POST['password'] ?? '');

        if ($email === '' || $password === '') {
            $this->renderLogin('Email e password são obrigatórios.', $csrfToken);
            return;
        }

        $resp = $this->http->request(
            'POST',
            $this->apiBase . '/api/auth/login',
            ['email' => $email, 'password' => $password]
        );

        if ($resp->status === 200 && !empty($resp->body['access_token'])) {
            $session->store($resp->body);
            header('Location: /portal/aluno');
            exit;
        }

        $erro = $resp->body['error'] ?? $resp->body['message'] ?? $resp->body['erro'] ?? 'Credenciais inválidas.';
        $this->renderLogin($erro, $csrfToken);
    }

    public function logout(PortalAlunoSession $session): void
    {
        $token = $session->token();
        if ($token !== '') {
            $this->http->request(
                'POST',
                $this->apiBase . '/api/portal/aluno/logout',
                [],
                ["Authorization: Bearer $token"]
            );
        }
        $session->destroy();
        header('Location: /portal/aluno/login');
        exit;
    }

    public function definirSenha(): void
    {
        $token = trim((string) ($_GET['token'] ?? ''));
        if ($token === '') {
            http_response_code(400);
            echo 'Link inválido.';
            return;
        }

        $csrfToken = $this->generateCsrfToken();
        $erro      = null;
        $ok        = false;

        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            if (!$this->validateCsrfToken((string) ($_POST['_csrf'] ?? ''))) {
                $this->renderDefinirSenha($token, 'Pedido inválido. Recarregue a página.', false, $this->generateCsrfToken());
                return;
            }

            $password  = (string) ($_POST['password'] ?? '');
            $password2 = (string) ($_POST['password2'] ?? '');

            if (\strlen($password) < 6) {
                $erro = 'A senha deve ter pelo menos 6 caracteres.';
            } elseif ($password !== $password2) {
                $erro = 'As senhas não coincidem.';
            } else {
                $resp = $this->http->request(
                    'POST',
                    $this->apiBase . '/api/portal/aluno/definir-senha',
                    ['token' => $token, 'password' => $password]
                );
                if ($resp->status === 200) {
                    $ok = true;
                } else {
                    $erro = $resp->body['erro'] ?? $resp->body['message'] ?? 'Link inválido ou expirado.';
                }
            }
        }

        $this->renderDefinirSenha($token, $erro, $ok, $csrfToken);
    }

    // ── Chamadas API autenticadas ─────────────────────────────────────────────

    public function api(PortalAlunoSession $session, string $path, string $method = 'GET', ?array $body = null): array
    {
        $token = $session->token();
        $resp  = $this->http->request(
            $method,
            $this->apiBase . $path,
            $body,
            ["Authorization: Bearer $token"]
        );
        return ['status' => $resp->status, 'body' => $resp->body ?? []];
    }

    // ── Views ─────────────────────────────────────────────────────────────────

    private function renderLogin(string $erro = '', string $csrfToken = ''): void
    {
        require dirname(__DIR__, 2) . '/View/templates/portal/login.php';
    }

    private function renderDefinirSenha(string $token, ?string $erro, bool $ok, string $csrfToken = ''): void
    {
        require dirname(__DIR__, 2) . '/View/templates/portal/definir_senha.php';
    }

    // ── CSRF ──────────────────────────────────────────────────────────────────

    private function generateCsrfToken(): string
    {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
        if (empty($_SESSION['portal_csrf_token'])) {
            $_SESSION['portal_csrf_token'] = bin2hex(random_bytes(32));
        }
        return (string) $_SESSION['portal_csrf_token'];
    }

    private function validateCsrfToken(string $token): bool
    {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
        $stored = (string) ($_SESSION['portal_csrf_token'] ?? '');
        return $stored !== '' && hash_equals($stored, $token);
    }
}
