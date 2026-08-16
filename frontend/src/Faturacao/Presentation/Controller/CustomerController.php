<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Presentation\Controller;

use E258Tech\Faturacao\Application\Presenter\CustomerListPresenterInterface;
use E258Tech\Faturacao\Application\UseCase\ListCustomersUseCase;

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
