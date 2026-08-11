<?php

declare(strict_types=1);

namespace PHC\Application\Presenter;

use PHC\Application\DTO\InvoiceLayoutSettingsDTO;

interface InvoiceLayoutPresenterInterface
{
    public function present(InvoiceLayoutSettingsDTO $settings, ?string $error = null, bool $saved = false): mixed;
}
