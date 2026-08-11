<?php

declare(strict_types=1);

namespace PHC\Infrastructure\Service;

use PHC\Domain\Entity\DocumentLine;
use PHC\Domain\Service\DocumentCalculatorInterface;
use PHC\Domain\Service\DocumentTotals;
use PHC\Domain\ValueObject\Money;

final class DocumentCalculator implements DocumentCalculatorInterface
{
    public function calculateTotals(array $lines): DocumentTotals
    {
        $subtotal = new Money(0);
        $discount = new Money(0);
        $tax = new Money(0);
        $total = new Money(0);

        foreach ($lines as $line) {
            $subtotal = $subtotal->add($line->gross());
            $discount = $discount->add($line->discount());
            $tax = $tax->add($line->taxAmount());
            $total = $total->add($line->total());
        }

        return new DocumentTotals($subtotal, $discount, $tax, $total);
    }
}
