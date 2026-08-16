<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Presentation\Controller;

use E258Tech\Faturacao\Application\DTO\ListDocumentsRequest;
use E258Tech\Faturacao\Application\UseCase\ExportDocumentsUseCase;

final class ExportController
{
    public function __construct(private ExportDocumentsUseCase $useCase)
    {
    }

    public function documents(): void
    {
        $filter = $_GET['filter'] ?? 'all';
        $search = $_GET['search'] ?? '';

        $csv = $this->useCase->execute(new ListDocumentsRequest($filter, $search));

        header('Content-Type: text/csv; charset=utf-8');
        header('Content-Disposition: attachment; filename="documentos-faturacao.csv"');
        echo $csv;
        exit;
    }
}
