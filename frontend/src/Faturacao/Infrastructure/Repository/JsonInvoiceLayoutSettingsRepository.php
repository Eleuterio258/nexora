<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Infrastructure\Repository;

use E258Tech\Faturacao\Domain\Entity\InvoiceLayoutSettings;
use E258Tech\Faturacao\Domain\Repository\InvoiceLayoutSettingsRepositoryInterface;
use E258Tech\Faturacao\Infrastructure\Persistence\JsonDataStore;

final class JsonInvoiceLayoutSettingsRepository implements InvoiceLayoutSettingsRepositoryInterface
{
    private const FILE = 'invoice_layout';

    public function __construct(private JsonDataStore $store)
    {
    }

    public function get(): InvoiceLayoutSettings
    {
        return InvoiceLayoutSettings::fromArray($this->store->read(self::FILE));
    }

    public function save(InvoiceLayoutSettings $settings): void
    {
        $this->store->write(self::FILE, $settings->toArray());
    }
}
