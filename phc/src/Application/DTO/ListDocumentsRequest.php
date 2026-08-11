<?php

declare(strict_types=1);

namespace PHC\Application\DTO;

final readonly class ListDocumentsRequest
{
    public function __construct(
        public string $filter = 'all',
        public string $search = ''
    ) {
    }
}
