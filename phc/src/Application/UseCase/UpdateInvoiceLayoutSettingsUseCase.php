<?php

declare(strict_types=1);

namespace PHC\Application\UseCase;

use InvalidArgumentException;
use PHC\Application\DTO\InvoiceLayoutSettingsDTO;
use PHC\Application\DTO\UpdateInvoiceLayoutSettingsRequest;
use PHC\Domain\Entity\InvoiceLayoutSettings;
use PHC\Domain\Repository\InvoiceLayoutSettingsRepositoryInterface;

final class UpdateInvoiceLayoutSettingsUseCase
{
    private const MAX_LOGO_LENGTH = 400_000;

    public function __construct(private InvoiceLayoutSettingsRepositoryInterface $settings)
    {
    }

    public function execute(UpdateInvoiceLayoutSettingsRequest $request): InvoiceLayoutSettingsDTO
    {
        if (trim($request->companyName) === '') {
            throw new InvalidArgumentException('O nome da empresa é obrigatório.');
        }

        if (!preg_match('/^#[0-9a-fA-F]{6}$/', $request->accentColor)) {
            throw new InvalidArgumentException('A cor de destaque deve ser um código hexadecimal válido (ex.: #008b83).');
        }

        if (!in_array($request->template, InvoiceLayoutSettings::VALID_TEMPLATES, true)) {
            throw new InvalidArgumentException('Modelo de documento inválido.');
        }

        $logoDataUri = trim($request->logoDataUri);
        if ($logoDataUri !== '') {
            if (!preg_match('#^data:image/(png|jpe?g|gif|webp|svg\+xml);base64,#', $logoDataUri)) {
                throw new InvalidArgumentException('O logótipo deve ser uma imagem (PNG, JPG, GIF, WEBP ou SVG).');
            }
            if (strlen($logoDataUri) > self::MAX_LOGO_LENGTH) {
                throw new InvalidArgumentException('O logótipo é demasiado grande. Escolha uma imagem até ~300 KB.');
            }
        }

        $settings = new InvoiceLayoutSettings(
            trim($request->companyName),
            trim($request->companyTaxId),
            trim($request->companyAddress),
            trim($request->companyEmail),
            trim($request->companyPhone),
            $request->accentColor,
            trim($request->footerText),
            $request->showReference,
            $logoDataUri,
            $request->template,
            $request->showDiscountColumn,
            $request->showTaxColumn
        );

        $this->settings->save($settings);

        return InvoiceLayoutSettingsDTO::fromEntity($settings);
    }
}
