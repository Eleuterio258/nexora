<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Presentation\Presenter;

use E258Tech\Faturacao\Application\DTO\DashboardDTO;
use E258Tech\Faturacao\Application\Presenter\DashboardPresenterInterface;

final class HtmlDashboardPresenter implements DashboardPresenterInterface
{
    public function __construct(private string $viewDirectory)
    {
    }

    public function present(DashboardDTO $dto): string
    {
        $dashboard = $dto;
        $title = 'Visão geral';
        $active = 'dashboard';

        ob_start();
        require $this->viewDirectory . '/dashboard.php';
        $content = ob_get_clean();

        ob_start();
        require $this->viewDirectory . '/layout.php';
        return ob_get_clean();
    }
}
