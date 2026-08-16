<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\DTO;

final readonly class CreateDocumentLineRequest
{
    public function __construct(
        public ?int $productId,
        public string $description,
        public float $quantity,
        public float $price,
        public float $discount,
        public int $tax
    ) {
    }
}
