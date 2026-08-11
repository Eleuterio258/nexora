<?php

declare(strict_types=1);

namespace PHC\Tests\Domain\ValueObject;

use InvalidArgumentException;
use PHPUnit\Framework\TestCase;
use PHC\Domain\ValueObject\Money;

final class MoneyTest extends TestCase
{
    public function test_cannot_be_negative(): void
    {
        $this->expectException(InvalidArgumentException::class);
        new Money(-100);
    }

    public function test_adds_same_currency(): void
    {
        $a = Money::fromFloat(10.50);
        $b = Money::fromFloat(20.25);

        $this->assertSame(3075, $a->add($b)->cents());
    }

    public function test_formats_portuguese(): void
    {
        $money = Money::fromFloat(1234567.89);
        $this->assertSame('1.234.567,89 MT', $money->format());
    }
}
