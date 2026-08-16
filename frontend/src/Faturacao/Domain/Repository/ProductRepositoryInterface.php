<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Domain\Repository;

use E258Tech\Faturacao\Domain\Entity\Product;

interface ProductRepositoryInterface
{
    /**
     * @return Product[]
     */
    public function findAll(): array;

    public function findById(int $id): ?Product;

    public function save(Product $product): void;

    public function nextId(): int;
}
