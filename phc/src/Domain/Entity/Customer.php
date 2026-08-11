<?php

declare(strict_types=1);

namespace PHC\Domain\Entity;

final class Customer
{
    public function __construct(
        private int $id,
        private string $code,
        private string $name,
        private string $taxId,
        private string $phone,
        private string $email,
        private string $city,
        private float $balance = 0.0
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

    public function taxId(): string
    {
        return $this->taxId;
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

    public function balance(): float
    {
        return $this->balance;
    }

    public function increaseBalance(float $amount): void
    {
        $this->balance += $amount;
    }

    public function decreaseBalance(float $amount): void
    {
        $this->balance -= $amount;
    }

    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'name' => $this->name,
            'taxId' => $this->taxId,
            'phone' => $this->phone,
            'email' => $this->email,
            'city' => $this->city,
            'balance' => $this->balance,
        ];
    }

    public static function fromArray(array $data): self
    {
        return new self(
            (int) $data['id'],
            $data['code'],
            $data['name'],
            $data['taxId'],
            $data['phone'],
            $data['email'],
            $data['city'],
            (float) ($data['balance'] ?? 0.0)
        );
    }
}
