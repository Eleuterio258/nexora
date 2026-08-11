<?php

declare(strict_types=1);

namespace PHC\Domain\Repository;

use PHC\Domain\Entity\Customer;

interface CustomerRepositoryInterface
{
    /**
     * @return Customer[]
     */
    public function findAll(): array;

    public function findById(int $id): ?Customer;

    public function save(Customer $customer): void;

    public function nextId(): int;
}
