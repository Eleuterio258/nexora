<?php

declare(strict_types=1);

namespace PHC\Infrastructure\Repository;

use PHC\Domain\Entity\Customer;
use PHC\Domain\Repository\CustomerRepositoryInterface;
use PHC\Infrastructure\Persistence\JsonDataStore;

final class JsonCustomerRepository implements CustomerRepositoryInterface
{
    private const FILE = 'customers';

    public function __construct(private JsonDataStore $store)
    {
    }

    public function findAll(): array
    {
        return array_map(
            fn(array $row) => Customer::fromArray($row),
            $this->store->read(self::FILE)
        );
    }

    public function findById(int $id): ?Customer
    {
        foreach ($this->findAll() as $customer) {
            if ($customer->id() === $id) {
                return $customer;
            }
        }
        return null;
    }

    public function save(Customer $customer): void
    {
        $all = $this->store->read(self::FILE);
        $found = false;
        foreach ($all as $index => $existing) {
            if ((int) $existing['id'] === $customer->id()) {
                $all[$index] = $customer->toArray();
                $found = true;
                break;
            }
        }

        if (!$found) {
            $all[] = $customer->toArray();
        }

        $this->store->write(self::FILE, $all);
    }

    public function nextId(): int
    {
        $ids = array_map(fn(Customer $c) => $c->id(), $this->findAll());
        return empty($ids) ? 1 : max($ids) + 1;
    }
}
