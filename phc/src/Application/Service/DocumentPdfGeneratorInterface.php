<?php

declare(strict_types=1);

namespace PHC\Application\Service;

use PHC\Application\DTO\DocumentDTO;

interface DocumentPdfGeneratorInterface
{
    public function generate(DocumentDTO $document): string;
}
