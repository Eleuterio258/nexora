<?php

declare(strict_types=1);

namespace PHC\Infrastructure\Repository;

use PHC\Domain\Entity\InvoiceLayoutSettings;
use PHC\Domain\Repository\InvoiceLayoutSettingsRepositoryInterface;
use PHC\Infrastructure\Persistence\JsonDataStore;

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
