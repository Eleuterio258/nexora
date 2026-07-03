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

        $this->deny('Não tem permissão para aceder a esta secção.');
    }

    /**
     * Bloqueia o request se o utilizador não tiver um dos escopos indicados.
     * Superadmin bypassa.
     * Uso: $app->guard->requireEscopo('erp');
     */
    public function requireEscopo(string ...$escopos): void
    {
        if ($this->session->isSuperAdmin()) {
            return;
        }
        if (in_array($this->session->escopo(), $escopos, true)) {
            return;
        }
        $this->deny('O seu tipo de conta não tem acesso a esta secção.');
    }

    /**
     * Bloqueia o request se a funcionalidade não estiver activa para o tenant.
     * Uso: $app->guard->requireFeature('rh.ferias');
     */
    public function requireFeature(string $feature): void
    {
        if ($this->session->canFeature($feature)) {
            return;
        }
        $this->deny('Esta funcionalidade não está disponível no seu plano.');
    }

    private function deny(string $message): void
    {
        http_response_code(403);
        echo '<!DOCTYPE html><html lang="pt"><head><meta charset="UTF-8">'
            . '<meta name="viewport" content="width=device-width,initial-scale=1">'
            . '<title>Acesso negado</title><link rel="stylesheet" href="/assets/css/nexora.css"></head>'
            . '<body><main class="adm-denied"><h1>Acesso negado</h1>'
            . '<p>' . htmlspecialchars($message) . '</p>'
            . '<a href="/nexora/" class="adm-btn adm-btn-primary">Voltar ao início</a>'
            . '</main></body></html>';
        exit;
    }
}
