<?php

declare (strict_types = 1);

use PHC\Application\Presenter\CreateDocumentPresenterInterface;
use PHC\Application\Presenter\CustomerListPresenterInterface;
use PHC\Application\Presenter\DashboardPresenterInterface;
use PHC\Application\Presenter\DocumentListPresenterInterface;
use PHC\Application\Presenter\InvoiceLayoutPresenterInterface;
use PHC\Application\Presenter\ProductListPresenterInterface;
use PHC\Application\Presenter\ReportsPresenterInterface;
use PHC\Application\Presenter\SeriesListPresenterInterface;
use PHC\Application\Service\DocumentPdfGeneratorInterface;
use PHC\Application\UseCase\CreateDocumentUseCase;
use PHC\Application\UseCase\ExportDocumentsUseCase;
use PHC\Application\UseCase\GenerateDocumentPdfUseCase;
use PHC\Application\UseCase\GetDashboardUseCase;
use PHC\Application\UseCase\GetInvoiceLayoutSettingsUseCase;
use PHC\Application\UseCase\ListCustomersUseCase;
use PHC\Application\UseCase\ListDocumentsUseCase;
use PHC\Application\UseCase\ListProductsUseCase;
use PHC\Application\UseCase\ListSeriesUseCase;
use PHC\Application\UseCase\PreviewDocumentUseCase;
use PHC\Application\UseCase\UpdateInvoiceLayoutSettingsUseCase;
use PHC\Domain\Repository\InvoiceLayoutSettingsRepositoryInterface;
use PHC\Domain\Service\DocumentCalculatorInterface;
use PHC\Infrastructure\Persistence\JsonDataStore;
use PHC\Infrastructure\Repository\JsonCustomerRepository;
use PHC\Infrastructure\Repository\JsonDocumentRepository;
use PHC\Infrastructure\Repository\JsonInvoiceLayoutSettingsRepository;
use PHC\Infrastructure\Repository\JsonProductRepository;
use PHC\Infrastructure\Repository\JsonSeriesRepository;
use PHC\Infrastructure\Service\DocumentCalculator;
use PHC\Infrastructure\Service\DocumentNumberGenerator;
use PHC\Infrastructure\Service\DompdfDocumentGenerator;
use PHC\Presentation\Presenter\HtmlCreateDocumentPresenter;
use PHC\Presentation\Presenter\HtmlCustomerListPresenter;
use PHC\Presentation\Presenter\HtmlDashboardPresenter;
use PHC\Presentation\Presenter\HtmlDocumentListPresenter;
use PHC\Presentation\Presenter\HtmlInvoiceLayoutPresenter;
use PHC\Presentation\Presenter\HtmlProductListPresenter;
use PHC\Presentation\Presenter\HtmlReportsPresenter;
use PHC\Presentation\Presenter\HtmlSeriesListPresenter;

require_once __DIR__ . '/../vendor/autoload.php';

$baseDir = dirname(__DIR__);
$dataDir = $baseDir . '/data';
$viewDir = $baseDir . '/src/Presentation/View';

$dataStore = new JsonDataStore($dataDir);

$customerRepository      = new JsonCustomerRepository($dataStore);
$productRepository       = new JsonProductRepository($dataStore);
$seriesRepository        = new JsonSeriesRepository($dataStore);
$documentRepository      = new JsonDocumentRepository($dataStore);
$invoiceLayoutRepository = new JsonInvoiceLayoutSettingsRepository($dataStore);

$calculator      = new DocumentCalculator();
$numberGenerator = new DocumentNumberGenerator();

$getDashboardUseCase   = new GetDashboardUseCase($documentRepository, $customerRepository);
$listDocumentsUseCase  = new ListDocumentsUseCase($documentRepository, $customerRepository);
$createDocumentUseCase = new CreateDocumentUseCase(
    $documentRepository,
    $customerRepository,
    $productRepository,
    $seriesRepository,
    $calculator,
    $numberGenerator
);
$previewDocumentUseCase        = new PreviewDocumentUseCase($documentRepository, $customerRepository);
$pdfGenerator                  = new DompdfDocumentGenerator($viewDir, $invoiceLayoutRepository);
$generateDocumentPdfUseCase    = new GenerateDocumentPdfUseCase($previewDocumentUseCase, $pdfGenerator);
$listCustomersUseCase          = new ListCustomersUseCase($customerRepository);
$listProductsUseCase           = new ListProductsUseCase($productRepository);
$listSeriesUseCase             = new ListSeriesUseCase($seriesRepository);
$exportDocumentsUseCase        = new ExportDocumentsUseCase($listDocumentsUseCase);
$getInvoiceLayoutSettingsUseCase    = new GetInvoiceLayoutSettingsUseCase($invoiceLayoutRepository);
$updateInvoiceLayoutSettingsUseCase = new UpdateInvoiceLayoutSettingsUseCase($invoiceLayoutRepository);

$dashboardPresenter      = new HtmlDashboardPresenter($viewDir);
$documentListPresenter   = new HtmlDocumentListPresenter($viewDir);
$createDocumentPresenter = new HtmlCreateDocumentPresenter($viewDir);
$customerListPresenter   = new HtmlCustomerListPresenter($viewDir);
$productListPresenter    = new HtmlProductListPresenter($viewDir);
$reportsPresenter        = new HtmlReportsPresenter($viewDir);
$seriesListPresenter     = new HtmlSeriesListPresenter($viewDir);
$invoiceLayoutPresenter  = new HtmlInvoiceLayoutPresenter($viewDir);

return [
    GetDashboardUseCase::class                 => $getDashboardUseCase,
    ListDocumentsUseCase::class                => $listDocumentsUseCase,
    CreateDocumentUseCase::class                => $createDocumentUseCase,
    ListCustomersUseCase::class                => $listCustomersUseCase,
    ListProductsUseCase::class                 => $listProductsUseCase,
    ListSeriesUseCase::class                   => $listSeriesUseCase,
    ExportDocumentsUseCase::class              => $exportDocumentsUseCase,
    PreviewDocumentUseCase::class              => $previewDocumentUseCase,
    GenerateDocumentPdfUseCase::class          => $generateDocumentPdfUseCase,
    GetInvoiceLayoutSettingsUseCase::class     => $getInvoiceLayoutSettingsUseCase,
    UpdateInvoiceLayoutSettingsUseCase::class  => $updateInvoiceLayoutSettingsUseCase,
    DocumentPdfGeneratorInterface::class       => $pdfGenerator,
    DocumentCalculatorInterface::class         => $calculator,
    InvoiceLayoutSettingsRepositoryInterface::class => $invoiceLayoutRepository,
    DashboardPresenterInterface::class         => $dashboardPresenter,
    DocumentListPresenterInterface::class      => $documentListPresenter,
    CreateDocumentPresenterInterface::class    => $createDocumentPresenter,
    CustomerListPresenterInterface::class      => $customerListPresenter,
    ProductListPresenterInterface::class       => $productListPresenter,
    ReportsPresenterInterface::class           => $reportsPresenter,
    SeriesListPresenterInterface::class        => $seriesListPresenter,
    InvoiceLayoutPresenterInterface::class     => $invoiceLayoutPresenter,
];
