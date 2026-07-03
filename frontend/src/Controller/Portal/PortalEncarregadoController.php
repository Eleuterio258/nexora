<?php
declare(strict_types=1);

namespace E258Tech\Controller\Portal;

use E258Tech\Infrastructure\Http\CurlHttpClient;

final class PortalEncarregadoController
{
    private CurlHttpClient $http;

    public function __construct(private readonly string $apiBase)
    {
        $this->http = new CurlHttpClient();
    }

    // ── Auth ──────────────────────────────────────────────────────────────────

    public function login(): void
    {
        $csrfToken = $this->generateCsrfToken();

        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            $this->renderLogin('', $csrfToken);
            return;
        }

        if (!$this->validateCsrfToken((string) ($_POST['_csrf'] ?? ''))) {
            $this->renderLogin('Pedido inválido. Recarregue a página.', $this->generateCsrfToken());
            return;
        }

        $email    = trim((string) ($_POST['email'] ?? ''));
        $password = (string) ($_POST['password'] ?? '');

        if ($email === '' || $password === '') {
            $this->renderLogin('Email e password são obrigatórios.', $csrfToken);
            return;
        }

        $resp = $this->http->request('POST', $this->apiBase . '/api/auth/login',
            ['email' => $email, 'password' => $password]);

        if ($resp->status === 200 && !empty($resp->body['access_token'])) {
            $this->storeSession($resp->body);
            header('Location: /portal/encarregado');
            exit;
        }

        $erro = $resp->body['error'] ?? $resp->body['message'] ?? $resp->body['erro'] ?? 'Credenciais inválidas.';
        $this->renderLogin($erro, $csrfToken);
    }

    public function logout(): void
    {
        $token = $this->getToken();
        if ($token !== '') {
            $this->http->request('POST', $this->apiBase . '/api/portal/encarregado/logout',
                [], ["Authorization: Bearer $token"]);
        }
        $this->destroySession();
        header('Location: /nexora/login?next=/portal/encarregado');
        exit;
    }

    public function definirSenha(): void
    {
        $token = trim((string) ($_GET['token'] ?? ''));
        if ($token === '') { http_response_code(400); echo 'Link inválido.'; return; }

        $csrfToken = $this->generateCsrfToken();
        $erro = null; $ok = false;

        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            if (!$this->validateCsrfToken((string)($_POST['_csrf'] ?? ''))) {
                $erro = 'Pedido inválido. Recarregue a página.';
            } else {
                $pass  = (string)($_POST['password'] ?? '');
                $pass2 = (string)($_POST['password2'] ?? '');
                if (\strlen($pass) < 6)         $erro = 'A senha deve ter pelo menos 6 caracteres.';
                elseif ($pass !== $pass2)        $erro = 'As senhas não coincidem.';
                else {
                    $r = $this->http->request('POST', $this->apiBase . '/api/portal/encarregado/definir-senha',
                        ['token' => $token, 'password' => $pass]);
                    $ok = ($r->status === 200);
                    if (!$ok) $erro = $r->body['erro'] ?? $r->body['message'] ?? 'Link inválido ou expirado.';
                }
            }
        }

        $viewRoot = dirname(__DIR__, 2) . '/View/templates/portal_encarregado';
        require $viewRoot . '/definir_senha.php';
    }

    // ── API wrapper ───────────────────────────────────────────────────────────

    public function api(string $path, string $method = 'GET', ?array $body = null): array
    {
        $token = $this->getToken();
        $resp  = $this->http->request($method, $this->apiBase . $path, $body,
            ["Authorization: Bearer $token"]);
        return ['status' => $resp->status, 'body' => $resp->body ?? []];
    }

    public function requireAuth(): void
    {
        if (!$this->isAuthenticated()) {
            header('Location: /nexora/login?next=/portal/encarregado');
            exit;
        }
    }

    // ── Session ───────────────────────────────────────────────────────────────

    private function storeSession(array $body): void
    {
        if (session_status() === PHP_SESSION_NONE) session_start();
        $_SESSION['enc_token']      = $body['access_token'] ?? '';
        $_SESSION['enc_info']       = $body['encarregado']  ?? [];
        $_SESSION['enc_expires_at'] = time() + (int)($body['expires_in'] ?? 28800);
    }

    public function getToken(): string
    {
        if (session_status() === PHP_SESSION_NONE) session_start();
        return (string)($_SESSION['enc_token'] ?? '');
    }

    public function isAuthenticated(): bool
    {
        if (session_status() === PHP_SESSION_NONE) session_start();
        return $this->getToken() !== '' && (int)($_SESSION['enc_expires_at'] ?? 0) > time();
    }

    private function destroySession(): void
    {
        if (session_status() === PHP_SESSION_NONE) session_start();
        unset($_SESSION['enc_token'], $_SESSION['enc_info'], $_SESSION['enc_expires_at']);
    }

    // ── Views ─────────────────────────────────────────────────────────────────

    private function renderLogin(string $erro = '', string $csrfToken = ''): void
    {
        require dirname(__DIR__, 2) . '/View/templates/portal_encarregado/login.php';
    }

    // ── CSRF ──────────────────────────────────────────────────────────────────

    private function generateCsrfToken(): string
    {
        if (session_status() === PHP_SESSION_NONE) session_start();
        if (empty($_SESSION['enc_csrf_token'])) {
            $_SESSION['enc_csrf_token'] = bin2hex(random_bytes(32));
        }
        return (string)$_SESSION['enc_csrf_token'];
    }

    private function validateCsrfToken(string $token): bool
    {
        if (session_status() === PHP_SESSION_NONE) session_start();
        $stored = (string)($_SESSION['enc_csrf_token'] ?? '');
        return $stored !== '' && hash_equals($stored, $token);
    }
}
