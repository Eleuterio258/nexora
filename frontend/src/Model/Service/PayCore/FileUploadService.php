<?php

declare(strict_types=1);

namespace E258Tech\Model\Service\PayCore;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

/**
 * Upload de ficheiros no PayCore (/api/v1/files).
 */
final class FileUploadService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    /**
     * Faz upload de um ficheiro e devolve a URL pública.
     *
     * @param array<string, mixed> $file Entrada $_FILES['nome']
     */
    public function uploadSingle(array $file): string
    {
        if (empty($file['tmp_name']) || !is_uploaded_file($file['tmp_name'])) {
            throw new OperationException('Ficheiro invalido ou nao enviado.');
        }

        $mime = $file['type'] ?? 'application/octet-stream';
        $name = $file['name'] ?? 'upload';
        $bytes = file_get_contents($file['tmp_name']);
        if ($bytes === false) {
            throw new OperationException('Erro ao ler o ficheiro.');
        }

        $response = $this->gateway->uploadBinary('/api/v1/files/upload/single', $bytes, $mime);
        $this->ensureSuccessArray($response, 'Erro ao fazer upload do ficheiro.');

        $body = $response['body'] ?? [];
        if (!empty($body['url'])) {
            return $body['url'];
        }
        if (!empty($body['imageUrl'])) {
            return $body['imageUrl'];
        }
        if (!empty($body['key'])) {
            return '/api/v1/files/url/' . urlencode($body['key']);
        }

        throw new OperationException('Resposta de upload inesperada.');
    }

    /**
     * @param array<string, mixed> $response
     */
    private function ensureSuccessArray(array $response, string $defaultMessage): void
    {
        $status = $response['status'] ?? 0;
        if ($status >= 200 && $status < 300) {
            return;
        }

        $body = $response['body'] ?? [];
        $message = $body['message'] ?? $body['error'] ?? $defaultMessage;
        throw new OperationException($message);
    }
}
