<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\Presenter;

use E258Tech\Faturacao\Application\DTO\InvoiceLayoutSettingsDTO;

interface InvoiceLayoutPresenterInterface
{
    public function present(InvoiceLayoutSettingsDTO $settings, ?string $error = null, bool $saved = false): mixed;
}
