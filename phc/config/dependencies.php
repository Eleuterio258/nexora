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
use PHC\Domain\Service\CompanyInfoProviderInterface;
use PHC\Domain\Service\DocumentCalculatorInterface;
use PHC\Infrastructure\Auth\AuthSession;
use PHC\Infrastructure\Http\ApiClient;
use PHC\Infrastructure\Http\HttpCompanyInfoProvider;
use PHC\Infrastructure\Persistence\JsonDataStore;
use PHC\Infrastructure\Repository\HttpCustomerRepository;
use PHC\Infrastructure\Repository\HttpDocumentRepository;
use PHC\Infrastructure\Repository\HttpProductRepository;
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

// Carregador de .env minimalista — sem dependência do composer, só para
// NEXORA_API_BASE_URL por agora. Não pisa variáveis já definidas no
// ambiente real (shell, vhost), só preenche o que faltar.
$envFile = $baseDir . '/.env';
if (is_file($envFile)) {
    foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
        $line = trim($line);
        if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) {
            continue;
        }
        [$envKey, $envValue] = explode('=', $line, 2);
        $envKey = trim($envKey);
        if (getenv($envKey) === false) {
            putenv($envKey . '=' . trim($envValue));
        }
    }
}

$dataStore = new JsonDataStore($dataDir);

// Repositórios locais (JSON) — usados apenas pelo fluxo de criação de
// documentos, que ainda não fala com a API (ver CreateDocumentUseCase).
$customerRepository      = new JsonCustomerRepository($dataStore);
$productRepository       = new JsonProductRepository($dataStore);
$seriesRepository        = new JsonSeriesRepository($dataStore);
$documentRepository      = new JsonDocumentRepository($dataStore);
$invoiceLayoutRepository = new JsonInvoiceLayoutSettingsRepository($dataStore);

// Autenticação e cliente HTTP contra a API real do backend Nexora.
$authSession = new AuthSession();
$apiBaseUrl  = getenv('NEXORA_API_BASE_URL') ?: 'http://localhost:8080';
$apiClient   = new ApiClient($apiBaseUrl, $authSession);

// Repositórios HTTP (só leitura) — usados pelas páginas de consulta
// (dashboard, documentos, clientes, produtos), que agora mostram dados
// reais do tenant autenticado em vez do JSON local de demonstração.
$httpCustomerRepository = new HttpCustomerRepository($apiClient);
$httpProductRepository  = new HttpProductRepository($apiClient);
$httpDocumentRepository = new HttpDocumentRepository($apiClient);
$companyInfoProvider    = new HttpCompanyInfoProvider($apiClient);

$calculator      = new DocumentCalculator();
$numberGenerator = new DocumentNumberGenerator();

$getDashboardUseCase   = new GetDashboardUseCase($httpDocumentRepository, $httpCustomerRepository);
$listDocumentsUseCase  = new ListDocumentsUseCase($httpDocumentRepository, $httpCustomerRepository);
// Continua 100% local: gera id e número do documento no cliente antes de
// gravar, o que a API real não permite (o servidor é que atribui ambos).
// O criador de clientes/produtos/séries usados aqui tem de ser o mesmo
// repositório local, senão a validação de existência falha sempre.
$createDocumentUseCase = new CreateDocumentUseCase(
    $documentRepository,
    $customerRepository,
    $productRepository,
    $seriesRepository,
    $calculator,
    $numberGenerator
);
$previewDocumentUseCase        = new PreviewDocumentUseCase($httpDocumentRepository, $httpCustomerRepository);
$pdfGenerator                  = new DompdfDocumentGenerator($viewDir, $invoiceLayoutRepository);
$generateDocumentPdfUseCase    = new GenerateDocumentPdfUseCase($previewDocumentUseCase, $pdfGenerator);
$listCustomersUseCase          = new ListCustomersUseCase($httpCustomerRepository);
$listProductsUseCase           = new ListProductsUseCase($httpProductRepository);
// Variantes locais só para o formulário "Nova venda", que tem de escolher
// cliente/produto do mesmo universo (JSON) que o CreateDocumentUseCase vai
// validar ao gravar — ver nota acima.
$listCustomersUseCaseForDocumentForm = new ListCustomersUseCase($customerRepository);
$listProductsUseCaseForDocumentForm  = new ListProductsUseCase($productRepository);
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
    AuthSession::class                         => $authSession,
    ApiClient::class                           => $apiClient,
    CompanyInfoProviderInterface::class        => $companyInfoProvider,
    'viewDir'                                  => $viewDir,
    'ListCustomersUseCase.forDocumentForm'     => $listCustomersUseCaseForDocumentForm,
    'ListProductsUseCase.forDocumentForm'      => $listProductsUseCaseForDocumentForm,
];
