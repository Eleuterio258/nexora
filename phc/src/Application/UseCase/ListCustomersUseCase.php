<?php

declare(strict_types=1);

namespace PHC\Application\UseCase;

use PHC\Application\DTO\CustomerDTO;
use PHC\Domain\Repository\CustomerRepositoryInterface;

final class ListCustomersUseCase
{
    public function __construct(private CustomerRepositoryInterface $customers)
    {
    }

    public function execute(): array
    {
        return array_map(
            fn($customer) => CustomerDTO::fromEntity($customer),
            $this->customers->findAll()
        );
    }
}
