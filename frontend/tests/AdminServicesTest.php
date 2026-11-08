<?php
declare(strict_types=1);

use E258Tech\Model\Service\Authorization\AuthorizationAdminService;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\School\SchoolService;
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

    public function uploadBinary(string $path, string $bytes, string $contentType): array
    {
        $this->calls[] = compact('method', 'path', 'bytes', 'contentType');
        return ['status' => 200, 'body' => []];
    }

    public function uploadMultipart(string $path, array $fields, array $files): array
    {
        $this->calls[] = compact('method', 'path', 'fields', 'files');
        return ['status' => 200, 'body' => []];
    }

    public function download(string $path): \E258Tech\Http\BinaryResponse
    {
        $this->calls[] = ['method' => 'GET', 'path' => $path];
        return new \E258Tech\Http\BinaryResponse(200, 'application/octet-stream', [], '');
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
$gateway->responses[] = new HttpResponse(201, ['id' => 9]);
$authorization = new AuthorizationAdminService($gateway);
$created = $authorization->saveRole(null, 'Gestor', null);
expectSame(9, $created['id'], 'Role creation must return the API id.');
expectSame('/api/auth/cargos', $gateway->calls[0]['path'], 'Role endpoint is invalid.');

$gateway = new FakeNexoraGateway();
$gateway->responses = [
    new HttpResponse(201, ['id' => 8]),
    new HttpResponse(200, ['media' => 15]),
];
$school = new SchoolService($gateway);
$school->execute('guardian.create', 25, ['nome' => 'Encarregado']);
expectSame('/api/escolar/students/25/guardians', $gateway->calls[0]['path'], 'School guardian endpoint is invalid.');
$school->execute('report.card.view', null, ['student_id' => 25, 'term_id' => 3]);
expectSame('/api/escolar/report-cards/25?term_id=3', $gateway->calls[1]['path'], 'School report card endpoint is invalid.');
expectSame(null, $gateway->calls[1]['payload'], 'GET filters must not be sent as a request body.');
expectOperationException(
    fn() => $school->execute('unknown.operation', null, []),
    'Unknown operational module actions must be rejected.'
);
expectSame(2, count($gateway->calls), 'Rejected operational module actions must not call the API.');

echo "Admin service tests passed.\n";
