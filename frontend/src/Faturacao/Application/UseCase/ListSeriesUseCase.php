<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\UseCase;

use E258Tech\Faturacao\Application\DTO\SeriesDTO;
use E258Tech\Faturacao\Domain\Repository\SeriesRepositoryInterface;

final class ListSeriesUseCase
{
    public function __construct(private SeriesRepositoryInterface $series)
    {
    }

    public function execute(): array
    {
        return array_map(
            fn($series) => SeriesDTO::fromEntity($series),
            $this->series->findAll()
        );
    }
}
