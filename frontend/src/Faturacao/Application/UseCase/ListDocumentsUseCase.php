<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\UseCase;

use E258Tech\Faturacao\Application\DTO\CustomerDTO;
use E258Tech\Faturacao\Application\DTO\DocumentDTO;
use E258Tech\Faturacao\Application\DTO\ListDocumentsRequest;
use E258Tech\Faturacao\Domain\Entity\Document;
use E258Tech\Faturacao\Domain\Repository\CustomerRepositoryInterface;
use E258Tech\Faturacao\Domain\Repository\DocumentRepositoryInterface;

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
