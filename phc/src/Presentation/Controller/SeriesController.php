<?php

declare(strict_types=1);

namespace PHC\Presentation\Controller;

use PHC\Application\Presenter\SeriesListPresenterInterface;
use PHC\Application\UseCase\ListSeriesUseCase;

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
