<?php

declare(strict_types=1);

namespace PHC\Presentation\Controller;

use PHC\Application\DTO\CreateDocumentLineRequest;
use PHC\Application\DTO\CreateDocumentRequest;
use PHC\Application\DTO\ListDocumentsRequest;
use PHC\Application\Presenter\CreateDocumentPresenterInterface;
use PHC\Application\Presenter\DocumentListPresenterInterface;
use PHC\Presentation\View\Html;
use PHC\Application\UseCase\CreateDocumentUseCase;
use PHC\Application\UseCase\ListDocumentsUseCase;
use PHC\Application\UseCase\GenerateDocumentPdfUseCase;
use PHC\Application\UseCase\GetInvoiceLayoutSettingsUseCase;
use PHC\Application\UseCase\ListCustomersUseCase;
use PHC\Application\UseCase\ListProductsUseCase;
use PHC\Application\UseCase\ListSeriesUseCase;
use PHC\Application\UseCase\PreviewDocumentUseCase;

final class DocumentController
{
    public function __construct(
        private ListDocumentsUseCase $listUseCase,
        private CreateDocumentUseCase $createUseCase,
        private PreviewDocumentUseCase $previewUseCase,
        private GenerateDocumentPdfUseCase $pdfUseCase,
        private ListCustomersUseCase $listCustomersUseCase,
        private ListProductsUseCase $listProductsUseCase,
        private ListSeriesUseCase $listSeriesUseCase,
        private GetInvoiceLayoutSettingsUseCase $layoutSettingsUseCase,
        private DocumentListPresenterInterface $listPresenter,
        private CreateDocumentPresenterInterface $createPresenter
    ) {
    }

    public function index(): void
    {
        $filter = $_GET['filter'] ?? 'all';
        $search = $_GET['search'] ?? '';

        $documents = $this->listUseCase->execute(new ListDocumentsRequest($filter, $search));
        echo $this->listPresenter->present($documents, $filter, $search);
    }

    public function create(): void
    {
        $customers = $this->listCustomersUseCase->execute();
        $products = $this->listProductsUseCase->execute();
        $series = $this->listSeriesUseCase->execute();

        echo $this->createPresenter->present($customers, $products, $series);
    }

    public function preview(): void
    {
        $id = (int) ($_GET['id'] ?? 0);
        if ($id <= 0) {
            http_response_code(404);
            echo 'Documento não encontrado.';
            return;
        }

        try {
            $document = $this->previewUseCase->execute($id);
            $doc = $document;
            $settings = $this->layoutSettingsUseCase->execute();
            require __DIR__ . '/../../Presentation/View/documents/print.php';
        } catch (\Throwable $e) {
            http_response_code(404);
            echo Html::e($e->getMessage());
        }
    }

    public function pdf(): void
    {
        $id = (int) ($_GET['id'] ?? 0);
        if ($id <= 0) {
            http_response_code(404);
            echo 'Documento não encontrado.';
            return;
        }

        try {
            $pdf = $this->pdfUseCase->execute($id);
            header('Content-Type: application/pdf');
            header('Content-Disposition: attachment; filename="' . $id . '.pdf"');
            echo $pdf;
            exit;
        } catch (\Throwable $e) {
            http_response_code(500);
            echo 'Erro ao gerar PDF: ' . Html::e($e->getMessage());
        }
    }

    public function store(): void
    {
        $lineRequests = $this->buildLineRequests($_POST['lines'] ?? []);

        $request = new CreateDocumentRequest(
            type: $_POST['type'] ?? 'FT',
            seriesId: (int) ($_POST['series_id'] ?? 0),
            customerId: (int) ($_POST['customer_id'] ?? 0),
            date: $_POST['date'] ?? date('Y-m-d'),
            dueDate: $_POST['due_date'] ?? date('Y-m-d', strtotime('+30 days')),
            lines: $lineRequests,
            notes: $_POST['notes'] ?? '',
            reference: $_POST['reference'] ?? '',
            draft: isset($_POST['draft'])
        );

        try {
            $this->createUseCase->execute($request);
            header('Location: /documents');
            exit;
        } catch (\Throwable $e) {
            $customers = $this->listCustomersUseCase->execute();
            $products = $this->listProductsUseCase->execute();
            $series = $this->listSeriesUseCase->execute();
            echo $this->createPresenter->present($customers, $products, $series, $e->getMessage());
        }
    }

    /**
     * @return \PHC\Application\DTO\CreateDocumentLineRequest[]
     */
    private function buildLineRequests(array $lines): array
    {
        $requests = [];
        $count = count($lines['product_id'] ?? []);

        for ($i = 0; $i < $count; $i++) {
            $productId = $lines['product_id'][$i] ?? null;
            $requests[] = new CreateDocumentLineRequest(
                productId: $productId !== '' && $productId !== null ? (int) $productId : null,
                description: $lines['description'][$i] ?? '',
                quantity: (float) ($lines['quantity'][$i] ?? 1),
                price: (float) ($lines['price'][$i] ?? 0),
                discount: (float) ($lines['discount'][$i] ?? 0),
                tax: (int) ($lines['tax'][$i] ?? 16)
            );
        }

        return $requests;
    }
}
