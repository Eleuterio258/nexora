<?php

declare(strict_types=1);

namespace PHC\Application\UseCase;

use PHC\Application\DTO\ProductDTO;
use PHC\Domain\Repository\ProductRepositoryInterface;

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
