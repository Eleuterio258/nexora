<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Presentation\Presenter;

use E258Tech\Faturacao\Application\Presenter\ReportsPresenterInterface;

final class HtmlReportsPresenter implements ReportsPresenterInterface
{
    public function __construct(private string $viewDirectory)
    {
    }

    public function present(): string
    {
        $title = 'Relatórios';
        $active = 'reports';

        ob_start();
        require $this->viewDirectory . '/reports.php';
        $content = ob_get_clean();

        ob_start();
        require $this->viewDirectory . '/layout.php';
        return ob_get_clean();
    }
}
