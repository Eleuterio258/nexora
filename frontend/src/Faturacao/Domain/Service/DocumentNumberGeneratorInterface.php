<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Domain\Service;

use E258Tech\Faturacao\Domain\Entity\Series;
use E258Tech\Faturacao\Domain\ValueObject\DocumentNumber;

interface DocumentNumberGeneratorInterface
{
    public function generate(Series $series): DocumentNumber;
}
