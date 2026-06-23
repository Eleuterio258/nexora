<?php
declare(strict_types=1);

namespace E258Tech\Http;

final readonly class ServerRequest
{
    public function __construct(
        private array $query,
        private array $post,
        private array $files,
        private array $server,
        private ?array $body = null
    ) {
    }

    public static function fromGlobals(): self
    {
        $body = $_POST;
        $contentType = strtolower((string) ($_SERVER['CONTENT_TYPE'] ?? ''));
        if (str_contains($contentType, 'application/json')) {
            $decoded = json_decode((string) file_get_contents('php://input'), true);
            $body = is_array($decoded) ? $decoded : [];
        }

        return new self($_GET, $_POST, $_FILES, $_SERVER, $body);
    }

    public function method(): string
    {
        return strtoupper((string) ($this->server['REQUEST_METHOD'] ?? 'GET'));
    }

    public function isPost(): bool
    {
        return $this->method() === 'POST';
    }

    public function query(): array
    {
        return $this->query;
    }

    public function queryString(string $key, string $default = ''): string
    {
        return trim((string) ($this->query[$key] ?? $default));
    }

    public function queryInt(string $key, ?int $default = null): ?int
    {
        $value = filter_var($this->query[$key] ?? null, FILTER_VALIDATE_INT);
        return $value === false || $value === null ? $default : $value;
    }

    public function queryEnum(string $key, array $allowed, string $default = ''): string
    {
        $value = $this->queryString($key);
        return in_array($value, $allowed, true) ? $value : $default;
    }

    public function postString(string $key, string $default = ''): string
    {
        return trim((string) ($this->post[$key] ?? $default));
    }

    public function postInt(string $key, ?int $default = null): ?int
    {
        $value = filter_var($this->post[$key] ?? null, FILTER_VALIDATE_INT);
        return $value === false || $value === null ? $default : $value;
    }

    public function postValue(string $key, mixed $default = null): mixed
    {
        return $this->post[$key] ?? $default;
    }

    public function body(): array
    {
        return $this->body ?? $this->post;
    }

    public function file(string $key): array
    {
        $file = $this->files[$key] ?? [];
        return is_array($file) ? $file : [];
    }

    public function requestUri(): string
    {
        return (string) ($this->server['REQUEST_URI'] ?? '');
    }

    public function csrfToken(): string
    {
        return trim((string) (
            $this->body()['csrf_token']
            ?? $this->body()['csrf']
            ?? $this->server['HTTP_X_CSRF_TOKEN']
            ?? ''
        ));
    }
}
