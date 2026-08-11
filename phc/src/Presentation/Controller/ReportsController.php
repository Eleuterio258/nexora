<?php

declare(strict_types=1);

namespace PHC\Presentation\Controller;

use PHC\Application\Presenter\ReportsPresenterInterface;

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
