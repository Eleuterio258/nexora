<?php

declare(strict_types=1);

namespace PHC\Application\Presenter;

use PHC\Application\DTO\SeriesDTO;

interface SeriesListPresenterInterface
{
    /**
     * @param SeriesDTO[] $series
     */
    public function present(array $series): mixed;
}
