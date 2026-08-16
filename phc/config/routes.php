<?php

declare (strict_types = 1);

use PHC\Infrastructure\Auth\AuthSession;
use PHC\Presentation\Controller\AuthController;
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

$authSession = $container[AuthSession::class];

// Todas as rotas exigem sessão real contra a API, excepto o próprio login.
// A verificação usa o path pedido directamente porque acontece antes do
// Router (que só resolve rotas registadas, não decide acesso).
$requestPath = rtrim(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?: '/', '/') ?: '/';
if (!$authSession->isAuthenticated() && $requestPath !== '/login') {
    header('Location: /login');
    exit;
}

$router = new Router();

$authController = new AuthController(
    $container[\PHC\Infrastructure\Http\ApiClient::class],
    $authSession,
    $container['viewDir']
);
$router->get('/login', fn() => $authController->showLogin());
$router->post('/login', fn() => $authController->login());
$router->post('/logout', fn() => $authController->logout());

$router->get('/', fn() => (new DashboardController(
    $container[\PHC\Application\UseCase\GetDashboardUseCase::class],
    $container[\PHC\Application\Presenter\DashboardPresenterInterface::class]
))());

$documentController = new DocumentController(
    $container[\PHC\Application\UseCase\ListDocumentsUseCase::class],
    $container[\PHC\Application\UseCase\CreateDocumentUseCase::class],
    $container[\PHC\Application\UseCase\PreviewDocumentUseCase::class],
    $container[\PHC\Application\UseCase\GenerateDocumentPdfUseCase::class],
    // Cliente e Produto vêm da API (pedido explícito) — o
    // CreateDocumentUseCase continua a validar customer_id/product_id
    // contra o JSON local, por isso GRAVAR com um cliente ou artigo real
    // vai falhar com "não encontrado" até o Nível 3b (escrita via API)
    // avançar.
    $container[\PHC\Application\UseCase\ListCustomersUseCase::class],
    $container[\PHC\Application\UseCase\ListProductsUseCase::class],
    $container[\PHC\Application\UseCase\ListSeriesUseCase::class],
    $container[\PHC\Application\UseCase\GetInvoiceLayoutSettingsUseCase::class],
    $container[\PHC\Application\Presenter\DocumentListPresenterInterface::class],
    $container[\PHC\Application\Presenter\CreateDocumentPresenterInterface::class],
    $container[\PHC\Domain\Service\CompanyInfoProviderInterface::class]
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

try {
    $router->dispatch($_SERVER['REQUEST_METHOD'], $_SERVER['REQUEST_URI']);
} catch (\PHC\Infrastructure\Http\ApiException $e) {
    if (!$e->isUnauthorized()) {
        http_response_code(502);
        echo 'Erro ao comunicar com a API: ' . \PHC\Presentation\View\Html::e($e->getMessage());
        exit;
    }

    // access_token expirado ou inválido a meio da sessão: tenta renovar
    // com o refresh_token guardado, sem obrigar a reintroduzir a
    // password. Se o refresh também falhar (ex.: refresh_token expirado
    // ou sessão nunca chegou a ter um), força novo login. O parâmetro
    // _refreshed evita ciclo infinito caso o token novo continue a ser
    // rejeitado por outro motivo.
    $alreadyTriedRefresh = isset($_GET['_refreshed']);
    $refreshToken = $authSession->refreshToken();
    $renewed = false;
    if (!$alreadyTriedRefresh && $refreshToken !== null) {
        try {
            $apiClient = $container[\PHC\Infrastructure\Http\ApiClient::class];
            $response = $apiClient->post('/api/auth/refresh', ['refresh_token' => $refreshToken]);
            $newAccessToken = (string) ($response['access_token'] ?? '');
            if ($newAccessToken !== '') {
                $authSession->updateAccessToken($newAccessToken);
                $renewed = true;
            }
        } catch (\PHC\Infrastructure\Http\ApiException) {
            $renewed = false;
        }
    }

    if ($renewed) {
        $separator = str_contains($_SERVER['REQUEST_URI'], '?') ? '&' : '?';
        header('Location: ' . $_SERVER['REQUEST_URI'] . $separator . '_refreshed=1');
        exit;
    }

    $authSession->clear();
    header('Location: /login');
    exit;
}
