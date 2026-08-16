<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Infrastructure\Service;

use E258Tech\Faturacao\Domain\Entity\Series;
use E258Tech\Faturacao\Domain\Service\DocumentNumberGeneratorInterface;
use E258Tech\Faturacao\Domain\ValueObject\DocumentNumber;

final class DocumentNumberGenerator implements DocumentNumberGeneratorInterface
{
    public function generate(Series $series): DocumentNumber
    {
        $sequential = $series->allocateNextNumber();
        return new DocumentNumber($series->type(), $series->code(), $series->year(), $sequential);
    }
}
