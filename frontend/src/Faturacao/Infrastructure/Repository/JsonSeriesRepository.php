<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Infrastructure\Repository;

use E258Tech\Faturacao\Domain\Entity\Series;
use E258Tech\Faturacao\Domain\Repository\SeriesRepositoryInterface;
use E258Tech\Faturacao\Domain\ValueObject\DocumentType;
use E258Tech\Faturacao\Infrastructure\Persistence\JsonDataStore;

final class JsonSeriesRepository implements SeriesRepositoryInterface
{
    private const FILE = 'series';

    public function __construct(private JsonDataStore $store)
    {
    }

    public function findAll(): array
    {
        return array_map(
            fn(array $row) => Series::fromArray($row),
            $this->store->read(self::FILE)
        );
    }

    public function findById(int $id): ?Series
    {
        foreach ($this->findAll() as $series) {
            if ($series->id() === $id) {
                return $series;
            }
        }
        return null;
    }

    public function findActiveByType(DocumentType $type): array
    {
        return array_filter(
            $this->findAll(),
            fn(Series $s) => $s->isActive() && $s->type()->equals($type)
        );
    }

    public function save(Series $series): void
    {
        $all = $this->store->read(self::FILE);
        $found = false;
        foreach ($all as $index => $existing) {
            if ((int) $existing['id'] === $series->id()) {
                $all[$index] = $series->toArray();
                $found = true;
                break;
            }
        }

        if (!$found) {
            $all[] = $series->toArray();
        }

        $this->store->write(self::FILE, $all);
    }

    public function nextId(): int
    {
        $ids = array_map(fn(Series $s) => $s->id(), $this->findAll());
        return empty($ids) ? 1 : max($ids) + 1;
    }
}
