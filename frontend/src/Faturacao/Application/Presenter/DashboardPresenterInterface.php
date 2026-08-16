<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\Presenter;

use E258Tech\Faturacao\Application\DTO\DashboardDTO;

interface DashboardPresenterInterface
{
    public function present(DashboardDTO $dto): mixed;
}
