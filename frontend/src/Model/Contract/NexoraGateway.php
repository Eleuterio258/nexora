<?php
declare(strict_types=1);

namespace E258Tech\Model\Contract;

use E258Tech\Http\BinaryResponse;
use E258Tech\Http\HttpResponse;

interface NexoraGateway
{
    public function request(
        string $method,
        string $path,
        ?array $payload = null
    ): HttpResponse;

    /**
     * Envia bytes crus (não JSON) autenticados por Bearer, ex.: um PDF gerado
     * localmente para ser guardado no storage do backend.
     */
    public function uploadBinary(string $path, string $bytes, string $contentType): array;

    /**
     * Envia ficheiros via multipart/form-data autenticado por Bearer.
     */
    public function uploadMultipart(string $path, array $fields, array $files): array;

    /**
     * Descarrega um recurso binário do backend (ex.: PDF) autenticado por Bearer.
     */
    public function download(string $path): BinaryResponse;
}
