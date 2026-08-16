<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\DTO;

final readonly class CreateDocumentRequest
{
    /**
     * @param CreateDocumentLineRequest[] $lines
     */
    public function __construct(
        public string $type,
        public int $seriesId,
        public int $customerId,
        public string $date,
        public string $dueDate,
        public array $lines,
        public string $notes = '',
        public string $reference = '',
        public bool $draft = false
    ) {
    }
}
