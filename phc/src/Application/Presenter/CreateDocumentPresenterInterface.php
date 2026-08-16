<?php

declare(strict_types=1);

namespace PHC\Application\Presenter;

use PHC\Application\DTO\CustomerDTO;
use PHC\Application\DTO\ProductDTO;
use PHC\Application\DTO\SeriesDTO;
use PHC\Domain\ValueObject\CompanyInfo;

interface CreateDocumentPresenterInterface
{
    /**
     * @param CustomerDTO[] $customers
     * @param ProductDTO[] $products
     * @param SeriesDTO[] $series
     */
    public function present(array $customers, array $products, array $series, ?CompanyInfo $company = null, ?string $error = null, bool $partialOnly = false): mixed;
}
