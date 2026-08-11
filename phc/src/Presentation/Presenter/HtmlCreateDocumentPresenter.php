<?php

declare(strict_types=1);

namespace PHC\Presentation\Presenter;

use PHC\Application\Presenter\CreateDocumentPresenterInterface;

final class HtmlCreateDocumentPresenter implements CreateDocumentPresenterInterface
{
    public function __construct(private string $viewDirectory)
    {
    }

    public function present(array $customers, array $products, array $series, ?string $error = null): string
    {
        $title = 'Novo documento';
        $active = 'documents';

        ob_start();
        require $this->viewDirectory . '/documents/form.php';
        $content = ob_get_clean();

        ob_start();
        require $this->viewDirectory . '/layout.php';
        return ob_get_clean();
    }
}
