<?php

declare(strict_types=1);

namespace PHC\Application\Presenter;

use PHC\Application\DTO\ProductDTO;

interface ProductListPresenterInterface
{
    /**
     * @param ProductDTO[] $products
     */
    public function present(array $products): mixed;
}
