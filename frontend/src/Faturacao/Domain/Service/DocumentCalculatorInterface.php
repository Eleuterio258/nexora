<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Domain\Service;

use E258Tech\Faturacao\Domain\Entity\DocumentLine;
use E258Tech\Faturacao\Domain\ValueObject\Money;

interface DocumentCalculatorInterface
{
    /**
     * @param DocumentLine[] $lines
     */
    public function calculateTotals(array $lines): DocumentTotals;
}
