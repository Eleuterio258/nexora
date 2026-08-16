<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Presentation\Controller;

use E258Tech\Faturacao\Application\DTO\CreateDocumentLineRequest;
use E258Tech\Faturacao\Application\DTO\CreateDocumentRequest;
use E258Tech\Faturacao\Application\DTO\ListDocumentsRequest;
use E258Tech\Faturacao\Application\Presenter\CreateDocumentPresenterInterface;
use E258Tech\Faturacao\Application\Presenter\DocumentListPresenterInterface;
use E258Tech\Faturacao\Presentation\View\Html;
use E258Tech\Faturacao\Application\UseCase\CreateDocumentUseCase;
use E258Tech\Faturacao\Application\UseCase\ListDocumentsUseCase;
use E258Tech\Faturacao\Application\UseCase\GenerateDocumentPdfUseCase;
use E258Tech\Faturacao\Application\UseCase\GetInvoiceLayoutSettingsUseCase;
use E258Tech\Faturacao\Application\UseCase\ListCustomersUseCase;
use E258Tech\Faturacao\Application\UseCase\ListProductsUseCase;
use E258Tech\Faturacao\Application\UseCase\ListSeriesUseCase;
use E258Tech\Faturacao\Application\UseCase\PreviewDocumentUseCase;
use E258Tech\Faturacao\Domain\Service\CompanyInfoProviderInterface;

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
        private CreateDocumentPresenterInterface $createPresenter,
        private CompanyInfoProviderInterface $companyInfoProvider
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
        $company = $this->companyInfoProvider->getPrimary();

        echo $this->createPresenter->present($customers, $products, $series, $company, null, $this->isAjax());
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

        $ajax = $this->isAjax();

        try {
            $document = $this->createUseCase->execute($request);
            if ($ajax) {
                header('Content-Type: application/json');
                echo json_encode([
                    'success' => true,
                    'redirect' => '/documents',
                    'id' => $document->id,
                    'pdfUrl' => '/documents/pdf?id=' . $document->id,
                ]);
                return;
            }
            header('Location: /documents');
            exit;
        } catch (\Throwable $e) {
            if ($ajax) {
                header('Content-Type: application/json');
                http_response_code(422);
                echo json_encode(['success' => false, 'error' => $e->getMessage()]);
                return;
            }
            $customers = $this->listCustomersUseCase->execute();
            $products = $this->listProductsUseCase->execute();
            $series = $this->listSeriesUseCase->execute();
            $company = $this->companyInfoProvider->getPrimary();
            echo $this->createPresenter->present($customers, $products, $series, $company, $e->getMessage());
        }
    }

    /**
     * O JS do modal marca os seus pedidos com este header — permite servir
     * só o fragmento do formulário (sem layout) e responder em JSON ao
     * gravar, sem exigir um endpoint separado nem partir a navegação directa
     * para quem aceder a /documents/new sem JavaScript.
     */
    private function isAjax(): bool
    {
        return strtolower($_SERVER['HTTP_X_REQUESTED_WITH'] ?? '') === 'xmlhttprequest';
    }

    /**
     * @return \E258Tech\Faturacao\Application\DTO\CreateDocumentLineRequest[]
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
