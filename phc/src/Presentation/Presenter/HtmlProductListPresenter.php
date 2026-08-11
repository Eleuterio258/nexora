<?php

declare(strict_types=1);

namespace PHC\Presentation\Presenter;

use PHC\Application\Presenter\ProductListPresenterInterface;

final class HtmlProductListPresenter implements ProductListPresenterInterface
{
    public function __construct(private string $viewDirectory)
    {
    }

    public function present(array $products): string
    {
        $title = 'Artigos e serviços';
        $active = 'products';

        ob_start();
        require $this->viewDirectory . '/products.php';
        $content = ob_get_clean();

        ob_start();
        require $this->viewDirectory . '/layout.php';
        return ob_get_clean();
    }
}
