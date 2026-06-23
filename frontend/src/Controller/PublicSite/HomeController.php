<?php
declare(strict_types=1);

namespace E258Tech\Controller\PublicSite;

use E258Tech\Infrastructure\Security\WebSecurity;

final readonly class HomeController
{
    public function __construct(
        private WebSecurity $security,
        private OpenVacanciesCounter $openVacancies,
        private string $viewRoot
    ) {
    }

    public function render(): void
    {
        $activePage = 'home';
        $csrf = $this->security->csrfToken();
        $app = (object) ['openVacancies' => $this->openVacancies];
        require $this->viewRoot . '/public/home.php';
    }
}
