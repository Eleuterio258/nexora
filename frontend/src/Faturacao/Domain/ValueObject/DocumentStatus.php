<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Domain\ValueObject;

use InvalidArgumentException;

final readonly class DocumentStatus
{
    private const VALID = ['draft', 'pending', 'paid', 'overdue', 'cancelled'];

    public function __construct(private string $value)
    {
        if (!in_array($value, self::VALID, true)) {
            throw new InvalidArgumentException('Estado de documento inválido: ' . $value);
        }
    }

    public function value(): string
    {
        return $this->value;
    }

    public function label(): string
    {
        return match ($this->value) {
            'draft' => 'Rascunho',
            'pending' => 'Pendente',
            'paid' => 'Pago',
            'overdue' => 'Vencido',
            'cancelled' => 'Anulado',
        };
    }

    public function equals(self $other): bool
    {
        return $this->value === $other->value;
    }
}
