<?php

declare(strict_types=1);

namespace PHC\Domain\Repository;

use PHC\Domain\Entity\Series;
use PHC\Domain\ValueObject\DocumentType;

interface SeriesRepositoryInterface
{
    /**
     * @return Series[]
     */
    public function findAll(): array;

    public function findById(int $id): ?Series;

    /**
     * @return Series[]
     */
    public function findActiveByType(DocumentType $type): array;

    public function save(Series $series): void;

    public function nextId(): int;
}
