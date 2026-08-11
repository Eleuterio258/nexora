<?php

declare(strict_types=1);

namespace PHC\Domain\ValueObject;

use InvalidArgumentException;

final readonly class DocumentType
{
    private const VALID_TYPES = ['FT', 'FR', 'VD', 'ORC', 'NC', 'PP'];

    public function __construct(private string $value)
    {
        if (!in_array($value, self::VALID_TYPES, true)) {
            throw new InvalidArgumentException('Tipo de documento inválido: ' . $value);
        }
    }

    public function value(): string
    {
        return $this->value;
    }

    public function label(): string
    {
        return match ($this->value) {
            'FT' => 'Fatura',
            'FR' => 'Fatura-recibo',
            'VD' => 'Venda a dinheiro',
            'ORC' => 'Orçamento',
            'NC' => 'Nota de crédito',
            'PP' => 'Fatura pro forma',
        };
    }

    public function isPaidOnIssue(): bool
    {
        return in_array($this->value, ['FR', 'VD'], true);
    }

    public function equals(self $other): bool
    {
        return $this->value === $other->value;
    }

    public function __toString(): string
    {
        return $this->value;
    }
}
