<?php
declare(strict_types=1);

namespace E258Tech\Http;

final readonly class BinaryResponse
{
    public function __construct(
        public int $status,
        public string $contentType,
        public array $headers,
        public string $body
    ) {
    }
}
