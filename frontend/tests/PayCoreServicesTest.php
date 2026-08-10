<?php

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';
require __DIR__ . '/../src/autoload.php';

use E258Tech\Core\Application;
use E258Tech\Core\ApplicationContainer;
use E258Tech\Model\Service\NexoraService;
use E258Tech\Routing\AdminRoutes;

$passed = 0;
$failed = 0;

function expect(bool $condition, string $message): void
{
    global $passed, $failed;
    if ($condition) {
        $passed++;
        echo "  ✓ $message\n";
    } else {
        $failed++;
        echo "  ✗ $message\n";
    }
}

echo "PayCore services smoke tests\n";
echo str_repeat('-', 40) . "\n";

// 1. Todas as classes PayCore existem e herdam de NexoraService
$services = [
    'E258Tech\\Model\\Service\\PayCore\\DashboardService',
    'E258Tech\\Model\\Service\\PayCore\\PosCashDrawerService',
    'E258Tech\\Model\\Service\\PayCore\\PosDiscountService',
    'E258Tech\\Model\\Service\\PayCore\\PosPaymentService',
    'E258Tech\\Model\\Service\\PayCore\\PosTransactionReportService',
    'E258Tech\\Model\\Service\\PayCore\\StockAdjustmentService',
    'E258Tech\\Model\\Service\\PayCore\\StockCategoryService',
    'E258Tech\\Model\\Service\\PayCore\\StockProductService',
    'E258Tech\\Model\\Service\\PayCore\\InvoicingService',
    'E258Tech\\Model\\Service\\PayCore\\CustomerService',
    'E258Tech\\Model\\Service\\PayCore\\FileUploadService',
    'E258Tech\\Model\\Service\\PayCore\\UserService',
    'E258Tech\\Model\\Service\\PayCore\\TerminalAdminService',
];

foreach ($services as $service) {
    expect(class_exists($service), "Classe $service existe");
    $reflection = new ReflectionClass($service);
    expect($reflection->isSubclassOf(NexoraService::class), "$service herda NexoraService");
}

// 2. Controllers API existem
$controllers = [
    'E258Tech\\Controller\\Admin\\Api\\ApiProxyController',
    'E258Tech\\Controller\\Admin\\Api\\PosPaymentApiController',
];

foreach ($controllers as $controller) {
    expect(class_exists($controller), "Controller $controller existe");
}

// 3. Rotas novas resolvem correctamente
$routes = new AdminRoutes();
$routeChecks = [
    ['pos_sessoes', [], '/nexora/pos/sessoes'],
    ['pos_sessa_abrir', [], '/nexora/pos/sessoes/abrir'],
    ['pos_sessa_detalhe', ['id' => 'abc'], '/nexora/pos/sessoes/ver?id=abc'],
    ['pos_sessa_fecho', ['id' => 'abc'], '/nexora/pos/sessoes/fechar?id=abc'],
    ['pos_relatorio_fecho', [], '/nexora/pos/relatorios/fecho'],
    ['pos_descontos', [], '/nexora/pos/descontos'],
    ['produto_detalhe', ['id' => 'abc'], '/nexora/produtos/ver?id=abc'],
    ['stock_alertas', [], '/nexora/stock/alertas'],
    ['fatura_detalhe', ['id' => 'abc'], '/nexora/faturacao/faturas/ver?id=abc'],
    ['cliente_detalhe', ['email' => 'a@b.c'], '/nexora/clientes/ver?email=a%40b.c'],
    ['utilizador_detalhe', ['id' => 'abc'], '/nexora/admin/utilizadores/ver?id=abc'],
    ['terminais_admin', [], '/nexora/admin/terminais'],
    ['terminal_admin_form', [], '/nexora/admin/terminais/form'],
];

foreach ($routeChecks as [$name, $params, $expected]) {
    $resolved = $routes->path($name, $params);
    expect($resolved === $expected, "Rota '$name' resolve para '$expected'");
}

// 4. Views novas existem
$views = [
    'src/View/templates/pages/dashboard.php',
    'src/View/templates/pages/pos_sessoes.php',
    'src/View/templates/pages/pos_sessa_abrir.php',
    'src/View/templates/pages/pos_sessa_fecho.php',
    'src/View/templates/pages/pos_sessa_detalhe.php',
    'src/View/templates/pages/pos_relatorio_fecho.php',
    'src/View/templates/pages/pos_descontos.php',
    'src/View/templates/pages/produto_categorias.php',
    'src/View/templates/pages/produtos.php',
    'src/View/templates/pages/produto_form.php',
    'src/View/templates/pages/produto_detalhe.php',
    'src/View/templates/pages/stock.php',
    'src/View/templates/pages/stock_alertas.php',
    'src/View/templates/pages/faturas.php',
    'src/View/templates/pages/fatura_detalhe.php',
    'src/View/templates/pages/clientes.php',
    'src/View/templates/pages/cliente_detalhe.php',
    'src/View/templates/pages/utilizadores.php',
    'src/View/templates/pages/utilizador_form.php',
    'src/View/templates/pages/utilizador_detalhe.php',
    'src/View/templates/pages/terminais_admin.php',
    'src/View/templates/pages/terminal_admin_form.php',
];

$base = __DIR__ . '/../';
foreach ($views as $view) {
    expect(file_exists($base . $view), "View $view existe");
}

// 5. ApplicationContainer expoe propriedades PayCore
$containerReflection = new ReflectionClass(ApplicationContainer::class);
$expectedProperties = [
    'payCoreDashboard',
    'payCoreCashDrawer',
    'payCoreDiscount',
    'payCorePayment',
    'payCoreTransactionReport',
    'payCoreStockCategory',
    'payCoreStockProduct',
    'payCoreStockAdjustment',
    'payCoreInvoicing',
    'payCoreCustomer',
    'payCoreFileUpload',
    'payCoreUser',
    'payCoreTerminalAdmin',
];

foreach ($expectedProperties as $property) {
    expect($containerReflection->hasProperty($property), "ApplicationContainer tem '\$$property'");
}

echo "\n";
echo "Resultado: $passed passaram, $failed falharam\n";

if ($failed > 0) {
    exit(1);
}
