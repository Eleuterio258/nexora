<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Presentation\Controller;

use E258Tech\Faturacao\Application\Presenter\DashboardPresenterInterface;
use E258Tech\Faturacao\Application\UseCase\GetDashboardUseCase;

final class DashboardController
{
    public function __construct(
        private GetDashboardUseCase $useCase,
        private DashboardPresenterInterface $presenter
    ) {
    }

    public function __invoke(): void
    {
        $dto = $this->useCase->execute();
        echo $this->presenter->present($dto);
    }
}
