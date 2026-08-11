<?php

declare(strict_types=1);

use PHC\Presentation\Controller\CustomerController;
use PHC\Presentation\Controller\DashboardController;
use PHC\Presentation\Controller\DocumentController;
use PHC\Presentation\Controller\ExportController;
use PHC\Presentation\Controller\ProductController;
use PHC\Presentation\Controller\ReportsController;
use PHC\Presentation\Controller\SeriesController;
use PHC\Presentation\Controller\SettingsController;
use PHC\Presentation\Router;

/** @var array<string, mixed> $container */
$container = require __DIR__ . '/dependencies.php';

$router = new Router();

$router->get('/', fn() => (new DashboardController(
    $container[\PHC\Application\UseCase\GetDashboardUseCase::class],
    $container[\PHC\Application\Presenter\DashboardPresenterInterface::class]
))());

$documentController = new DocumentController(
    $container[\PHC\Application\UseCase\ListDocumentsUseCase::class],
    $container[\PHC\Application\UseCase\CreateDocumentUseCase::class],
    $container[\PHC\Application\UseCase\PreviewDocumentUseCase::class],
    $container[\PHC\Application\UseCase\GenerateDocumentPdfUseCase::class],
    $container[\PHC\Application\UseCase\ListCustomersUseCase::class],
    $container[\PHC\Application\UseCase\ListProductsUseCase::class],
    $container[\PHC\Application\UseCase\ListSeriesUseCase::class],
    $container[\PHC\Application\UseCase\GetInvoiceLayoutSettingsUseCase::class],
    $container[\PHC\Application\Presenter\DocumentListPresenterInterface::class],
    $container[\PHC\Application\Presenter\CreateDocumentPresenterInterface::class]
);

$router->get('/documents', fn() => $documentController->index());
$router->get('/documents/new', fn() => $documentController->create());
$router->post('/documents', fn() => $documentController->store());
$router->get('/documents/preview', fn() => $documentController->preview());
$router->get('/documents/pdf', fn() => $documentController->pdf());

$router->get('/customers', fn() => (new CustomerController(
    $container[\PHC\Application\UseCase\ListCustomersUseCase::class],
    $container[\PHC\Application\Presenter\CustomerListPresenterInterface::class]
))());

$router->get('/products', fn() => (new ProductController(
    $container[\PHC\Application\UseCase\ListProductsUseCase::class],
    $container[\PHC\Application\Presenter\ProductListPresenterInterface::class]
))());

$router->get('/series', fn() => (new SeriesController(
    $container[\PHC\Application\UseCase\ListSeriesUseCase::class],
    $container[\PHC\Application\Presenter\SeriesListPresenterInterface::class]
))());

$router->get('/reports', fn() => (new ReportsController(
    $container[\PHC\Application\Presenter\ReportsPresenterInterface::class]
))());

$settingsController = new SettingsController(
    $container[\PHC\Application\UseCase\GetInvoiceLayoutSettingsUseCase::class],
    $container[\PHC\Application\UseCase\UpdateInvoiceLayoutSettingsUseCase::class],
    $container[\PHC\Domain\Service\DocumentCalculatorInterface::class],
    $container[\PHC\Application\Presenter\InvoiceLayoutPresenterInterface::class]
);

$router->get('/settings/invoice-layout', fn() => $settingsController->invoiceLayout());
$router->post('/settings/invoice-layout', fn() => $settingsController->updateInvoiceLayout());
$router->get('/settings/invoice-layout/preview', fn() => $settingsController->previewInvoiceLayout());
$router->post('/settings/invoice-layout/preview', fn() => $settingsController->previewInvoiceLayout());

$router->get('/export/documents', fn() => (new ExportController(
    $container[\PHC\Application\UseCase\ExportDocumentsUseCase::class]
))->documents());

$router->dispatch($_SERVER['REQUEST_METHOD'], $_SERVER['REQUEST_URI']);
