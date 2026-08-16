<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Presentation\Presenter;

use E258Tech\Faturacao\Application\Presenter\CreateDocumentPresenterInterface;
use E258Tech\Faturacao\Domain\ValueObject\CompanyInfo;

final class HtmlCreateDocumentPresenter implements CreateDocumentPresenterInterface
{
    public function __construct(private string $viewDirectory)
    {
    }

    public function present(array $customers, array $products, array $series, ?CompanyInfo $company = null, ?string $error = null, bool $partialOnly = false): string
    {
        $title = 'Novo documento';
        $active = 'documents';

        ob_start();
        require $this->viewDirectory . '/documents/form.php';
        $content = ob_get_clean();

        // Pedido via fetch() do modal: só o fragmento, sem sidebar/topbar —
        // quem já está em /documents injecta isto directamente no DOM.
        if ($partialOnly) {
            return $content;
        }

        ob_start();
        require $this->viewDirectory . '/layout.php';
        return ob_get_clean();
    }
}
