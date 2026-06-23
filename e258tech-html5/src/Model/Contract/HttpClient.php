<?php
declare(strict_types=1);

namespace E258Tech\Model\Contract;

use E258Tech\Http\HttpResponse;

interface HttpClient
{
    public function request(
        string $method,
        string $url,
        ?array $json = null,
        array $headers = []
    ): HttpResponse;
}
