<?php
declare(strict_types=1);

namespace E258Tech\Http;

final readonly class HttpResponse
{
    public function __construct(
        public int $status,
        public ?array $body = null
    ) {
    }

    public function successful(): bool
    {
        return $this->status >= 200 && $this->status < 300;
    }
}
