<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\UseCase;

use E258Tech\Faturacao\Application\DTO\InvoiceLayoutSettingsDTO;
use E258Tech\Faturacao\Domain\Repository\InvoiceLayoutSettingsRepositoryInterface;

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
