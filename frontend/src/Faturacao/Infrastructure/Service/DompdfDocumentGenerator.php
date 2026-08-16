<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Infrastructure\Service;

use Dompdf\Dompdf;
use Dompdf\Options;
use E258Tech\Faturacao\Application\DTO\DocumentDTO;
use E258Tech\Faturacao\Application\DTO\InvoiceLayoutSettingsDTO;
use E258Tech\Faturacao\Application\Service\DocumentPdfGeneratorInterface;
use E258Tech\Faturacao\Domain\Repository\InvoiceLayoutSettingsRepositoryInterface;

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
