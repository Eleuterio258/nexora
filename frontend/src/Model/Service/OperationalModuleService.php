<?php
declare(strict_types=1);

namespace E258Tech\Model\Service;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;

abstract class OperationalModuleService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    public function execute(string $operation, ?int $id, array $payload): array
    {
        $definition = $this->operations()[$operation] ?? null;
        if (!is_array($definition)) {
            throw new OperationException('Operacao invalida para este modulo.');
        }

        $path = (string) $definition['path'];
        if (str_contains($path, '{id}')) {
            if (!$id || $id < 1) {
                throw new OperationException('O identificador do registo e obrigatorio.');
            }
            $path = str_replace('{id}', (string) $id, $path);
        }

        preg_match_all('/\{([a-z_]+)\}/', $path, $matches);
        foreach ($matches[1] ?? [] as $parameter) {
            $value = trim((string) ($payload[$parameter] ?? ''));
            if ($value === '') {
                throw new OperationException("O parametro $parameter e obrigatorio.");
            }
            $path = str_replace('{' . $parameter . '}', rawurlencode($value), $path);
            unset($payload[$parameter]);
        }

        $method = (string) $definition['method'];
        if ($method === 'GET' && $payload) {
            $path .= (str_contains($path, '?') ? '&' : '?') . http_build_query($payload);
            $payload = [];
        }

        $response = $this->gateway->request($method, $path, $payload ?: null);
        $this->ensureSuccess($response, 'Erro ao executar a operacao.');

        return [
            'ok' => true,
            'msg' => (string) ($definition['message'] ?? 'Operacao concluida com sucesso.'),
            'id' => $response->body['id'] ?? $id,
            'data' => $response->body,
        ];
    }

    abstract protected function operations(): array;
}
