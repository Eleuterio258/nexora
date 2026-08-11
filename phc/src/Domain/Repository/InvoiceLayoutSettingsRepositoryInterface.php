<?php

declare(strict_types=1);

namespace PHC\Domain\Repository;

use PHC\Domain\Entity\InvoiceLayoutSettings;

interface InvoiceLayoutSettingsRepositoryInterface
{
    public function get(): InvoiceLayoutSettings;

    public function save(InvoiceLayoutSettings $settings): void;
}
