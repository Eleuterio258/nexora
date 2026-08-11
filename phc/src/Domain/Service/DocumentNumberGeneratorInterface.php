<?php

declare(strict_types=1);

namespace PHC\Domain\Service;

use PHC\Domain\Entity\Series;
use PHC\Domain\ValueObject\DocumentNumber;

interface DocumentNumberGeneratorInterface
{
    public function generate(Series $series): DocumentNumber;
}
