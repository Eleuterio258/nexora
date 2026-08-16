<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Domain\Service;

use E258Tech\Faturacao\Domain\ValueObject\Money;

final readonly class DocumentTotals
{
    public function __construct(
        public Money $subtotal,
        public Money $discount,
        public Money $tax,
        public Money $total
    ) {
    }
}
