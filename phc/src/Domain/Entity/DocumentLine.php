<?php

declare(strict_types=1);

namespace PHC\Domain\Entity;

use PHC\Domain\ValueObject\Money;
use PHC\Domain\ValueObject\TaxRate;

final readonly class DocumentLine
{
    public function __construct(
        private ?int $productId,
        private string $description,
        private float $quantity,
        private Money $unitPrice,
        private float $discountPercent,
        private TaxRate $tax
    ) {
    }

    public function productId(): ?int
    {
        return $this->productId;
    }

    public function description(): string
    {
        return $this->description;
    }

    public function quantity(): float
    {
        return $this->quantity;
    }

    public function unitPrice(): Money
    {
        return $this->unitPrice;
    }

    public function discountPercent(): float
    {
        return $this->discountPercent;
    }

    public function tax(): TaxRate
    {
        return $this->tax;
    }

    public function gross(): Money
    {
        return $this->unitPrice->multiply($this->quantity);
    }

    public function discount(): Money
    {
        return $this->gross()->multiply($this->discountPercent / 100);
    }

    public function taxableBase(): Money
    {
        return $this->gross()->subtract($this->discount());
    }

    public function taxAmount(): Money
    {
        return $this->taxableBase()->percentage($this->tax->percentage());
    }

    public function total(): Money
    {
        return $this->taxableBase()->add($this->taxAmount());
    }

    public function toArray(): array
    {
        return [
            'productId' => $this->productId,
            'description' => $this->description,
            'quantity' => $this->quantity,
            'price' => $this->unitPrice->toFloat(),
            'discount' => $this->discountPercent,
            'tax' => $this->tax->percentage(),
        ];
    }

    public static function fromArray(array $data): self
    {
        return new self(
            isset($data['productId']) && $data['productId'] !== null ? (int) $data['productId'] : null,
            $data['description'] ?? '',
            (float) ($data['quantity'] ?? 1),
            Money::fromFloat((float) ($data['price'] ?? 0)),
            (float) ($data['discount'] ?? 0),
            TaxRate::fromFloat((float) ($data['tax'] ?? 16))
        );
    }
}
