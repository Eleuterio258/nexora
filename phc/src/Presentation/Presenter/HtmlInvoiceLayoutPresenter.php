<?php

declare(strict_types=1);

namespace PHC\Presentation\Presenter;

use PHC\Application\DTO\InvoiceLayoutSettingsDTO;
use PHC\Application\Presenter\InvoiceLayoutPresenterInterface;

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
