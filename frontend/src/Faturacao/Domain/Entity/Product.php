<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Domain\Entity;

use E258Tech\Faturacao\Domain\ValueObject\Money;
use E258Tech\Faturacao\Domain\ValueObject\TaxRate;

final class Product
{
    public function __construct(
        private int $id,
        private string $code,
        private string $name,
        private string $unit,
        private Money $price,
        private TaxRate $tax,
        private ?int $stock,
        private bool $active = true
    ) {
    }

    public function id(): int
    {
        return $this->id;
    }

    public function code(): string
    {
        return $this->code;
    }

    public function name(): string
    {
        return $this->name;
    }

    public function unit(): string
    {
        return $this->unit;
    }

    public function price(): Money
    {
        return $this->price;
    }

    public function tax(): TaxRate
    {
        return $this->tax;
    }

    public function stock(): ?int
    {
        return $this->stock;
    }

    public function isActive(): bool
    {
        return $this->active;
    }

    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'name' => $this->name,
            'unit' => $this->unit,
            'price' => $this->price->toFloat(),
            'tax' => $this->tax->percentage(),
            'stock' => $this->stock,
            'active' => $this->active,
        ];
    }

    public static function fromArray(array $data): self
    {
        return new self(
            (int) $data['id'],
            $data['code'],
            $data['name'],
            $data['unit'],
            Money::fromFloat((float) $data['price']),
            TaxRate::fromFloat((float) $data['tax']),
            isset($data['stock']) && $data['stock'] !== null ? (int) $data['stock'] : null,
            (bool) ($data['active'] ?? true)
        );
    }
}
