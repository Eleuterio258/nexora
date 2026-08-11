<?php

declare(strict_types=1);

namespace PHC\Application\Presenter;

use PHC\Application\DTO\CustomerDTO;
use PHC\Application\DTO\ProductDTO;
use PHC\Application\DTO\SeriesDTO;

interface CreateDocumentPresenterInterface
{
    /**
     * @param CustomerDTO[] $customers
     * @param ProductDTO[] $products
     * @param SeriesDTO[] $series
     */
    public function present(array $customers, array $products, array $series, ?string $error = null): mixed;
}
