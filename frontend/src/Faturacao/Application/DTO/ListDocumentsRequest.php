<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\DTO;

final readonly class ListDocumentsRequest
{
    public function __construct(
        public string $filter = 'all',
        public string $search = ''
    ) {
    }
}
