<?php

declare(strict_types=1);

namespace PHC\Application\UseCase;

use PHC\Application\Service\DocumentPdfGeneratorInterface;

final class GenerateDocumentPdfUseCase
{
    public function __construct(
        private PreviewDocumentUseCase $previewUseCase,
        private DocumentPdfGeneratorInterface $pdfGenerator
    ) {
    }

    public function execute(int $documentId): string
    {
        $document = $this->previewUseCase->execute($documentId);
        return $this->pdfGenerator->generate($document);
    }
}
