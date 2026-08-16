<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Infrastructure\Service;

use E258Tech\Faturacao\Domain\Entity\DocumentLine;
use E258Tech\Faturacao\Domain\Service\DocumentCalculatorInterface;
use E258Tech\Faturacao\Domain\Service\DocumentTotals;
use E258Tech\Faturacao\Domain\ValueObject\Money;

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
