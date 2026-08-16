<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\Service;

use E258Tech\Faturacao\Application\DTO\DocumentDTO;

interface DocumentPdfGeneratorInterface
{
    public function generate(DocumentDTO $document): string;
}
