<?php

declare(strict_types=1);

namespace PHC\Application\Presenter;

use PHC\Application\DTO\CustomerDTO;

interface CustomerListPresenterInterface
{
    /**
     * @param CustomerDTO[] $customers
     */
    public function present(array $customers): mixed;
}
