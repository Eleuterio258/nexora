<?php

declare(strict_types=1);

namespace PHC\Application\UseCase;

use PHC\Application\DTO\InvoiceLayoutSettingsDTO;
use PHC\Domain\Repository\InvoiceLayoutSettingsRepositoryInterface;

final class GetInvoiceLayoutSettingsUseCase
{
    public function __construct(private InvoiceLayoutSettingsRepositoryInterface $settings)
    {
    }

    public function execute(): InvoiceLayoutSettingsDTO
    {
        return InvoiceLayoutSettingsDTO::fromEntity($this->settings->get());
    }
}
