<?php

declare(strict_types=1);

namespace PHC\Infrastructure\Service;

use Dompdf\Dompdf;
use Dompdf\Options;
use PHC\Application\DTO\DocumentDTO;
use PHC\Application\DTO\InvoiceLayoutSettingsDTO;
use PHC\Application\Service\DocumentPdfGeneratorInterface;
use PHC\Domain\Repository\InvoiceLayoutSettingsRepositoryInterface;

final class DompdfDocumentGenerator implements DocumentPdfGeneratorInterface
{
    public function __construct(
        private string $viewDirectory,
        private InvoiceLayoutSettingsRepositoryInterface $layoutSettings
    ) {
    }

    public function generate(DocumentDTO $document): string
    {
        $options = new Options();
        $options->set('isRemoteEnabled', false);
        $options->set('isHtml5ParserEnabled', true);
        $options->set('defaultFont', 'DejaVu Sans');

        $dompdf = new Dompdf($options);

        $doc = $document;
        $settings = InvoiceLayoutSettingsDTO::fromEntity($this->layoutSettings->get());
        ob_start();
        require $this->viewDirectory . '/documents/print.php';
        $html = ob_get_clean();

        $dompdf->loadHtml($html, 'UTF-8');
        $dompdf->setPaper('A4', 'portrait');
        $dompdf->render();

        return (string) $dompdf->output();
    }
}
