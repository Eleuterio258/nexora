<?php
declare(strict_types=1);

namespace E258Tech\Infrastructure\Security;

final class WebSecurity
{
    public function csrfToken(): string
    {
        $this->startSession();
        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }

        return (string) $_SESSION['csrf_token'];
    }

    public function hasValidCsrf(string $token): bool
    {
        $this->startSession();
        $sessionToken = (string) ($_SESSION['csrf_token'] ?? '');
        return $sessionToken !== '' && hash_equals($sessionToken, $token);
    }

    public function sanitize(string $input, int $maxLength = 500): string
    {
        return htmlspecialchars(trim(substr($input, 0, $maxLength)), ENT_QUOTES, 'UTF-8');
    }

    public function sanitizeEmail(string $email): string|false
    {
        $email = filter_var(trim($email), FILTER_SANITIZE_EMAIL);
        return filter_var($email, FILTER_VALIDATE_EMAIL) ? $email : false;
    }

    public function allow(string $key, int $max = 5, int $window = 60): bool
    {
        $this->startSession();
        $now = time();
        $data = $_SESSION['rl'][$key] ?? ['count' => 0, 'start' => $now];

        if ($now - $data['start'] > $window) {
            $data = ['count' => 0, 'start' => $now];
        }

        $data['count']++;
        $_SESSION['rl'][$key] = $data;

        return $data['count'] <= $max;
    }

    public function jsonResponse(array $data, int $status = 200): never
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
        exit;
    }

    private function startSession(): void
    {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
    }
}
