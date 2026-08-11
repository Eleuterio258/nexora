<?php

declare(strict_types=1);

namespace PHC\Application\UseCase;

use PHC\Application\DTO\CustomerDTO;
use PHC\Application\DTO\DocumentDTO;
use PHC\Application\DTO\ListDocumentsRequest;
use PHC\Domain\Entity\Document;
use PHC\Domain\Repository\CustomerRepositoryInterface;
use PHC\Domain\Repository\DocumentRepositoryInterface;

final class ListDocumentsUseCase
{
    public function __construct(
        private DocumentRepositoryInterface $documents,
        private CustomerRepositoryInterface $customers
    ) {
    }

    public function execute(ListDocumentsRequest $request): array
    {
        $all = $this->documents->findAll();
        $customerMap = [];
        foreach ($this->customers->findAll() as $c) {
            $customerMap[$c->id()] = $c->name();
        }

        $filter = $request->filter;
        $search = strtolower(trim($request->search));

        $filtered = array_filter($all, function (Document $doc) use ($filter, $search, $customerMap) {
            if ($filter !== 'all' && $doc->status()->value() !== $filter && $doc->number()->type()->value() !== $filter) {
                return false;
            }

            if ($search === '') {
                return true;
            }

            $haystack = strtolower($doc->number() . ' ' . ($customerMap[$doc->customerId()] ?? ''));
            return str_contains($haystack, $search);
        });

        return array_map(
            fn(Document $doc) => DocumentDTO::fromEntity($doc, $customerMap[$doc->customerId()] ?? 'Consumidor final'),
            array_values($filtered)
        );
    }
}
