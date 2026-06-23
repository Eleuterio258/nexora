<?php
declare(strict_types=1);

namespace E258Tech\Model\Service;

use E258Tech\Http\HttpResponse;
use E258Tech\Model\Exception\OperationException;

abstract class NexoraService
{
    protected function ensureSuccess(HttpResponse $response, string $fallback): void
    {
        if ($response->successful()) {
            return;
        }

        throw new OperationException(
            (string) ($response->body['erro'] ?? $response->body['error'] ?? $fallback),
            $response->status
        );
    }
}
