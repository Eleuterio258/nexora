<?php

declare(strict_types=1);

namespace PHC\Application\Presenter;

use PHC\Application\DTO\DocumentDTO;

interface DocumentListPresenterInterface
{
    /**
     * @param DocumentDTO[] $documents
     */
    public function present(array $documents, string $filter, string $search): mixed;
}
