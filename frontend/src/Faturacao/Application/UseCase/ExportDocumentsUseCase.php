<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Application\UseCase;

use E258Tech\Faturacao\Application\DTO\DocumentDTO;
use E258Tech\Faturacao\Application\DTO\ListDocumentsRequest;

final class ExportDocumentsUseCase
{
    public function __construct(private ListDocumentsUseCase $listUseCase)
    {
    }

    public function execute(ListDocumentsRequest $request): string
    {
        $documents = $this->listUseCase->execute($request);

        $output = fopen('php://temp', 'r+');
        fwrite($output, "\xEF\xBB\xBF");
        fputcsv($output, ['Número', 'Cliente', 'Emissão', 'Vencimento', 'Estado', 'Subtotal', 'IVA', 'Total'], ';');

        foreach ($documents as $doc) {
            /** @var DocumentDTO $doc */
            fputcsv($output, [
                $doc->number,
                $doc->customerName,
                $doc->date,
                $doc->dueDate,
                $doc->statusLabel,
                $this->parseMoney($doc->subtotal),
                $this->parseMoney($doc->tax),
                $this->parseMoney($doc->total),
            ], ';');
        }

        rewind($output);
        $csv = stream_get_contents($output);
        fclose($output);

        return $csv ?: '';
    }

    private function parseMoney(string $formatted): float
    {
        $clean = str_replace([' MT', ' '], '', $formatted);
        $clean = str_replace('.', '', $clean);
        $clean = str_replace(',', '.', $clean);
        return (float) $clean;
    }
}
