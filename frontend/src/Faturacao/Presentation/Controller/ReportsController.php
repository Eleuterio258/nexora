<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Presentation\Controller;

use E258Tech\Faturacao\Application\Presenter\ReportsPresenterInterface;

final class ReportsController
{
    public function __construct(private ReportsPresenterInterface $presenter)
    {
    }

    public function __invoke(): void
    {
        echo $this->presenter->present();
    }
}
