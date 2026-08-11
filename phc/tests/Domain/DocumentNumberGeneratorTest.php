<?php

declare(strict_types=1);

namespace PHC\Tests\Domain;

use PHC\Domain\Entity\Series;
use PHC\Domain\ValueObject\DocumentType;
use PHC\Infrastructure\Service\DocumentNumberGenerator;
use PHPUnit\Framework\TestCase;

final class DocumentNumberGeneratorTest extends TestCase
{
    public function testGeneratesSequentialDocumentNumbers(): void
    {
        $series = new Series(1, 'A', new DocumentType('FT'), 'Faturas 2026', 2026, 48);
        $generator = new DocumentNumberGenerator();

        self::assertSame('FT A/2026-000048', (string) $generator->generate($series));
        self::assertSame('FT A/2026-000049', (string) $generator->generate($series));
        self::assertSame(50, $series->next());
    }
}
