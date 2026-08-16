<?php

declare(strict_types=1);

namespace PHC\Application\DTO;

use PHC\Domain\Entity\Product;

final readonly class ProductDTO
{
    public function __construct(
        public int $id,
        public string $code,
        public string $name,
        public string $unit,
        public float $price,
        public int $tax,
        public ?int $stock,
        public bool $active
    ) {
    }

    public static function fromEntity(Product $product): self
    {
        return new self(
            $product->id(),
            $product->code(),
            $product->name(),
            $product->unit(),
            $product->price()->toFloat(),
            $product->tax()->percentage(),
            $product->stock(),
            $product->isActive()
        );
    }
}
