<?php
declare(strict_types=1);

namespace E258Tech\Core;

use E258Tech\Infrastructure\Auth\AdminSession;
use E258Tech\Infrastructure\Auth\PhpSessionTokenProvider;
use E258Tech\Infrastructure\Http\CurlHttpClient;
use E258Tech\Infrastructure\Nexora\NexoraClient;
use E258Tech\Infrastructure\Security\WebSecurity;
use E258Tech\Controller\Admin\AdminAuthController;
use E258Tech\Controller\Admin\AdminDownloadController;
use E258Tech\Controller\Admin\AdminPageGuard;
use E258Tech\Controller\PublicSite\CarreiraController;
use E258Tech\Controller\PublicSite\HomeController;
use E258Tech\Controller\PublicSite\OpenVacanciesCounter;
use E258Tech\Controller\PublicSite\PublicApiController;
use E258Tech\Http\ServerRequest;
use E258Tech\Routing\AdminPageRouter;
use E258Tech\Routing\AdminRoutes;
use E258Tech\Routing\StudentAdminRoutes;
use E258Tech\View\ViewHelper;

final readonly class ApplicationContainer
{
    public NexoraClient $nexora;
    public AdminSession $session;
    public AdminPageGuard $guard;
    public WebSecurity $security;
    public ServerRequest $request;
    public ViewHelper $view;
    public CarreiraController $carreira;
    public HomeController $home;
    public PublicApiController $publicApi;
    public AdminRoutes $routes;
    public StudentAdminRoutes $studentRoutes;
    public AdminPageRouter $adminPages;
    public AdminAuthController $adminAuth;
    public AdminDownloadController $adminDownload;
    public OpenVacanciesCounter $openVacancies;

    public function __construct(string $baseUrl)
    {
        $http = new CurlHttpClient();
        $tokens = new PhpSessionTokenProvider($http, $baseUrl);
        $this->nexora = new NexoraClient($baseUrl, $tokens);
        $this->session = new AdminSession($this->nexora);
        $this->security = new WebSecurity();
        $this->request = ServerRequest::fromGlobals();
        $this->guard = new AdminPageGuard($this->session, $this->request);
        $this->view = new ViewHelper();
        $this->openVacancies = new OpenVacanciesCounter($this->nexora);
        $this->carreira = new CarreiraController(
            $this->nexora,
            $this->security,
            $this->view,
            $this->openVacancies,
            dirname(__DIR__, 2) . '/src/View/templates'
        );
        $this->home = new HomeController(
            $this->security,
            $this->openVacancies,
            dirname(__DIR__, 2) . '/src/View/templates'
        );
        $this->publicApi = new PublicApiController($this->request, $this->security, $this->nexora);
        $this->routes        = new AdminRoutes();
        $this->studentRoutes = new StudentAdminRoutes();
        $this->adminPages    = new AdminPageRouter(
            $this->routes,
            $this->guard,
            dirname(__DIR__, 2) . '/src/View/templates'
        );
        $this->adminAuth = new AdminAuthController(
            $this->session,
            $this->security,
            $this->request,
            dirname(__DIR__, 2) . '/src/View/templates'
        );
        $this->adminDownload = new AdminDownloadController($this->guard, $this->request, $this->nexora);
    }
}
