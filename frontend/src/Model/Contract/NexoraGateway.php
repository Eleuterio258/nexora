<?php
declare(strict_types=1);

namespace E258Tech\Model\Contract;

use E258Tech\Http\HttpResponse;

interface NexoraGateway
{
    public function request(
        string $method,
        string $path,
        ?array $payload = null
    ): HttpResponse;
}
