<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\Presenter;

use E258Tech\Faturacao\Application\DTO\CustomerDTO;

interface CustomerListPresenterInterface
{
    /**
     * @param CustomerDTO[] $customers
     */
    public function present(array $customers): mixed;
}
