<?php

declare(strict_types=1);

namespace PHC\Application\DTO;

use PHC\Domain\Entity\Series;

final readonly class SeriesDTO
{
    public function __construct(
        public int $id,
        public string $code,
        public string $type,
        public string $description,
        public int $year,
        public int $next,
        public bool $active
    ) {
    }

    public static function fromEntity(Series $series): self
    {
        return new self(
            $series->id(),
            $series->code(),
            $series->type()->value(),
            $series->description(),
            $series->year(),
            $series->next(),
            $series->isActive()
        );
    }
}
