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

    public function areaCandidato(): void
    {
        $session = new PortalCandidatoSession();
        $session->requireAuthenticated();

        $candidato    = $session->candidato();
        $candidaturas = $this->nexora->callWithBearer(
            'GET',
            '/api/public/recrutamento/candidatos/candidaturas',
            null,
            $session->token()
        )['body'] ?? [];
        if (!is_array($candidaturas)) {
            $candidaturas = [];
        }

        $activePage = 'carreira';
        $csrf       = $this->security->csrfToken();
        $view       = $this->view;
        $app        = (object) ['openVacancies' => $this->openVacancies, 'candidatoRoutes' => $this->candidatoRoutes];

        require $this->viewRoot . '/public/carreira_area.php';
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
