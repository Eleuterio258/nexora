<?php

declare(strict_types=1);

namespace PHC\Domain\Repository;

use PHC\Domain\Entity\Document;
use PHC\Domain\ValueObject\DocumentStatus;

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
