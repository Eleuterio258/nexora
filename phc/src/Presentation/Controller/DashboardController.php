<?php

declare(strict_types=1);

namespace PHC\Presentation\Controller;

use PHC\Application\Presenter\DashboardPresenterInterface;
use PHC\Application\UseCase\GetDashboardUseCase;

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
