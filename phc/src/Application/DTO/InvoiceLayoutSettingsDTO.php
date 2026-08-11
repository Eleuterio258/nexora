<?php

declare(strict_types=1);

namespace PHC\Application\DTO;

use PHC\Domain\Entity\InvoiceLayoutSettings;

final readonly class InvoiceLayoutSettingsDTO
{
    public function __construct(
        public string $companyName,
        public string $companyTaxId,
        public string $companyAddress,
        public string $companyEmail,
        public string $companyPhone,
        public string $accentColor,
        public string $footerText,
        public bool $showReference,
        public string $logoDataUri,
        public string $template,
        public bool $showDiscountColumn,
        public bool $showTaxColumn
    ) {
    }

    public static function fromEntity(InvoiceLayoutSettings $settings): self
    {
        return new self(
            $settings->companyName(),
            $settings->companyTaxId(),
            $settings->companyAddress(),
            $settings->companyEmail(),
            $settings->companyPhone(),
            $settings->accentColor(),
            $settings->footerText(),
            $settings->showReference(),
            $settings->logoDataUri(),
            $settings->template(),
            $settings->showDiscountColumn(),
            $settings->showTaxColumn()
        );
    }
}
