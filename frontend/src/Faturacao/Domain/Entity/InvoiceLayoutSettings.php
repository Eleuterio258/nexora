<?php

declare (strict_types = 1);

namespace E258Tech\Faturacao\Domain\Entity;

final class InvoiceLayoutSettings
{
    public const VALID_TEMPLATES = ['classic', 'modern', 'compact'];

    public function __construct(
        private string $companyName,
        private string $companyTaxId,
        private string $companyAddress,
        private string $companyEmail,
        private string $companyPhone,
        private string $accentColor,
        private string $footerText,
        private bool $showReference,
        private string $logoDataUri,
        private string $template,
        private bool $showDiscountColumn,
        private bool $showTaxColumn
    ) {
    }

    public static function defaults(): self
    {
        return new self(
            'Nexora, Lda.',
            'NUIT 400123456',
            'Maputo, Moçambique',
            'financeiro@nexora.co.mz',
            '+258 84 000 0000',
            '#008b83',
            'Documento emitido pelo protótipo PHC Faturação · Este documento não tem valor fiscal.',
            false,
            '',
            'classic',
            true,
            true
        );
    }

    public function companyName(): string
    {
        return $this->companyName;
    }

    public function companyTaxId(): string
    {
        return $this->companyTaxId;
    }

    public function companyAddress(): string
    {
        return $this->companyAddress;
    }

    public function companyEmail(): string
    {
        return $this->companyEmail;
    }

    public function companyPhone(): string
    {
        return $this->companyPhone;
    }

    public function accentColor(): string
    {
        return $this->accentColor;
    }

    public function footerText(): string
    {
        return $this->footerText;
    }

    public function showReference(): bool
    {
        return $this->showReference;
    }

    public function logoDataUri(): string
    {
        return $this->logoDataUri;
    }

    public function template(): string
    {
        return $this->template;
    }

    public function showDiscountColumn(): bool
    {
        return $this->showDiscountColumn;
    }

    public function showTaxColumn(): bool
    {
        return $this->showTaxColumn;
    }

    public function toArray(): array
    {
        return [
            'company_name'         => $this->companyName,
            'company_tax_id'       => $this->companyTaxId,
            'company_address'      => $this->companyAddress,
            'company_email'        => $this->companyEmail,
            'company_phone'        => $this->companyPhone,
            'accent_color'         => $this->accentColor,
            'footer_text'          => $this->footerText,
            'show_reference'       => $this->showReference,
            'logo_data_uri'        => $this->logoDataUri,
            'template'             => $this->template,
            'show_discount_column' => $this->showDiscountColumn,
            'show_tax_column'      => $this->showTaxColumn,
        ];
    }

    public static function fromArray(array $data): self
    {
        $defaults = self::defaults();

        return new self(
            (string) ($data['company_name'] ?? $defaults->companyName()),
            (string) ($data['company_tax_id'] ?? $defaults->companyTaxId()),
            (string) ($data['company_address'] ?? $defaults->companyAddress()),
            (string) ($data['company_email'] ?? $defaults->companyEmail()),
            (string) ($data['company_phone'] ?? $defaults->companyPhone()),
            (string) ($data['accent_color'] ?? $defaults->accentColor()),
            (string) ($data['footer_text'] ?? $defaults->footerText()),
            (bool) ($data['show_reference'] ?? $defaults->showReference()),
            (string) ($data['logo_data_uri'] ?? $defaults->logoDataUri()),
            in_array($data['template'] ?? null, self::VALID_TEMPLATES, true) ? $data['template'] : $defaults->template(),
            (bool) ($data['show_discount_column'] ?? $defaults->showDiscountColumn()),
            (bool) ($data['show_tax_column'] ?? $defaults->showTaxColumn())
        );
    }
}
