<?php

declare(strict_types=1);

namespace PHC\Infrastructure\Repository;

use PHC\Domain\Entity\Product;
use PHC\Domain\Repository\ProductRepositoryInterface;
use PHC\Infrastructure\Persistence\JsonDataStore;

final class JsonProductRepository implements ProductRepositoryInterface
{
    private const FILE = 'products';

    public function __construct(private JsonDataStore $store)
    {
    }

    public function findAll(): array
    {
        return array_map(
            fn(array $row) => Product::fromArray($row),
            $this->store->read(self::FILE)
        );
    }

    public function findById(int $id): ?Product
    {
        foreach ($this->findAll() as $product) {
            if ($product->id() === $id) {
                return $product;
            }
        }
        return null;
    }

    public function save(Product $product): void
    {
        $all = $this->store->read(self::FILE);
        $found = false;
        foreach ($all as $index => $existing) {
            if ((int) $existing['id'] === $product->id()) {
                $all[$index] = $product->toArray();
                $found = true;
                break;
            }
        }

        if (!$found) {
            $all[] = $product->toArray();
        }

        $this->store->write(self::FILE, $all);
    }

    public function nextId(): int
    {
        $ids = array_map(fn(Product $p) => $p->id(), $this->findAll());
        return empty($ids) ? 1 : max($ids) + 1;
    }
}
