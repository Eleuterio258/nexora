<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Domain\Entity;

use E258Tech\Faturacao\Domain\ValueObject\DocumentType;

final class Series
{
    public function __construct(
        private int $id,
        private string $code,
        private DocumentType $type,
        private string $description,
        private int $year,
        private int $next,
        private bool $active = true
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

    public function type(): DocumentType
    {
        return $this->type;
    }

    public function description(): string
    {
        return $this->description;
    }

    public function year(): int
    {
        return $this->year;
    }

    public function next(): int
    {
        return $this->next;
    }

    public function isActive(): bool
    {
        return $this->active;
    }

    public function allocateNextNumber(): int
    {
        $current = $this->next;
        $this->next++;
        return $current;
    }

    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'type' => $this->type->value(),
            'description' => $this->description,
            'year' => $this->year,
            'next' => $this->next,
            'active' => $this->active,
        ];
    }

    public static function fromArray(array $data): self
    {
        return new self(
            (int) $data['id'],
            $data['code'],
            new DocumentType($data['type']),
            $data['description'],
            (int) $data['year'],
            (int) $data['next'],
            (bool) ($data['active'] ?? true)
        );
    }
}
