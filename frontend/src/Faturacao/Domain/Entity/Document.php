<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Domain\Entity;

use DateTimeImmutable;
use E258Tech\Faturacao\Domain\ValueObject\DocumentNumber;
use E258Tech\Faturacao\Domain\ValueObject\DocumentStatus;
use E258Tech\Faturacao\Domain\ValueObject\Money;

final class Document
{
    /**
     * @param DocumentLine[] $lines
     */
    public function __construct(
        private int $id,
        private DocumentNumber $number,
        private int $customerId,
        private DateTimeImmutable $date,
        private DateTimeImmutable $dueDate,
        private Money $subtotal,
        private Money $discount,
        private Money $tax,
        private Money $total,
        private DocumentStatus $status,
        private array $lines,
        private string $notes = '',
        private string $reference = ''
    ) {
    }

    public function id(): int
    {
        return $this->id;
    }

    public function number(): DocumentNumber
    {
        return $this->number;
    }

    public function customerId(): int
    {
        return $this->customerId;
    }

    public function date(): DateTimeImmutable
    {
        return $this->date;
    }

    public function dueDate(): DateTimeImmutable
    {
        return $this->dueDate;
    }

    public function subtotal(): Money
    {
        return $this->subtotal;
    }

    public function discount(): Money
    {
        return $this->discount;
    }

    public function tax(): Money
    {
        return $this->tax;
    }

    public function total(): Money
    {
        return $this->total;
    }

    public function status(): DocumentStatus
    {
        return $this->status;
    }

    /**
     * @return DocumentLine[]
     */
    public function lines(): array
    {
        return $this->lines;
    }

    public function notes(): string
    {
        return $this->notes;
    }

    public function reference(): string
    {
        return $this->reference;
    }

    public function setStatus(DocumentStatus $status): void
    {
        $this->status = $status;
    }

    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'type' => $this->number->type()->value(),
            'number' => (string) $this->number,
            'customerId' => $this->customerId,
            'date' => $this->date->format('Y-m-d'),
            'dueDate' => $this->dueDate->format('Y-m-d'),
            'subtotal' => $this->subtotal->toFloat(),
            'discount' => $this->discount->toFloat(),
            'tax' => $this->tax->toFloat(),
            'total' => $this->total->toFloat(),
            'status' => $this->status->value(),
            'notes' => $this->notes,
            'reference' => $this->reference,
            'lines' => array_map(fn(DocumentLine $line) => $line->toArray(), $this->lines),
        ];
    }

    public static function fromArray(array $data): self
    {
        preg_match('/^(\w+)\s+(\w+)\/(\d{4})-(\d{6})$/', $data['number'], $matches);
        if (!$matches) {
            throw new \InvalidArgumentException('Número de documento inválido: ' . $data['number']);
        }

        $type = new \E258Tech\Faturacao\Domain\ValueObject\DocumentType($matches[1]);
        $number = new DocumentNumber($type, $matches[2], (int) $matches[3], (int) $matches[4]);

        return new self(
            (int) $data['id'],
            $number,
            (int) $data['customerId'],
            new DateTimeImmutable($data['date']),
            new DateTimeImmutable($data['dueDate']),
            Money::fromFloat((float) $data['subtotal']),
            Money::fromFloat((float) $data['discount']),
            Money::fromFloat((float) $data['tax']),
            Money::fromFloat((float) $data['total']),
            new DocumentStatus($data['status']),
            array_map(fn(array $line) => DocumentLine::fromArray($line), $data['lines'] ?? []),
            $data['notes'] ?? '',
            $data['reference'] ?? ''
        );
    }
}
