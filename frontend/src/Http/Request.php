<?php
declare(strict_types=1);

namespace E258Tech\Http;

final readonly class Request
{
    public function __construct(private array $data)
    {
    }

    public static function fromServerRequest(ServerRequest $request): self
    {
        return new self($request->method() === 'GET' ? $request->query() : $request->body());
    }

    public function all(): array
    {
        return $this->data;
    }

    public function string(string $key, string $default = ''): string
    {
        return trim((string) ($this->data[$key] ?? $default));
    }

    public function int(string $key): ?int
    {
        $value = filter_var($this->data[$key] ?? null, FILTER_VALIDATE_INT);
        return $value === false ? null : $value;
    }

    public function float(string $key): ?float
    {
        $value = filter_var($this->data[$key] ?? null, FILTER_VALIDATE_FLOAT);
        return $value === false ? null : $value;
    }

    public function bool(string $key): bool
    {
        return filter_var($this->data[$key] ?? false, FILTER_VALIDATE_BOOL);
    }

    public function has(string $key): bool
    {
        return array_key_exists($key, $this->data);
    }

    public function csrfToken(): string
    {
        return $this->string('csrf_token', $this->string('csrf'));
    }
}
