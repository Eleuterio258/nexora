<?php

declare(strict_types=1);

namespace E258Tech\Infrastructure\Nexora;

use E258Tech\Http\HttpResponse;

/**
 * Helper para normalizar respostas da API Nexora no frontend.
 *
 * Converte códigos HTTP em mensagens amigáveis e opcionalmente regista
 * flash messages na sessão PHP para serem mostradas na UI.
 */
final class ApiResponse
{
    /**
     * Processa uma HttpResponse e devolve um array normalizado.
     *
     * @return array{status: int, body: array<string, mixed>|null, message: string|null, ok: bool}
     */
    public static function handle(HttpResponse $response, bool $flashOnError = false): array
    {
        $status = $response->status;
        $body = $response->body ?? [];
        $message = self::extractMessage($body, $status);

        $result = [
            'status' => $status,
            'body' => is_array($body) ? $body : null,
            'message' => $message,
            'ok' => $status >= 200 && $status < 300,
        ];

        if (!$result['ok'] && $flashOnError) {
            self::flash($status, $message);
        }

        return $result;
    }

    /**
     * Devolve a mensagem de erro apropriada para um código HTTP.
     */
    public static function errorMessage(int $status, ?string $backendMessage = null): string
    {
        if ($backendMessage !== null && $backendMessage !== '') {
            return $backendMessage;
        }

        return match ($status) {
            400 => 'Pedido inválido. Verifica os dados enviados.',
            401 => 'Sessão expirada. Por favor, inicia sessão novamente.',
            402 => 'Licença da aplicação expirada ou suspensa. Contacta o administrador.',
            403 => 'Sem permissão para realizar esta operação.',
            404 => 'Recurso não encontrado.',
            409 => 'Conflito de dados. O registo pode já existir.',
            422 => 'Dados inválidos. Verifica os campos do formulário.',
            429 => 'Muitos pedidos. Tenta novamente dentro de momentos.',
            500 => 'Erro interno do servidor. Tenta novamente mais tarde.',
            502 => 'Serviço indisponível. O backend não respondeu.',
            503 => 'Serviço temporariamente indisponível. Tenta novamente mais tarde.',
            default => 'Ocorreu um erro inesperado. Tenta novamente.',
        };
    }

    /**
     * Regista uma flash message na sessão PHP.
     */
    public static function flash(int $status, ?string $message = null): void
    {
        if (session_status() !== PHP_SESSION_ACTIVE) {
            return;
        }

        $type = $status >= 200 && $status < 300 ? 'success' : 'error';
        if ($status === 402 || $status === 403) {
            $type = 'warning';
        }

        $_SESSION['_flash_messages'][] = [
            'type' => $type,
            'message' => $message ?? self::errorMessage($status),
        ];
    }

    /**
     * Lê e limpa as flash messages da sessão PHP.
     *
     * @return list<array{type: string, message: string}>
     */
    public static function consumeFlashMessages(): array
    {
        if (session_status() !== PHP_SESSION_ACTIVE) {
            return [];
        }

        $messages = $_SESSION['_flash_messages'] ?? [];
        unset($_SESSION['_flash_messages']);

        return is_array($messages) ? $messages : [];
    }

    /**
     * Extrai a mensagem do corpo da resposta ou devolve uma mensagem padrão.
     *
     * @param array<string, mixed> $body
     */
    private static function extractMessage(array $body, int $status): ?string
    {
        $raw = $body['erro']
            ?? $body['error']
            ?? $body['message']
            ?? $body['mensagem']
            ?? null;

        if (is_string($raw) && $raw !== '') {
            return $raw;
        }

        if ($status >= 200 && $status < 300) {
            return null;
        }

        return self::errorMessage($status);
    }
}
