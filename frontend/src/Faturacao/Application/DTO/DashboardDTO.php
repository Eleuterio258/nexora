<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\DTO;

final readonly class DashboardDTO
{
    /**
     * @param DocumentDTO[] $pendingDocuments
     * @param DocumentDTO[] $recentDocuments
     */
    public function __construct(
        public string $emitted,
        public string $received,
        public string $outstanding,
        public string $overdue,
        public int $pendingCount,
        public int $overdueCount,
        public array $pendingDocuments,
        public array $recentDocuments,
        public string $todayFormatted
    ) {
    }
}
