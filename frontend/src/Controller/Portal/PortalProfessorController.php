<?php
declare(strict_types=1);

namespace E258Tech\Controller\Portal;

use E258Tech\Infrastructure\Auth\AdminSession;
use E258Tech\Infrastructure\Http\CurlHttpClient;

final class PortalProfessorController
{
    private CurlHttpClient $http;

    public function __construct(
        private readonly string $apiBase,
        private readonly string $token
    ) {
        $this->http = new CurlHttpClient();
    }

    public function api(string $path, string $method = 'GET', ?array $body = null): array
    {
        $resp = $this->http->request(
            $method,
            $this->apiBase . $path,
            $body,
            ["Authorization: Bearer {$this->token}"]
        );
        return ['status' => $resp->status, 'body' => $resp->body ?? []];
    }

    public function logout(AdminSession $session): void
    {
        if ($this->token !== '') {
            $this->http->request(
                'POST',
                $this->apiBase . '/api/portal/professor/logout',
                [],
                ["Authorization: Bearer {$this->token}"]
            );
        }
        $session->clear();
        header('Location: /nexora/login');
        exit;
    }
}
