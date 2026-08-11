<?php

declare(strict_types=1);

namespace PHC\Presentation\Presenter;

use PHC\Application\Presenter\CustomerListPresenterInterface;

final class HtmlCustomerListPresenter implements CustomerListPresenterInterface
{
    public function __construct(private string $viewDirectory)
    {
    }

    public function present(array $customers): string
    {
        $title = 'Clientes';
        $active = 'customers';

        ob_start();
        require $this->viewDirectory . '/customers.php';
        $content = ob_get_clean();

        ob_start();
        require $this->viewDirectory . '/layout.php';
        return ob_get_clean();
    }
}
