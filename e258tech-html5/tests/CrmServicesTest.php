<?php
declare (strict_types = 1);

use E258Tech\Http\HttpResponse;
use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\Crm\LeadService;
use E258Tech\Model\Service\Crm\OpportunityService;

require_once __DIR__ . '/../src/autoload.php';

final class FakeGateway implements NexoraGateway
{
    public array $calls     = [];
    public array $responses = [];

    public function request(string $method, string $path, ?array $payload = null): HttpResponse
    {
        return $this->record($method, $path, $payload ?? []);
    }

    private function record(string $method, string $resource, array $payload = []): HttpResponse
    {
        $this->calls[] = compact('method', 'resource', 'payload');
        return array_shift($this->responses) ?? new HttpResponse(200, []);
    }
}

function assertSameValue(mixed $expected, mixed $actual, string $message): void
{
    if ($expected !== $actual) {
        throw new RuntimeException(sprintf(
            '%s Expected %s, got %s.',
            $message,
            var_export($expected, true),
            var_export($actual, true)
        ));
    }
}

function assertThrows(callable $operation, string $message): void
{
    try {
        $operation();
    } catch (OperationException) {
        return;
    }

    throw new RuntimeException($message);
}

$gateway              = new FakeGateway();
$gateway->responses[] = new HttpResponse(201, ['id' => 42]);
$leadService          = new LeadService($gateway);
$result               = $leadService->save(null, ['nome' => 'Empresa Teste']);

assertSameValue(42, $result['id'], 'Lead creation must return the API id.');
assertSameValue('POST', $gateway->calls[0]['method'], 'Lead creation must use POST.');
assertSameValue('/api/crm/leads', $gateway->calls[0]['resource'], 'Lead creation resource is invalid.');

assertThrows(
    fn() => $leadService->save(null, ['nome' => '']),
    'Lead without a name must be rejected.'
);

$gateway              = new FakeGateway();
$gateway->responses[] = new HttpResponse(200, ['estagio' => 'ganho']);
$opportunityService   = new OpportunityService($gateway);

assertThrows(
    fn() => $opportunityService->move(10, 'proposta'),
    'A closed opportunity must not move to another stage.'
);

echo "CRM service tests passed.\n";
