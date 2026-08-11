<?php

declare(strict_types=1);

namespace PHC\Domain\ValueObject;

final readonly class DocumentNumber
{
    public function __construct(
        private DocumentType $type,
        private string $seriesCode,
        private int $year,
        private int $sequential
    ) {
        if ($this->sequential < 1) {
            throw new \InvalidArgumentException('Sequencial deve ser maior ou igual a 1.');
        }
    }

    public function type(): DocumentType
    {
        return $this->type;
    }

    public function seriesCode(): string
    {
        return $this->seriesCode;
    }

    public function year(): int
    {
        return $this->year;
    }

    public function sequential(): int
    {
        return $this->sequential;
    }

    public function __toString(): string
    {
        return sprintf(
            '%s %s/%d-%06d',
            $this->type->value(),
            $this->seriesCode,
            $this->year,
            $this->sequential
        );
    }
}
