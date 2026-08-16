<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\UseCase;

use DateTimeImmutable;
use InvalidArgumentException;
use E258Tech\Faturacao\Application\DTO\CreateDocumentRequest;
use E258Tech\Faturacao\Application\DTO\DocumentDTO;
use E258Tech\Faturacao\Domain\Entity\Document;
use E258Tech\Faturacao\Domain\Entity\DocumentLine;
use E258Tech\Faturacao\Domain\Repository\CustomerRepositoryInterface;
use E258Tech\Faturacao\Domain\Repository\DocumentRepositoryInterface;
use E258Tech\Faturacao\Domain\Repository\ProductRepositoryInterface;
use E258Tech\Faturacao\Domain\Repository\SeriesRepositoryInterface;
use E258Tech\Faturacao\Domain\Service\DocumentCalculatorInterface;
use E258Tech\Faturacao\Domain\Service\DocumentNumberGeneratorInterface;
use E258Tech\Faturacao\Domain\ValueObject\DocumentStatus;
use E258Tech\Faturacao\Domain\ValueObject\Money;
use E258Tech\Faturacao\Domain\ValueObject\TaxRate;

final class CreateDocumentUseCase
{
    public function __construct(
        private DocumentRepositoryInterface $documents,
        private CustomerRepositoryInterface $customers,
        private ProductRepositoryInterface $products,
        private SeriesRepositoryInterface $series,
        private DocumentCalculatorInterface $calculator,
        private DocumentNumberGeneratorInterface $numberGenerator
    ) {
    }

    public function execute(CreateDocumentRequest $request): DocumentDTO
    {
        $customer = $this->customers->findById($request->customerId);
        if ($customer === null) {
            throw new InvalidArgumentException('Cliente não encontrado.');
        }

        $series = $this->series->findById($request->seriesId);
        if ($series === null || !$series->isActive()) {
            throw new InvalidArgumentException('Série documental inválida ou inativa.');
        }

        $expectedType = new \E258Tech\Faturacao\Domain\ValueObject\DocumentType($request->type);
        if (!$series->type()->equals($expectedType)) {
            throw new InvalidArgumentException('A série não corresponde ao tipo de documento.');
        }

        $lines = $this->buildLines($request->lines);
        if (count($lines) === 0) {
            throw new InvalidArgumentException('Adicione pelo menos uma linha ao documento.');
        }

        $totals = $this->calculator->calculateTotals($lines);
        $number = $this->numberGenerator->generate($series);

        $statusValue = $request->draft ? 'draft' : ($series->type()->isPaidOnIssue() ? 'paid' : 'pending');
        $status = new DocumentStatus($statusValue);

        $document = new Document(
            $this->documents->nextId(),
            $number,
            $customer->id(),
            new DateTimeImmutable($request->date),
            new DateTimeImmutable($request->dueDate),
            $totals->subtotal,
            $totals->discount,
            $totals->tax,
            $totals->total,
            $status,
            $lines,
            $request->notes,
            $request->reference
        );

        $this->documents->save($document);

        if ($status->value() === 'pending') {
            $customer->increaseBalance($totals->total);
            $this->customers->save($customer);
        }

        $this->series->save($series);

        return DocumentDTO::fromEntity($document, $customer->name());
    }

    /**
     * @param \E258Tech\Faturacao\Application\DTO\CreateDocumentLineRequest[] $lineRequests
     * @return DocumentLine[]
     */
    private function buildLines(array $lineRequests): array
    {
        $lines = [];
        foreach ($lineRequests as $lineRequest) {
            if ($lineRequest->quantity <= 0) {
                continue;
            }

            $description = $lineRequest->description;
            if ($lineRequest->productId !== null && $description === '') {
                $product = $this->products->findById($lineRequest->productId);
                $description = $product?->name() ?? '';
            }

            $lines[] = new DocumentLine(
                $lineRequest->productId,
                $description,
                $lineRequest->quantity,
                Money::fromFloat($lineRequest->price),
                $lineRequest->discount,
                new TaxRate($lineRequest->tax)
            );
        }

        return $lines;
    }
}
