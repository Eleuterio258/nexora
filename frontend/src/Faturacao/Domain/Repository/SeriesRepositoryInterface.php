<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Domain\Repository;

use E258Tech\Faturacao\Domain\Entity\Series;
use E258Tech\Faturacao\Domain\ValueObject\DocumentType;

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
