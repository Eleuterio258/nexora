<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\UseCase;

use DateTimeImmutable;
use E258Tech\Faturacao\Application\DTO\CustomerDTO;
use E258Tech\Faturacao\Application\DTO\DashboardDTO;
use E258Tech\Faturacao\Application\DTO\DocumentDTO;
use E258Tech\Faturacao\Domain\Entity\Document;
use E258Tech\Faturacao\Domain\Repository\CustomerRepositoryInterface;
use E258Tech\Faturacao\Domain\Repository\DocumentRepositoryInterface;
use E258Tech\Faturacao\Domain\ValueObject\DocumentStatus;

final class GetDashboardUseCase
{
    public function __construct(
        private DocumentRepositoryInterface $documents,
        private CustomerRepositoryInterface $customers
    ) {
    }

    public function execute(): DashboardDTO
    {
        $all = $this->documents->findAll();

        $emittedCents = 0;
        $receivedCents = 0;
        $outstandingCents = 0;
        $overdueCents = 0;
        $pendingCount = 0;
        $overdueCount = 0;
        $today = new DateTimeImmutable();

        foreach ($all as $doc) {
            if ($doc->status()->value() === 'draft' || $doc->status()->value() === 'cancelled') {
                continue;
            }

            $total = $doc->total()->cents();
            $emittedCents += $total;

            if ($doc->status()->value() === 'paid') {
                $receivedCents += $total;
            } else {
                $outstandingCents += $total;
                $pendingCount++;
                if ($doc->dueDate() < $today) {
                    $overdueCents += $total;
                    $overdueCount++;
                }
            }
        }

        $customerMap = [];
        foreach ($this->customers->findAll() as $c) {
            $customerMap[$c->id()] = CustomerDTO::fromEntity($c);
        }

        $pending = array_filter($all, fn(Document $d) => in_array($d->status()->value(), ['pending', 'overdue'], true));
        $pending = array_slice(array_values($pending), 0, 4);

        $recent = array_slice($all, 0, 5);

        return new DashboardDTO(
            $this->formatMoney($emittedCents),
            $this->formatMoney($receivedCents),
            $this->formatMoney($outstandingCents),
            $this->formatMoney($overdueCents),
            $pendingCount,
            $overdueCount,
            array_map(fn(Document $d) => DocumentDTO::fromEntity($d, $customerMap[$d->customerId()]->name ?? 'Consumidor final'), $pending),
            array_map(fn(Document $d) => DocumentDTO::fromEntity($d, $customerMap[$d->customerId()]->name ?? 'Consumidor final'), $recent),
            $this->formatDatePt($today)
        );
    }

    private function formatMoney(int $cents): string
    {
        return number_format($cents / 100, 2, ',', '.') . ' MT';
    }

    private function formatDatePt(DateTimeImmutable $date): string
    {
        $days = ['Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado'];
        $months = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];

        return $days[(int) $date->format('w')] . ', ' . (int) $date->format('j') . ' de ' . $months[(int) $date->format('n') - 1];
    }
}
