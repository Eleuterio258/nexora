<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin;

use E258Tech\Infrastructure\Auth\AdminSession;
use E258Tech\Http\ServerRequest;

final class AdminPageGuard
{
    public function __construct(
        private readonly AdminSession $session,
        private readonly ServerRequest $request
    ) {
    }

    public function requireAuthenticated(): void
    {
        if (!$this->session->isAuthenticated()) {
            $redirect = urlencode($this->request->requestUri());
            header('Location: /nexora/login' . ($redirect ? '?next=' . $redirect : ''));
            exit;
        }

        if ($this->session->expiresSoon() && !$this->session->refresh()) {
            $this->session->clear();
            header('Location: /nexora/login');
            exit;
        }

        // Verifica se o admin actualizou permissões (via timestamp no servidor).
        // Se sim, ou se o TTL expirou, faz sync imediato — sem logout necessário.
        if ($this->session->modulosExpirados()) {
            $this->session->syncModulos();
        }
        // Mantém o timestamp do servidor actualizado (leve — só 1× por request após sync)
        $this->session->refreshPermTimestamp();
    }

    public function requirePermission(string $module): void
    {
        // Módulo sem restrição (permission = '') → qualquer autenticado passa
        if ($module === '') {
            return;
        }

        // Verifica se o utilizador tem o módulo com qualquer acção (canModule)
        // Não depende do nome da acção — compatível com permissões semânticas da API
        if ($this->session->canModule($module)) {
            return;
        }

        http_response_code(403);
        echo '<!DOCTYPE html><html lang="pt"><head><meta charset="UTF-8">'
            . '<meta name="viewport" content="width=device-width,initial-scale=1">'
            . '<title>Acesso negado</title><link rel="stylesheet" href="/assets/css/nexora.css"></head>'
            . '<body><main class="adm-denied"><h1>Acesso negado</h1>'
            . '<p>Nao tem permissao para aceder a esta seccao.</p>'
            . '<a href="/nexora/" class="adm-btn adm-btn-primary">Voltar ao inicio</a>'
            . '</main></body></html>';
        exit;
    }
}
