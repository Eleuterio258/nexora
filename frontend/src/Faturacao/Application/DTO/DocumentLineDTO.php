<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\DTO;

use E258Tech\Faturacao\Domain\Entity\DocumentLine;

final readonly class DocumentLineDTO
{
    public function __construct(
        public ?int $productId,
        public string $description,
        public float $quantity,
        public float $price,
        public float $discount,
        public int $tax,
        public string $total
    ) {
    }

    public static function fromEntity(DocumentLine $line): self
    {
        return new self(
            $line->productId(),
            $line->description(),
            $line->quantity(),
            $line->unitPrice()->toFloat(),
            $line->discountPercent(),
            $line->tax()->percentage(),
            $line->total()->format()
        );
    }
}
