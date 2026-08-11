<?php

declare(strict_types=1);

namespace PHC\Presentation\Presenter;

use PHC\Application\Presenter\SeriesListPresenterInterface;

final class HtmlSeriesListPresenter implements SeriesListPresenterInterface
{
    public function __construct(private string $viewDirectory)
    {
    }

    public function present(array $series): string
    {
        $title = 'Séries documentais';
        $active = 'series';

        ob_start();
        require $this->viewDirectory . '/series.php';
        $content = ob_get_clean();

        ob_start();
        require $this->viewDirectory . '/layout.php';
        return ob_get_clean();
    }
}
