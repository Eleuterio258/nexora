<?php

declare(strict_types=1);

namespace PHC\Presentation\Controller;

use PHC\Application\Presenter\CustomerListPresenterInterface;
use PHC\Application\UseCase\ListCustomersUseCase;

final class CustomerController
{
    public function __construct(
        private ListCustomersUseCase $useCase,
        private CustomerListPresenterInterface $presenter
    ) {
    }

    public function __invoke(): void
    {
        $customers = $this->useCase->execute();
        echo $this->presenter->present($customers);
    }
}
