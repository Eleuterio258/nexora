<?php
declare(strict_types=1);

namespace E258Tech\Infrastructure\Http;

use E258Tech\Http\HttpResponse;
use E258Tech\Model\Contract\HttpClient;

final class CurlHttpClient implements HttpClient
{
    public function __construct(
        private readonly int $timeout = 30,
        private readonly int $connectTimeout = 5
    ) {
    }

    public function request(
        string $method,
        string $url,
        ?array $json = null,
        array $headers = []
    ): HttpResponse {
        $headers[] = 'Accept: application/json';
        $options = [
            CURLOPT_CUSTOMREQUEST => strtoupper($method),
            CURLOPT_HTTPHEADER => $headers,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => $this->timeout,
            CURLOPT_CONNECTTIMEOUT => $this->connectTimeout,
        ];

        if ($json !== null) {
            $encoded = json_encode($json, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
            $options[CURLOPT_HTTPHEADER][] = 'Content-Type: application/json';
            $options[CURLOPT_POSTFIELDS] = $encoded;
        }

        $handle = curl_init($url);
        curl_setopt_array($handle, $options);
        $rawBody = curl_exec($handle);

        if ($rawBody === false) {
            $message = curl_error($handle);
            curl_close($handle);
            throw new HttpClientException('Erro de comunicacao com a API Nexora: ' . $message);
        }

        $status = (int) curl_getinfo($handle, CURLINFO_RESPONSE_CODE);
        curl_close($handle);

        $body = json_decode((string) $rawBody, true);
        if (is_array($body) && isset($body['error']) && !isset($body['erro'])) {
            $body['erro'] = $body['error'];
        }

        return new HttpResponse($status, is_array($body) ? $body : null);
    }
}
