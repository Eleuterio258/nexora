<?php
declare(strict_types=1);

namespace E258Tech\Core;

use E258Tech\Controller\Admin\AdminAuthController;
use E258Tech\Controller\Admin\AdminPageGuard;
use E258Tech\Controller\PublicSite\PublicApiController;
use E258Tech\Http\ServerRequest;
use E258Tech\Infrastructure\Auth\AdminSession;
use E258Tech\Infrastructure\Auth\PhpSessionTokenProvider;
use E258Tech\Infrastructure\Http\CurlHttpClient;
use E258Tech\Infrastructure\Nexora\NexoraClient;
use E258Tech\Infrastructure\Security\IdHasher;
use E258Tech\Infrastructure\Security\WebSecurity;
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
    public IdHasher $id;
    public ViewHelper $view;
    public PublicApiController $publicApi;
    public AdminRoutes $routes;
    public StudentAdminRoutes $studentRoutes;
    public AdminPageRouter $adminPages;
    public AdminAuthController $adminAuth;

    public function __construct(string $baseUrl)
    {
        $http = new CurlHttpClient();
        $tokens = new PhpSessionTokenProvider($http, $baseUrl);
        $this->nexora = new NexoraClient(
            $baseUrl,
            $tokens,
            getenv('NEXORA_TENANT_CODE') ?: null,
            getenv('NEXORA_TENANT_SECRET') ?: null
        );
        $this->session = new AdminSession($this->nexora);
        $this->security = new WebSecurity();
        $this->request = ServerRequest::fromGlobals();
        $idSalt = getenv('JWT_SECRET') ?: 'change-me-secret';
        $this->id = new IdHasher($idSalt);
        $this->guard = new AdminPageGuard($this->session, $this->request);
        $this->view = new ViewHelper();
        $this->publicApi = new PublicApiController($this->nexora);
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
    }
}
