<?php
declare(strict_types=1);

namespace E258Tech\Infrastructure\Nexora;

use CURLFile;
use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Contract\TokenProvider;
use E258Tech\Http\BinaryResponse;
use E258Tech\Infrastructure\Http\HttpClientException;
use E258Tech\Http\HttpResponse;

final class NexoraClient implements NexoraGateway
{
    public function __construct(
        private readonly string $baseUrl,
        private readonly TokenProvider $tokens
    ) {
    }

    public function request(
        string $method,
        string $path,
        ?array $payload = null,
        array $query = []
    ): HttpResponse {
        $response = $this->json(
            $method,
            $this->url($path, $query),
            $payload,
            ['Authorization: Bearer ' . $this->tokens->accessToken()]
        );

        return $response->status === 401
            ? $this->json(
                $method,
                $this->url($path, $query),
                $payload,
                ['Authorization: Bearer ' . $this->tokens->accessToken(true)]
            )
            : $response;
    }

    public function call(
        string $method,
        string $path,
        ?array $payload = null,
        array $query = []
    ): array {
        $response = $this->request($method, $path, $payload, $query);
        return ['status' => $response->status, 'body' => $response->body];
    }

    public function publicRequest(
        string $method,
        string $path,
        ?array $payload = null,
        array $query = [],
        array $curlOptions = []
    ): HttpResponse {
        $headers = [];
        if ($ip = $this->clientIp()) {
            $headers[] = 'X-Forwarded-For: ' . $ip;
        }

        return $this->json(
            $method,
            $this->url($path, $query),
            $payload,
            $headers,
            $curlOptions
        );
    }

    public function callPublic(
        string $method,
        string $path,
        ?array $payload = null,
        array $query = [],
        array $curlOptions = []
    ): array {
        $response = $this->publicRequest($method, $path, $payload, $query, $curlOptions);
        return ['status' => $response->status, 'body' => $response->body];
    }

    public function authenticate(string $email, string $password): HttpResponse
    {
        return $this->json('POST', $this->baseUrl . '/api/auth/login', [
            'email' => $email,
            'password' => $password,
        ]);
    }

    public function refresh(string $refreshToken): HttpResponse
    {
        return $this->json('POST', $this->baseUrl . '/api/auth/refresh', [
            'refresh_token' => $refreshToken,
        ]);
    }

    public function logout(string $accessToken): void
    {
        $this->json(
            'POST',
            $this->baseUrl . '/api/auth/logout',
            null,
            ['Authorization: Bearer ' . $accessToken]
        );
    }

    public function download(string $path): BinaryResponse
    {
        $response = $this->raw(
            $this->baseUrl . $path,
            [CURLOPT_HTTPHEADER => ['Authorization: Bearer ' . $this->tokens->accessToken()]]
        );
        if ($response['status'] === 401) {
            $response = $this->raw(
                $this->baseUrl . $path,
                [CURLOPT_HTTPHEADER => ['Authorization: Bearer ' . $this->tokens->accessToken(true)]]
            );
        }

        return new BinaryResponse(
            $response['status'],
            $response['contentType'],
            $response['headers'],
            $response['body']
        );
    }

    public function downloadData(string $path): array
    {
        $response = $this->download($path);
        return [
            'status' => $response->status,
            'contentType' => $response->contentType,
            'headers' => $response->headers,
            'body' => $response->body,
        ];
    }

    public function uploadPublic(string $path, array $fields, array $files): HttpResponse
    {
        $postFields = $fields;
        foreach ($files as $field => $file) {
            if (empty($file['tmp_name']) || !is_uploaded_file($file['tmp_name'])) {
                continue;
            }
            $postFields[$field] = new CURLFile(
                $file['tmp_name'],
                $file['type'] ?? '',
                $file['name'] ?? ''
            );
        }

        $headers = ['Accept: application/json'];
        if ($ip = $this->clientIp()) {
            $headers[] = 'X-Forwarded-For: ' . $ip;
        }

        $response = $this->raw($this->baseUrl . $path, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $postFields,
            CURLOPT_HTTPHEADER => $headers,
            CURLOPT_TIMEOUT => 60,
        ]);
        $body = json_decode($response['body'], true);

        return new HttpResponse($response['status'], is_array($body) ? $body : null);
    }

    public function uploadPublicData(string $path, array $fields, array $files): array
    {
        $response = $this->uploadPublic($path, $fields, $files);
        return ['status' => $response->status, 'body' => $response->body];
    }

    private function json(
        string $method,
        string $url,
        ?array $payload = null,
        array $headers = [],
        array $curlOptions = []
    ): HttpResponse {
        $headers[] = 'Accept: application/json';
        $options = [
            CURLOPT_CUSTOMREQUEST => strtoupper($method),
            CURLOPT_HTTPHEADER => $headers,
        ];
        if ($payload !== null) {
            $options[CURLOPT_HTTPHEADER][] = 'Content-Type: application/json';
            $options[CURLOPT_POSTFIELDS] = json_encode(
                $payload,
                JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR
            );
        }

        $response = $this->raw($url, $options + $curlOptions);
        $body = json_decode($response['body'], true);
        if (is_array($body) && isset($body['error']) && !isset($body['erro'])) {
            $body['erro'] = $body['error'];
        }

        return new HttpResponse($response['status'], is_array($body) ? $body : null);
    }

    private function raw(string $url, array $options): array
    {
        $headers = [];
        $handle = curl_init($url);
        curl_setopt_array($handle, $options + [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 30,
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_HEADERFUNCTION => static function ($handle, string $line) use (&$headers): int {
                $parts = explode(':', $line, 2);
                if (count($parts) === 2) {
                    $headers[strtolower(trim($parts[0]))] = trim($parts[1]);
                }
                return strlen($line);
            },
        ]);

        $body = curl_exec($handle);
        if ($body === false) {
            $message = curl_error($handle);
            curl_close($handle);
            throw new HttpClientException('Erro de comunicacao com a API Nexora: ' . $message);
        }

        $status = (int) curl_getinfo($handle, CURLINFO_RESPONSE_CODE);
        $contentType = (string) curl_getinfo($handle, CURLINFO_CONTENT_TYPE);
        curl_close($handle);

        return [
            'status' => $status,
            'contentType' => $contentType,
            'headers' => $headers,
            'body' => (string) $body,
        ];
    }

    private function url(string $path, array $query): string
    {
        $url = $this->baseUrl . $path;
        $query = array_filter($query, static fn(mixed $value): bool => $value !== null && $value !== '');
        return $query ? $url . (str_contains($path, '?') ? '&' : '?') . http_build_query($query) : $url;
    }

    private function clientIp(): ?string
    {
        if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
            return trim(explode(',', $_SERVER['HTTP_X_FORWARDED_FOR'])[0]);
        }
        return $_SERVER['REMOTE_ADDR'] ?? null;
    }
}
