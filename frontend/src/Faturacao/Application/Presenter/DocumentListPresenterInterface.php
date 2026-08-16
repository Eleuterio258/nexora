<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\Presenter;

use E258Tech\Faturacao\Application\DTO\DocumentDTO;

interface DocumentListPresenterInterface
{
    /**
     * @param DocumentDTO[] $documents
     */
    public function present(array $documents, string $filter, string $search): mixed;
}
