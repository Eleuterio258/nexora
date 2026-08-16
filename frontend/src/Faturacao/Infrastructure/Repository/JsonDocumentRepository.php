<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Infrastructure\Repository;

use E258Tech\Faturacao\Domain\Entity\Document;
use E258Tech\Faturacao\Domain\Repository\DocumentRepositoryInterface;
use E258Tech\Faturacao\Domain\ValueObject\DocumentStatus;
use E258Tech\Faturacao\Infrastructure\Persistence\JsonDataStore;

final class JsonDocumentRepository implements DocumentRepositoryInterface
{
    private const FILE = 'documents';

    public function __construct(private JsonDataStore $store)
    {
    }

    public function findAll(): array
    {
        $items = $this->store->read(self::FILE);
        usort($items, fn(array $a, array $b) => $b['id'] <=> $a['id']);

        return array_map(
            fn(array $row) => Document::fromArray($row),
            $items
        );
    }

    public function findById(int $id): ?Document
    {
        foreach ($this->findAll() as $document) {
            if ($document->id() === $id) {
                return $document;
            }
        }
        return null;
    }

    public function findByStatus(DocumentStatus $status): array
    {
        return array_filter(
            $this->findAll(),
            fn(Document $d) => $d->status()->equals($status)
        );
    }

    public function save(Document $document): void
    {
        $all = $this->store->read(self::FILE);
        $found = false;
        foreach ($all as $index => $existing) {
            if ((int) $existing['id'] === $document->id()) {
                $all[$index] = $document->toArray();
                $found = true;
                break;
            }
        }

        if (!$found) {
            $all[] = $document->toArray();
        }

        usort($all, fn(array $a, array $b) => (int) $b['id'] <=> (int) $a['id']);
        $this->store->write(self::FILE, $all);
    }

    public function nextId(): int
    {
        $ids = array_map(fn(Document $d) => $d->id(), $this->findAll());
        return empty($ids) ? 1 : max($ids) + 1;
    }
}
