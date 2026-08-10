<?php

declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Core\Application;
use E258Tech\Http\HttpResponse;
use E258Tech\Infrastructure\Nexora\ApiResponse;

/**
 * Proxy REST genérico para o backend Go.
 *
 * Encaminha pedidos de /nexora/api/v1/* para a API Go, autenticando com o
 * Bearer token do administrador em sessão. Permite criar endpoints compostos
 * (ex.: /nexora/api/v1/pos/sessoes) sem precisar de controller PHP individual.
 */
final class ApiProxyController
{
    /**
     * Processa um pedido proxy e termina a execução com a resposta JSON.
     */
    public static function handle(): never
    {
        $app = Application::bootstrap();

        if (!$app->session->isAuthenticated()) {
            self::sendJson(401, ['erro' => 'Nao autenticado']);
        }

        $uri = (string) parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH);
        $base = '/nexora/api/v1';
        if (!str_starts_with($uri, $base)) {
            self::sendJson(404, ['erro' => 'Rota proxy invalida']);
        }

        $path = substr($uri, strlen($base));
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        $query = $_GET;
        $payload = null;

        if (in_array($method, ['POST', 'PUT', 'PATCH', 'DELETE'], true)) {
            $input = file_get_contents('php://input');
            if ($input !== '' && $input !== false) {
                $decoded = json_decode($input, true);
                $payload = is_array($decoded) ? $decoded : null;
            }
        }

        try {
            $response = $app->nexora->request($method, '/api' . $path, $payload, $query);
        } catch (\Throwable $e) {
            error_log('Proxy API v1 erro: ' . $e->getMessage());
            self::sendJson(502, ['erro' => 'Erro de comunicacao com a API']);
        }

        self::sendHttpResponse($response);
    }

    /**
     * Envia uma resposta HttpResponse directamente ao cliente.
     */
    public static function sendHttpResponse(HttpResponse $response): never
    {
        $handled = ApiResponse::handle($response, true);
        self::sendJson($response->status, $response->body ?? ($handled['ok'] ? ['ok' => true] : ['erro' => $handled['error']]));
    }

    /**
     * Envia uma resposta JSON e termina a execução.
     *
     * @param array<string, mixed> $body
     */
    public static function sendJson(int $status, array $body): never
    {
        header('Content-Type: application/json');
        http_response_code($status);
        echo json_encode($body, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
        exit;
    }
}
