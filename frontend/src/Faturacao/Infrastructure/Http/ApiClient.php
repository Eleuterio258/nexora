<?php

declare(strict_types=1);

namespace E258Tech\Faturacao\Infrastructure\Http;

use E258Tech\Faturacao\Infrastructure\Auth\AuthSession;

/**
 * Cliente HTTP mínimo para a API do backend Nexora (Go). Sem dependências
 * externas — usa cURL directamente, já que o phc não tinha nenhum cliente
 * HTTP no composer.json.
 */
final class ApiClient
{
    public function __construct(
        private readonly string $baseUrl,
        private readonly AuthSession $session
    ) {
    }

    /**
     * @return array<string, mixed>
     */
    public function get(string $path, array $query = []): array
    {
        $url = $this->baseUrl . $path;
        if ($query !== []) {
            $url .= '?' . http_build_query($query);
        }
        return $this->request('GET', $url);
    }

    /**
     * @return array<string, mixed>
     */
    public function post(string $path, array $body = []): array
    {
        return $this->request('POST', $this->baseUrl . $path, $body);
    }

    /**
     * @return array<string, mixed>
     */
    private function request(string $method, string $url, ?array $body = null): array
    {
        $ch = curl_init($url);
        $headers = ['Accept: application/json'];

        $token = $this->session->accessToken();
        if ($token !== null) {
            $headers[] = 'Authorization: Bearer ' . $token;
        }

        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 15);

        if ($body !== null) {
            $headers[] = 'Content-Type: application/json';
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body, JSON_THROW_ON_ERROR));
        }

        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

        $raw = curl_exec($ch);
        if ($raw === false) {
            $error = curl_error($ch);
            curl_close($ch);
            throw new ApiException('Falha de ligação à API: ' . $error, 0);
        }

        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        $decoded = $raw !== '' ? json_decode($raw, true) : null;

        if ($status >= 400) {
            $message = is_array($decoded) && isset($decoded['error'])
                ? (string) $decoded['error']
                : 'Erro ao comunicar com a API (HTTP ' . $status . ').';
            throw new ApiException($message, $status);
        }

        return is_array($decoded) ? $decoded : [];
    }
}
