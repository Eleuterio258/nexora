<?php

declare(strict_types=1);

namespace PHC\Application\UseCase;

use PHC\Application\DTO\SeriesDTO;
use PHC\Domain\Repository\SeriesRepositoryInterface;

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
