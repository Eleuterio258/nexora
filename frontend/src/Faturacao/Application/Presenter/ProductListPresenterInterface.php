<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\Presenter;

use E258Tech\Faturacao\Application\DTO\ProductDTO;

interface ProductListPresenterInterface
{
    /**
     * @param ProductDTO[] $products
     */
    public function present(array $products): mixed;
}
