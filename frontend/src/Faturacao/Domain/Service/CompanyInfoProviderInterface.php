<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Domain\Service;

use E258Tech\Faturacao\Domain\ValueObject\CompanyInfo;

interface CompanyInfoProviderInterface
{
    public function getPrimary(): ?CompanyInfo;
}
