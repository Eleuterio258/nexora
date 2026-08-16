<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Infrastructure\Http;

use RuntimeException;

final class ApiException extends RuntimeException
{
    public function __construct(
        string $message,
        private readonly int $statusCode,
        private readonly ?string $errorCode = null
    ) {
        parent::__construct($message);
    }

    public function statusCode(): int
    {
        return $this->statusCode;
    }

    public function errorCode(): ?string
    {
        return $this->errorCode;
    }

    public function isUnauthorized(): bool
    {
        return $this->statusCode === 401;
    }
}
