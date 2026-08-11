<?php

declare(strict_types=1);

namespace PHC\Domain\ValueObject;

use InvalidArgumentException;

final readonly class Money
{
    public function __construct(
        private int $cents,
        private string $currency = 'MT'
    ) {
        if ($this->cents < 0) {
            throw new InvalidArgumentException('O valor monetário não pode ser negativo.');
        }
    }

    public static function fromFloat(float $amount, string $currency = 'MT'): self
    {
        return new self((int) round($amount * 100), $currency);
    }

    public function cents(): int
    {
        return $this->cents;
    }

    public function currency(): string
    {
        return $this->currency;
    }

    public function toFloat(): float
    {
        return $this->cents / 100;
    }

    public function add(self $other): self
    {
        $this->assertSameCurrency($other);
        return new self($this->cents + $other->cents, $this->currency);
    }

    public function subtract(self $other): self
    {
        $this->assertSameCurrency($other);
        return new self($this->cents - $other->cents, $this->currency);
    }

    public function multiply(float $factor): self
    {
        return new self((int) round($this->cents * $factor), $this->currency);
    }

    public function percentage(int $percent): self
    {
        return new self((int) round($this->cents * $percent / 100), $this->currency);
    }

    public function equals(self $other): bool
    {
        return $this->currency === $other->currency && $this->cents === $other->cents;
    }

    public function isZero(): bool
    {
        return $this->cents === 0;
    }

    public function format(): string
    {
        return number_format($this->toFloat(), 2, ',', '.') . ' ' . $this->currency;
    }

    private function assertSameCurrency(self $other): void
    {
        if ($this->currency !== $other->currency) {
            throw new InvalidArgumentException('Moedas incompatíveis.');
        }
    }
}
