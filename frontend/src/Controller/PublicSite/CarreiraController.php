<?php
declare(strict_types=1);

namespace E258Tech\Controller\PublicSite;

use E258Tech\Infrastructure\Auth\PortalCandidatoSession;
use E258Tech\Infrastructure\Nexora\NexoraClient;
use E258Tech\Infrastructure\Security\WebSecurity;
use E258Tech\Routing\CandidatoRoutes;
use E258Tech\View\ViewHelper;

final readonly class CarreiraController
{
    public function __construct(
        private NexoraClient $nexora,
        private WebSecurity $security,
        private ViewHelper $view,
        private OpenVacanciesCounter $openVacancies,
        private string $viewRoot,
        private CandidatoRoutes $candidatoRoutes
    ) {
    }

    private function fetchVagas(): array
    {
        try {
            $resp  = $this->nexora->callPublic('GET', '/api/public/recrutamento/vagas', null, ['limit' => 100]);
            $vagas = $resp['body']['data'] ?? [];
        } catch (\Throwable) {
            $vagas = [];
        }
        usort($vagas, fn($a, $b) => $a['id'] <=> $b['id']);

        $hoje = strtotime('today');
        foreach ($vagas as &$v) {
            $v['dias_restantes'] = $v['prazo'] !== null
                ? (int) ((strtotime($v['prazo']) - $hoje) / 86400)
                : null;
        }
        unset($v);
        return $vagas;
    }

    private function fetchCandidaturas(PortalCandidatoSession $session): array
    {
        $resp = $this->nexora->callWithBearer(
            'GET',
            '/api/public/recrutamento/candidatos/candidaturas',
            null,
            $session->token()
        )['body'] ?? [];
        return is_array($resp) ? $resp : [];
    }

    private function fetchConversas(PortalCandidatoSession $session): array
    {
        $resp = $this->nexora->callWithBearer(
            'GET',
            '/api/public/recrutamento/candidatos/conversas',
            null,
            $session->token()
        )['body'] ?? [];
        return is_array($resp) ? $resp : [];
    }

    private function appContext(): object
    {
        return (object) ['openVacancies' => $this->openVacancies, 'candidatoRoutes' => $this->candidatoRoutes];
    }

    public function render(): void
    {
        $activePage = 'carreira';
        $csrf       = $this->security->csrfToken();
        $view       = $this->view;
        $app        = (object) ['openVacancies' => $this->openVacancies, 'candidatoRoutes' => $this->candidatoRoutes];

        $vagas      = $this->fetchVagas();
        $totalVagas = array_sum(array_column($vagas, 'num_vagas'));

        $candidatoSessao = new PortalCandidatoSession();
        $candidatoLogado = $candidatoSessao->isAuthenticated() ? $candidatoSessao->candidato() : null;

        require $this->viewRoot . '/public/carreira.php';
    }

    public function estado(): void
    {
        $activePage = 'carreira';
        $csrf       = $this->security->csrfToken();
        $view       = $this->view;
        $app        = (object) ['openVacancies' => $this->openVacancies, 'candidatoRoutes' => $this->candidatoRoutes];

        require $this->viewRoot . '/public/carreira_estado.php';
    }

    public function loginCandidato(): void
    {
        // Login unificado — mesma entrada que ERP/aluno/encarregado/professor.
        header('Location: ' . $this->candidatoRoutes->loginUrl());
        exit;
    }

    public function registarCandidato(): void
    {
        $activePage = 'carreira';
        $csrf       = $this->security->csrfToken();
        $view       = $this->view;
        $app        = (object) ['openVacancies' => $this->openVacancies, 'candidatoRoutes' => $this->candidatoRoutes];

        require $this->viewRoot . '/public/carreira_registar.php';
    }

    /**
     * Painel do candidato — resumo: contagem de candidaturas por estado e
     * últimas conversas com mensagens não lidas.
     */
    public function areaCandidato(): void
    {
        $session = new PortalCandidatoSession();
        $session->requireAuthenticated();

        $candidato    = $session->candidato();
        $candidaturas = $this->fetchCandidaturas($session);
        $conversas    = $this->fetchConversas($session);

        $activePage = 'painel_dashboard';
        $csrf       = $this->security->csrfToken();
        $view       = $this->view;
        $app        = $this->appContext();

        require $this->viewRoot . '/candidato/dashboard.php';
    }

    public function candidaturasCandidato(): void
    {
        $session = new PortalCandidatoSession();
        $session->requireAuthenticated();

        $candidato    = $session->candidato();
        $candidaturas = $this->fetchCandidaturas($session);
        $conversas    = $this->fetchConversas($session);

        $activePage = 'painel_candidaturas';
        $csrf       = $this->security->csrfToken();
        $view       = $this->view;
        $app        = $this->appContext();

        require $this->viewRoot . '/candidato/candidaturas.php';
    }

    /**
     * Lista de conversas por candidatura; se `id` for passado na query,
     * carrega também o histórico de mensagens dessa candidatura (thread).
     */
    public function mensagensCandidato(): void
    {
        $session = new PortalCandidatoSession();
        $session->requireAuthenticated();

        $candidato       = $session->candidato();
        $conversas       = $this->fetchConversas($session);
        $candidaturaId   = (int) ($_GET['id'] ?? 0);
        $conversaActiva  = null;
        $mensagens       = [];

        if ($candidaturaId > 0) {
            foreach ($conversas as $c) {
                if ((int) $c['candidatura_id'] === $candidaturaId) {
                    $conversaActiva = $c;
                    break;
                }
            }
            if ($conversaActiva !== null) {
                $resp      = $this->nexora->callWithBearer(
                    'GET',
                    "/api/public/recrutamento/candidatos/candidaturas/$candidaturaId/mensagens",
                    null,
                    $session->token()
                )['body'] ?? [];
                $mensagens = is_array($resp) ? $resp : [];
            }
        }

        $activePage = 'painel_mensagens';
        $csrf       = $this->security->csrfToken();
        $view       = $this->view;
        $app        = $this->appContext();

        require $this->viewRoot . '/candidato/mensagens.php';
    }

    public function perfilCandidato(): void
    {
        $session   = new PortalCandidatoSession();
        $session->requireAuthenticated();

        $candidato = $session->candidato();
        $conversas = $this->fetchConversas($session);
        $perfil    = $this->nexora->callWithBearer(
            'GET',
            '/api/public/recrutamento/candidatos/perfil',
            null,
            $session->token()
        )['body'] ?? [];
        if (!is_array($perfil)) {
            $perfil = [];
        }

        $activePage = 'painel_perfil';
        $csrf       = $this->security->csrfToken();
        $view       = $this->view;
        $app        = $this->appContext();

        require $this->viewRoot . '/candidato/perfil.php';
    }

    /** POST /carreira/candidato/api/mensagens/{id} — enviar mensagem numa candidatura. */
    public function apiEnviarMensagem(int $candidaturaId): void
    {
        header('Content-Type: application/json');
        $session = new PortalCandidatoSession();
        if (!$session->isAuthenticated()) {
            http_response_code(401);
            echo json_encode(['erro' => 'Sessão expirada.']);
            return;
        }

        $body = json_decode((string) file_get_contents('php://input'), true);
        $resp = $this->nexora->callWithBearer(
            'POST',
            "/api/public/recrutamento/candidatos/candidaturas/$candidaturaId/mensagens",
            is_array($body) ? $body : [],
            $session->token()
        );
        http_response_code($resp['status'] ?: 200);
        echo json_encode($resp['body']);
    }

    /** PUT /carreira/candidato/api/perfil — actualizar nome/telefone/password. */
    public function apiActualizarPerfil(): void
    {
        header('Content-Type: application/json');
        $session = new PortalCandidatoSession();
        if (!$session->isAuthenticated()) {
            http_response_code(401);
            echo json_encode(['erro' => 'Sessão expirada.']);
            return;
        }

        $body = json_decode((string) file_get_contents('php://input'), true);
        $resp = $this->nexora->callWithBearer(
            'PUT',
            '/api/public/recrutamento/candidatos/perfil',
            is_array($body) ? $body : [],
            $session->token()
        );
        http_response_code($resp['status'] ?: 200);
        if ($resp['status'] !== 204) {
            echo json_encode($resp['body']);
        }
    }

    public function logoutCandidato(): never
    {
        $session = new PortalCandidatoSession();
        $token   = $session->token();
        if ($token !== '') {
            $this->nexora->callWithBearer('POST', '/api/public/recrutamento/candidatos/logout', null, $token);
        }
        $session->destroy();
        header('Location: /nexora/login');
        exit;
    }
}
