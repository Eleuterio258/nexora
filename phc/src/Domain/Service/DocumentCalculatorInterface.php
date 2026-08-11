<?php

declare(strict_types=1);

namespace PHC\Domain\Service;

use PHC\Domain\Entity\DocumentLine;
use PHC\Domain\ValueObject\Money;

interface DocumentCalculatorInterface
{
    /**
     * @param DocumentLine[] $lines
     */
    public function calculateTotals(array $lines): DocumentTotals;
}
