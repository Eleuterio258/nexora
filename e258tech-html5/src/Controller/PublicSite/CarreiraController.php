<?php
declare(strict_types=1);

namespace E258Tech\Controller\PublicSite;

use E258Tech\Infrastructure\Nexora\NexoraClient;
use E258Tech\Infrastructure\Security\WebSecurity;
use E258Tech\View\ViewHelper;

final readonly class CarreiraController
{
    public function __construct(
        private NexoraClient $nexora,
        private WebSecurity $security,
        private ViewHelper $view,
        private OpenVacanciesCounter $openVacancies,
        private string $viewRoot
    ) {
    }

    public function render(): void
    {
        $activePage = 'carreira';
        $csrf       = $this->security->csrfToken();
        $view       = $this->view;
        $app        = (object) ['openVacancies' => $this->openVacancies];

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

        $totalVagas = array_sum(array_column($vagas, 'num_vagas'));

        require $this->viewRoot . '/public/carreira.php';
    }
}
