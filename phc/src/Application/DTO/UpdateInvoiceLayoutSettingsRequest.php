<?php

declare(strict_types=1);

namespace PHC\Application\DTO;

final readonly class UpdateInvoiceLayoutSettingsRequest
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
}
