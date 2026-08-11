<?php

declare(strict_types=1);

namespace PHC\Application\UseCase;

use InvalidArgumentException;
use PHC\Application\DTO\DocumentDTO;
use PHC\Domain\Repository\CustomerRepositoryInterface;
use PHC\Domain\Repository\DocumentRepositoryInterface;

final class PreviewDocumentUseCase
{
    public function __construct(
        private DocumentRepositoryInterface $documents,
        private CustomerRepositoryInterface $customers
    ) {
    }

    public function execute(int $documentId): DocumentDTO
    {
        $document = $this->documents->findById($documentId);
        if ($document === null) {
            throw new InvalidArgumentException('Documento não encontrado.');
        }

        $customer = $this->customers->findById($document->customerId());
        $customerName = $customer?->name() ?? 'Consumidor final';

        return DocumentDTO::fromEntity($document, $customerName);
    }
}
