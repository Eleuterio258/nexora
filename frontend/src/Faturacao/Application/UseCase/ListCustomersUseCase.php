<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\UseCase;

use E258Tech\Faturacao\Application\DTO\CustomerDTO;
use E258Tech\Faturacao\Domain\Repository\CustomerRepositoryInterface;

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
