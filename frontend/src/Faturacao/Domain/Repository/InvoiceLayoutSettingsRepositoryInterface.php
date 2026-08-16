<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Domain\Repository;

use E258Tech\Faturacao\Domain\Entity\InvoiceLayoutSettings;

interface InvoiceLayoutSettingsRepositoryInterface
{
    public function get(): InvoiceLayoutSettings;

    public function save(InvoiceLayoutSettings $settings): void;
}
