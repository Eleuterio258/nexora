<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\Presenter;

use E258Tech\Faturacao\Application\DTO\SeriesDTO;

interface SeriesListPresenterInterface
{
    /**
     * @param SeriesDTO[] $series
     */
    public function present(array $series): mixed;
}
