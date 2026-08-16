<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Domain\Repository;

use E258Tech\Faturacao\Domain\Entity\Document;
use E258Tech\Faturacao\Domain\ValueObject\DocumentStatus;

interface DocumentRepositoryInterface
{
    /**
     * @return Document[]
     */
    public function findAll(): array;

    public function findById(int $id): ?Document;

    /**
     * @return Document[]
     */
    public function findByStatus(DocumentStatus $status): array;

    public function save(Document $document): void;

    public function nextId(): int;
}
