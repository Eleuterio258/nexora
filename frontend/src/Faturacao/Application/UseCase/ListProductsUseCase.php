<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\UseCase;

use E258Tech\Faturacao\Application\DTO\ProductDTO;
use E258Tech\Faturacao\Domain\Repository\ProductRepositoryInterface;

final class ListProductsUseCase
{
    public function __construct(private ProductRepositoryInterface $products)
    {
    }

    public function execute(): array
    {
        return array_map(
            fn($product) => ProductDTO::fromEntity($product),
            $this->products->findAll()
        );
    }
}
