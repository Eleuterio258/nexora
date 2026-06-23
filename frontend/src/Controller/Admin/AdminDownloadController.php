<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin;

use E258Tech\Http\ServerRequest;
use E258Tech\Infrastructure\Nexora\NexoraClient;

final readonly class AdminDownloadController
{
    public function __construct(
        private AdminPageGuard $guard,
        private ServerRequest $request,
        private NexoraClient $nexora
    ) {
    }

    public function download(): never
    {
        $this->guard->requireAuthenticated();
        $this->guard->requirePermission('recrutamento');

        $type = $this->request->queryString('type');
        $id = $this->request->queryInt('id', 0);

        if (!in_array($type, ['cv', 'carta'], true) || !$id) {
            http_response_code(400);
            echo 'Pedido inválido.';
            exit;
        }

        $resp = $this->nexora->downloadData("/api/recrutamento/candidaturas/$id/$type");

        if ($resp['status'] !== 200) {
            http_response_code(404);
            echo 'Ficheiro não encontrado.';
            exit;
        }

        header('Content-Type: ' . ($resp['contentType'] ?: 'application/octet-stream'));
        header('Content-Disposition: ' . ($resp['headers']['content-disposition'] ?? 'attachment'));
        echo $resp['body'];
        exit;
    }
}
