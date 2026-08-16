<?php

declare (strict_types = 1);

namespace E258Tech\Faturacao\Presentation\Controller;

use E258Tech\Faturacao\Application\DTO\DocumentDTO;
use E258Tech\Faturacao\Application\DTO\DocumentLineDTO;
use E258Tech\Faturacao\Application\DTO\InvoiceLayoutSettingsDTO;
use E258Tech\Faturacao\Application\DTO\UpdateInvoiceLayoutSettingsRequest;
use E258Tech\Faturacao\Application\Presenter\InvoiceLayoutPresenterInterface;
use E258Tech\Faturacao\Application\UseCase\GetInvoiceLayoutSettingsUseCase;
use E258Tech\Faturacao\Application\UseCase\UpdateInvoiceLayoutSettingsUseCase;
use E258Tech\Faturacao\Domain\Entity\DocumentLine;
use E258Tech\Faturacao\Domain\Entity\InvoiceLayoutSettings;
use E258Tech\Faturacao\Domain\Service\DocumentCalculatorInterface;
use E258Tech\Faturacao\Domain\ValueObject\Money;
use E258Tech\Faturacao\Domain\ValueObject\TaxRate;

final class SettingsController
{
    public function __construct(
        private GetInvoiceLayoutSettingsUseCase $getUseCase,
        private UpdateInvoiceLayoutSettingsUseCase $updateUseCase,
        private DocumentCalculatorInterface $calculator,
        private InvoiceLayoutPresenterInterface $presenter
    ) {
    }

    public function invoiceLayout(): void
    {
        $settings = $this->getUseCase->execute();
        $saved    = isset($_GET['saved']);
        echo $this->presenter->present($settings, null, $saved);
    }

    public function updateInvoiceLayout(): void
    {
        $request = new UpdateInvoiceLayoutSettingsRequest(
            companyName: $_POST['company_name'] ?? '',
            companyTaxId: $_POST['company_tax_id'] ?? '',
            companyAddress: $_POST['company_address'] ?? '',
            companyEmail: $_POST['company_email'] ?? '',
            companyPhone: $_POST['company_phone'] ?? '',
            accentColor: $_POST['accent_color'] ?? '',
            footerText: $_POST['footer_text'] ?? '',
            showReference: isset($_POST['show_reference']),
            logoDataUri: $_POST['logo_data_uri'] ?? '',
            template: $_POST['template'] ?? 'classic',
            showDiscountColumn: isset($_POST['show_discount_column']),
            showTaxColumn: isset($_POST['show_tax_column'])
        );

        try {
            $this->updateUseCase->execute($request);
            header('Location: /settings/invoice-layout?saved=1');
            exit;
        } catch (\Throwable $e) {
            $settings = $this->getUseCase->execute();
            echo $this->presenter->present($settings, $e->getMessage());
        }
    }

    public function previewInvoiceLayout(): void
    {
        $settings = isset($_POST['company_name'])
            ? $this->settingsFromDraft($_POST)
            : $this->getUseCase->execute();

        $doc = $this->buildSampleDocument();

        header('Content-Type: text/html; charset=UTF-8');
        require __DIR__ . '/../../Presentation/View/documents/print.php';
    }

    private function settingsFromDraft(array $post): InvoiceLayoutSettingsDTO
    {
        $defaults    = InvoiceLayoutSettingsDTO::fromEntity(InvoiceLayoutSettings::defaults());
        $accentColor = $post['accent_color'] ?? '';
        if (! preg_match('/^#[0-9a-fA-F]{6}$/', $accentColor)) {
            $accentColor = $defaults->accentColor;
        }

        $template = $post['template'] ?? $defaults->template;
        if (! in_array($template, InvoiceLayoutSettings::VALID_TEMPLATES, true)) {
            $template = $defaults->template;
        }

        $logoDataUri = (string) ($post['logo_data_uri'] ?? '');
        if ($logoDataUri !== '' && ! preg_match('#^data:image/(png|jpe?g|gif|webp|svg\+xml);base64,#', $logoDataUri)) {
            $logoDataUri = '';
        }

        return new InvoiceLayoutSettingsDTO(
            trim((string) ($post['company_name'] ?? '')) !== '' ? $post['company_name'] : $defaults->companyName,
            $post['company_tax_id'] ?? '',
            $post['company_address'] ?? '',
            $post['company_email'] ?? '',
            $post['company_phone'] ?? '',
            $accentColor,
            trim((string) ($post['footer_text'] ?? '')) !== '' ? $post['footer_text'] : $defaults->footerText,
            isset($post['show_reference']),
            $logoDataUri,
            $template,
            isset($post['show_discount_column']),
            isset($post['show_tax_column'])
        );
    }

    private function buildSampleDocument(): DocumentDTO
    {
        $lines = [
            new DocumentLine(null, 'Consultoria e desenvolvimento', 1, Money::fromFloat(8000), 0, new TaxRate(16)),
            new DocumentLine(null, 'Licença de software (mensal)', 2, Money::fromFloat(1000), 10, new TaxRate(16)),
        ];
        $totals   = $this->calculator->calculateTotals($lines);
        $lineDTOs = array_map(fn(DocumentLine $line) => DocumentLineDTO::fromEntity($line), $lines);

        return new DocumentDTO(
            0,
            'FT',
            'Fatura',
            'FT A/2026-000001',
            0,
            'Cliente de exemplo, Lda.',
            date('Y-m-d'),
            date('Y-m-d', strtotime('+30 days')),
            $totals->subtotal->format(),
            $totals->discount->format(),
            $totals->tax->format(),
            $totals->total->format(),
            'pending',
            'Pendente',
            $lineDTOs,
            'Documento de exemplo para pré-visualização do layout.',
            'REF-EXEMPLO-001'
        );
    }
}
