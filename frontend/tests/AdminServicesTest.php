<?php
declare(strict_types=1);

use E258Tech\Model\Service\Authorization\AuthorizationAdminService;
use E258Tech\Model\Service\Company\CompanyAdminService;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\Purchase\PurchaseService;
use E258Tech\Model\Service\Recruitment\RecruitmentAdminService;
use E258Tech\Model\Service\School\SchoolService;
use E258Tech\Model\Service\Stock\StockService;
use E258Tech\Model\Service\Tax\AdvancedTaxService;
use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Http\HttpResponse;

require_once __DIR__ . '/../src/autoload.php';

final class FakeNexoraGateway implements NexoraGateway
{
    public array $calls = [];
    public array $responses = [];

    public function request(string $method, string $path, ?array $payload = null): HttpResponse
    {
        $this->calls[] = compact('method', 'path', 'payload');
        return array_shift($this->responses) ?? new HttpResponse(200, []);
    }
}

function expectSame(mixed $expected, mixed $actual, string $message): void
{
    if ($expected !== $actual) {
        throw new RuntimeException($message);
    }
}

function expectOperationException(callable $operation, string $message): void
{
    try {
        $operation();
    } catch (OperationException) {
        return;
    }
    throw new RuntimeException($message);
}

$gateway = new FakeNexoraGateway();
$gateway->responses = [
    new HttpResponse(200, ['estado' => 'aprovada']),
];
$recruitment = new RecruitmentAdminService($gateway);
expectOperationException(
    fn() => $recruitment->moveApplication(5, 'em_analise'),
    'Final applications must not return to an earlier state.'
);

$gateway = new FakeNexoraGateway();
$gateway->responses[] = new HttpResponse(201, ['id' => 9]);
$authorization = new AuthorizationAdminService($gateway);
$created = $authorization->saveRole(null, 'Gestor', null);
expectSame(9, $created['id'], 'Role creation must return the API id.');
expectSame('/api/auth/cargos', $gateway->calls[0]['path'], 'Role endpoint is invalid.');

$gateway = new FakeNexoraGateway();
$company = new CompanyAdminService($gateway);
expectOperationException(
    fn() => $company->createLicense(1, [
        'plano' => 'invalid',
        'inicia_em' => '2026-06-12',
        'expira_em' => null,
    ]),
    'Invalid plans must be rejected before calling the API.'
);
expectSame(0, count($gateway->calls), 'Invalid company data must not call the API.');

$gateway = new FakeNexoraGateway();
$gateway->responses[] = new HttpResponse(201, ['id' => 31]);
$purchases = new PurchaseService($gateway);
$created = $purchases->createDocument('order', ['numero' => 'OC-2026-001']);
expectSame(31, $created['id'], 'Purchase order creation must return the API id.');
expectSame('/api/purchase-orders', $gateway->calls[0]['path'], 'Purchase order endpoint is invalid.');

$gateway->responses[] = new HttpResponse(201, ['id' => 48]);
$item = $purchases->addItem('order', ['purchase_order_id' => 31, 'product_id' => 7]);
expectSame(48, $item['id'], 'Purchase item creation must return the API id.');
expectSame('/api/purchase-order-items', $gateway->calls[1]['path'], 'Purchase item endpoint is invalid.');

$gateway->responses[] = new HttpResponse(200, []);
$purchases->list('invoice', ['status' => 'pendente', 'supplier_id' => null]);
expectSame(
    '/api/purchase-invoices?status=pendente',
    $gateway->calls[2]['path'],
    'Purchase list filters must be appended to the endpoint.'
);

expectOperationException(
    fn() => $purchases->createDocument('invalid', ['numero' => 'X']),
    'Invalid purchase document types must be rejected.'
);
expectOperationException(
    fn() => $purchases->createDocument('request', ['numero' => '']),
    'Purchase documents without a number must be rejected.'
);
expectSame(3, count($gateway->calls), 'Invalid purchase data must not call the API.');

$gateway = new FakeNexoraGateway();
$gateway->responses = [
    new HttpResponse(201, ['id' => 4]),
    new HttpResponse(200, []),
    new HttpResponse(201, ['id' => 8]),
    new HttpResponse(200, ['media' => 15]),
];
$stock = new StockService($gateway);
$stock->execute('location.create', null, ['warehouse_id' => 3, 'codigo' => 'A-01']);
expectSame('/api/stock/warehouses/3/locations', $gateway->calls[0]['path'], 'Stock path parameters must be resolved.');
expectSame(['codigo' => 'A-01'], $gateway->calls[0]['payload'], 'Stock path parameters must not be forwarded in the payload.');

$taxes = new AdvancedTaxService($gateway);
$taxes->execute('return.submit', 12, []);
expectSame('/api/impostos/declaracoes/12/submeter', $gateway->calls[1]['path'], 'Tax return submission endpoint is invalid.');

$school = new SchoolService($gateway);
$school->execute('guardian.create', 25, ['nome' => 'Encarregado']);
expectSame('/api/escolar/students/25/guardians', $gateway->calls[2]['path'], 'School guardian endpoint is invalid.');
$school->execute('report.card.view', null, ['student_id' => 25, 'term_id' => 3]);
expectSame('/api/escolar/report-cards/25?term_id=3', $gateway->calls[3]['path'], 'School report card endpoint is invalid.');
expectSame(null, $gateway->calls[3]['payload'], 'GET filters must not be sent as a request body.');
expectOperationException(
    fn() => $school->execute('unknown.operation', null, []),
    'Unknown operational module actions must be rejected.'
);
expectSame(4, count($gateway->calls), 'Rejected operational module actions must not call the API.');

echo "Admin service tests passed.\n";
