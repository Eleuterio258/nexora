<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Domain\Repository;

use E258Tech\Faturacao\Domain\Entity\Customer;

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
