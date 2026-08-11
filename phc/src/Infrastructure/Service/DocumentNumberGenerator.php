<?php

declare(strict_types=1);

namespace PHC\Infrastructure\Service;

use PHC\Domain\Entity\Series;
use PHC\Domain\Service\DocumentNumberGeneratorInterface;
use PHC\Domain\ValueObject\DocumentNumber;

final class DocumentNumberGenerator implements DocumentNumberGeneratorInterface
{
    public function generate(Series $series): DocumentNumber
    {
        $sequential = $series->allocateNextNumber();
        return new DocumentNumber($series->type(), $series->code(), $series->year(), $sequential);
    }
}
