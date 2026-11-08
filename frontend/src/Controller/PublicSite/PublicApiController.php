<?php
declare(strict_types=1);

namespace E258Tech\Controller\PublicSite;

use E258Tech\Infrastructure\Nexora\NexoraClient;

final readonly class PublicApiController
{
    public function __construct(
        private NexoraClient $nexora
    ) {
    }

    /**
     * Proxy JSON para o backend Go, usado pelo login unificado
     * (POST /api/auth/login): reencaminha o corpo e o cabeçalho Authorization
     * tal como recebidos, sem exigir sessão PHP.
     */
    public function proxyJson(string $uri, string $method): never
    {
        $method = strtoupper($method);
        $payload = in_array($method, ['POST', 'PUT', 'PATCH'], true) ? $this->jsonBody() : null;
        $response = $this->nexora->callPublic($method, $uri, $payload, $method === 'GET' ? $_GET : []);
        header('Content-Type: application/json');
        http_response_code($response['status'] ?: 200);
        echo json_encode($response['body']);
        exit;
    }

    private function jsonBody(): ?array
    {
        $raw = file_get_contents('php://input');
        if ($raw === false || $raw === '') {
            return null;
        }
        $decoded = json_decode($raw, true);
        return is_array($decoded) ? $decoded : null;
    }
}
