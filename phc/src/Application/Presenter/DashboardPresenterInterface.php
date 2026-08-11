<?php

declare(strict_types=1);

namespace PHC\Application\Presenter;

use PHC\Application\DTO\DashboardDTO;

interface DashboardPresenterInterface
{
    public function present(DashboardDTO $dto): mixed;
}
