<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\DTO;

use E258Tech\Faturacao\Domain\Entity\Document;

final readonly class DocumentDTO
{
    /**
     * @param DocumentLineDTO[] $lines
     */
    public function __construct(
        public int $id,
        public string $type,
        public string $typeLabel,
        public string $number,
        public int $customerId,
        public string $customerName,
        public string $date,
        public string $dueDate,
        public string $subtotal,
        public string $discount,
        public string $tax,
        public string $total,
        public string $status,
        public string $statusLabel,
        public array $lines,
        public string $notes,
        public string $reference
    ) {
    }

    public static function fromEntity(Document $document, string $customerName): self
    {
        return new self(
            $document->id(),
            $document->number()->type()->value(),
            $document->number()->type()->label(),
            (string) $document->number(),
            $document->customerId(),
            $customerName,
            $document->date()->format('Y-m-d'),
            $document->dueDate()->format('Y-m-d'),
            $document->subtotal()->format(),
            $document->discount()->format(),
            $document->tax()->format(),
            $document->total()->format(),
            $document->status()->value(),
            $document->status()->label(),
            array_map(fn($line) => DocumentLineDTO::fromEntity($line), $document->lines()),
            $document->notes(),
            $document->reference()
        );
    }
}
