<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Domain\ValueObject;

final readonly class CompanyInfo
{
    public function __construct(
        private string $name,
        private string $nuit
    ) {
    }

    public function name(): string
    {
        return $this->name;
    }

    public function nuit(): string
    {
        return $this->nuit;
    }
}
