<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\UseCase;

use E258Tech\Faturacao\Application\Service\DocumentPdfGeneratorInterface;

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
