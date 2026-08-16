<?php

declare(strict_types=1);

namespace PHC\Domain\Service;

use PHC\Domain\ValueObject\CompanyInfo;

interface CompanyInfoProviderInterface
{
    public function getPrimary(): ?CompanyInfo;
}
