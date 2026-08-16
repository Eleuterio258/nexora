<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\Presenter;

use E258Tech\Faturacao\Application\DTO\CustomerDTO;
use E258Tech\Faturacao\Application\DTO\ProductDTO;
use E258Tech\Faturacao\Application\DTO\SeriesDTO;
use E258Tech\Faturacao\Domain\ValueObject\CompanyInfo;

interface CreateDocumentPresenterInterface
{
    /**
     * @param CustomerDTO[] $customers
     * @param ProductDTO[] $products
     * @param SeriesDTO[] $series
     */
    public function present(array $customers, array $products, array $series, ?CompanyInfo $company = null, ?string $error = null, bool $partialOnly = false): mixed;
}
