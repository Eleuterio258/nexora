<?php

declare(strict_types=1);

namespace PHC\Tests\Domain;

use PHC\Domain\Entity\DocumentLine;
use PHC\Domain\ValueObject\Money;
use PHC\Domain\ValueObject\TaxRate;
use PHC\Infrastructure\Service\DocumentCalculator;
use PHPUnit\Framework\TestCase;

final class DocumentCalculatorTest extends TestCase
{
    public function testCalculatesSubtotalDiscountTaxAndTotalInCents(): void
    {
        $line = new DocumentLine(
            1,
            'Consultoria',
            2,
            Money::fromFloat(1_000),
            10,
            new TaxRate(16)
        );

        $totals = (new DocumentCalculator())->calculateTotals([$line]);

        self::assertSame(200_000, $totals->subtotal->cents());
        self::assertSame(20_000, $totals->discount->cents());
        self::assertSame(28_800, $totals->tax->cents());
        self::assertSame(208_800, $totals->total->cents());
    }

    public function testAggregatesLinesWithDifferentTaxRates(): void
    {
        $lines = [
            new DocumentLine(1, 'Produto', 1, Money::fromFloat(100), 0, new TaxRate(16)),
            new DocumentLine(2, 'Isento', 2, Money::fromFloat(50), 0, new TaxRate(0)),
        ];

        $totals = (new DocumentCalculator())->calculateTotals($lines);

        self::assertSame(20_000, $totals->subtotal->cents());
        self::assertSame(1_600, $totals->tax->cents());
        self::assertSame(21_600, $totals->total->cents());
    }
}
