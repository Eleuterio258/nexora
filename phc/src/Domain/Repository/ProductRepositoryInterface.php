<?php

declare(strict_types=1);

namespace PHC\Domain\Repository;

use PHC\Domain\Entity\Product;

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
