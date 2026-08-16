<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Domain\Entity;

use E258Tech\Faturacao\Domain\ValueObject\Money;

final class Customer
{
    public function __construct(
        private int $id,
        private string $code,
        private string $name,
        private string $nuit,
        private string $phone,
        private string $email,
        private string $city,
        private Money $balance = new Money(0)
    ) {
    }

    public function id(): int
    {
        return $this->id;
    }

    public function code(): string
    {
        return $this->code;
    }

    public function name(): string
    {
        return $this->name;
    }

    public function nuit(): string
    {
        return $this->nuit;
    }

    public function phone(): string
    {
        return $this->phone;
    }

    public function email(): string
    {
        return $this->email;
    }

    public function city(): string
    {
        return $this->city;
    }

    public function balance(): Money
    {
        return $this->balance;
    }

    public function increaseBalance(Money $amount): void
    {
        $this->balance = $this->balance->add($amount);
    }

    public function decreaseBalance(Money $amount): void
    {
        $this->balance = $this->balance->subtract($amount);
    }

    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'name' => $this->name,
            'nuit' => $this->nuit,
            'phone' => $this->phone,
            'email' => $this->email,
            'city' => $this->city,
            'balance' => $this->balance->toFloat(),
        ];
    }

    public static function fromArray(array $data): self
    {
        return new self(
            (int) $data['id'],
            $data['code'],
            $data['name'],
            $data['nuit'],
            $data['phone'],
            $data['email'],
            $data['city'],
            Money::fromFloat((float) ($data['balance'] ?? 0.0))
        );
    }
}
