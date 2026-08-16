<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Presentation\Presenter;

use E258Tech\Faturacao\Application\DTO\InvoiceLayoutSettingsDTO;
use E258Tech\Faturacao\Application\Presenter\InvoiceLayoutPresenterInterface;

final class HtmlInvoiceLayoutPresenter implements InvoiceLayoutPresenterInterface
{
    public function __construct(private string $viewDirectory)
    {
    }

    public function present(InvoiceLayoutSettingsDTO $settings, ?string $error = null, bool $saved = false): string
    {
        $title = 'Layout da fatura';
        $active = 'settings-invoice-layout';

        ob_start();
        require $this->viewDirectory . '/settings/invoice-layout.php';
        $content = ob_get_clean();

        ob_start();
        require $this->viewDirectory . '/layout.php';
        return ob_get_clean();
    }
}
