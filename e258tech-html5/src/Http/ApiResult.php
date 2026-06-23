<?php
declare(strict_types=1);

namespace E258Tech\Http;

final readonly class ApiResult
{
    public function __construct(
        public array $body,
        public int $status = 200
    ) {
    }
}
