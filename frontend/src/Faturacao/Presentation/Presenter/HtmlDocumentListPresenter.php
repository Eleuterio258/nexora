<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Presentation\Presenter;

use E258Tech\Faturacao\Application\Presenter\DocumentListPresenterInterface;

final class HtmlDocumentListPresenter implements DocumentListPresenterInterface
{
    public function __construct(private string $viewDirectory)
    {
    }

    public function present(array $documents, string $filter, string $search): string
    {
        $title = 'Documentos';
        $active = 'documents';

        ob_start();
        require $this->viewDirectory . '/documents/list.php';
        $content = ob_get_clean();

        ob_start();
        require $this->viewDirectory . '/layout.php';
        return ob_get_clean();
    }
}
