<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Presentation\Controller;

use E258Tech\Faturacao\Application\Presenter\SeriesListPresenterInterface;
use E258Tech\Faturacao\Application\UseCase\ListSeriesUseCase;

final class SeriesController
{
    public function __construct(
        private ListSeriesUseCase $useCase,
        private SeriesListPresenterInterface $presenter
    ) {
    }

    public function __invoke(): void
    {
        $series = $this->useCase->execute();
        echo $this->presenter->present($series);
    }
}
