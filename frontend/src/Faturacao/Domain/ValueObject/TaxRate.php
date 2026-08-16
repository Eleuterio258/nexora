<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Domain\ValueObject;

use InvalidArgumentException;

final readonly class TaxRate
{
    public function __construct(private int $percentage)
    {
        if ($this->percentage < 0 || $this->percentage > 100) {
            throw new InvalidArgumentException('Taxa de IVA inválida.');
        }
    }

    public static function fromFloat(float $percentage): self
    {
        return new self((int) round($percentage));
    }

    public function percentage(): int
    {
        return $this->percentage;
    }

    public function factor(): float
    {
        return 1 + ($this->percentage / 100);
    }

    public function equals(self $other): bool
    {
        return $this->percentage === $other->percentage;
    }
}
