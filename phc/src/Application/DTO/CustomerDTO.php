<?php

declare(strict_types=1);

namespace PHC\Application\DTO;

use PHC\Domain\Entity\Customer;

final readonly class CustomerDTO
{
    public function __construct(
        public int $id,
        public string $code,
        public string $name,
        public string $taxId,
        public string $phone,
        public string $email,
        public string $city,
        public float $balance
    ) {
    }

    public static function fromEntity(Customer $customer): self
    {
        return new self(
            $customer->id(),
            $customer->code(),
            $customer->name(),
            $customer->taxId(),
            $customer->phone(),
            $customer->email(),
            $customer->city(),
            $customer->balance()
        );
    }
}
