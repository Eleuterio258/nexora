<?php

declare(strict_types=1);

namespace PHC\Domain\Service;

use PHC\Domain\ValueObject\Money;

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
