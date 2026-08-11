<?php

declare(strict_types=1);

namespace PHC\Tests\Domain\Service;

use PHPUnit\Framework\TestCase;
use PHC\Domain\Entity\DocumentLine;
use PHC\Domain\ValueObject\Money;
use PHC\Infrastructure\Service\DocumentCalculator;
use PHC\Domain\ValueObject\TaxRate;

final class DocumentCalculatorTest extends TestCase
{
    public function test_calculates_totals_for_single_line(): void
    {
        $calculator = new DocumentCalculator();
        $lines = [
            new DocumentLine(
                productId: 1,
                description: 'Consultoria',
                quantity: 10,
                unitPrice: Money::fromFloat(2500),
                discountPercent: 10,
                tax: new TaxRate(16)
            )
        ];

        $totals = $calculator->calculateTotals($lines);

        $this->assertSame(2500000, $totals->subtotal->cents());
        $this->assertSame(250000, $totals->discount->cents());
        $this->assertSame(360000, $totals->tax->cents());
        $this->assertSame(2610000, $totals->total->cents());
    }

    public function test_calculates_totals_for_multiple_lines(): void
    {
        $calculator = new DocumentCalculator();
        $lines = [
            new DocumentLine(1, 'A', 1, Money::fromFloat(1000), 0, new TaxRate(16)),
            new DocumentLine(2, 'B', 2, Money::fromFloat(500), 0, new TaxRate(0)),
        ];

        $totals = $calculator->calculateTotals($lines);

        $this->assertSame(200000, $totals->subtotal->cents());
        $this->assertSame(0, $totals->discount->cents());
        $this->assertSame(16000, $totals->tax->cents());
        $this->assertSame(216000, $totals->total->cents());
    }
}
