<?php
declare(strict_types=1);

namespace E258Tech\Core;

use E258Tech\Infrastructure\Auth\AdminSession;
use E258Tech\Infrastructure\Auth\PhpSessionTokenProvider;
use E258Tech\Infrastructure\Http\CurlHttpClient;
use E258Tech\Infrastructure\Nexora\NexoraClient;
use E258Tech\Infrastructure\Security\IdHasher;
use E258Tech\Infrastructure\Security\WebSecurity;
use E258Tech\Controller\Admin\AdminAuthController;
use E258Tech\Controller\Admin\AdminDownloadController;
use E258Tech\Controller\Admin\AdminPageGuard;
use E258Tech\Controller\PublicSite\CarreiraController;
use E258Tech\Controller\PublicSite\HomeController;
use E258Tech\Controller\PublicSite\OpenVacanciesCounter;
use E258Tech\Controller\PublicSite\PublicApiController;
use E258Tech\Http\ServerRequest;
use E258Tech\Model\Service\PayCore\DashboardService;
use E258Tech\Model\Service\PayCore\PosCashDrawerService;
use E258Tech\Model\Service\PayCore\PosDiscountService;
use E258Tech\Model\Service\Pos\PosService;
use E258Tech\Model\Service\PayCore\CustomerService;
use E258Tech\Model\Service\PayCore\FileUploadService;
use E258Tech\Model\Service\PayCore\InvoicingService;
use E258Tech\Model\Service\PayCore\PosPaymentService;
use E258Tech\Model\Service\PayCore\PosTransactionReportService;
use E258Tech\Model\Service\PayCore\StockAdjustmentService;
use E258Tech\Model\Service\PayCore\StockCategoryService;
use E258Tech\Model\Service\PayCore\StockProductService;
use E258Tech\Model\Service\PayCore\TerminalAdminService;
use E258Tech\Model\Service\PayCore\UserService;
use E258Tech\Routing\AdminPageRouter;
use E258Tech\Routing\AdminRoutes;
use E258Tech\Routing\CandidatoRoutes;
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
    public CarreiraController $carreira;
    public HomeController $home;
    public PublicApiController $publicApi;
    public AdminRoutes $routes;
    public StudentAdminRoutes $studentRoutes;
    public CandidatoRoutes $candidatoRoutes;
    public AdminPageRouter $adminPages;
    public AdminAuthController $adminAuth;
    public AdminDownloadController $adminDownload;
    public OpenVacanciesCounter $openVacancies;
    public DashboardService $payCoreDashboard;
    public PosCashDrawerService $payCoreCashDrawer;
    public PosService $pos;
    public PosTransactionReportService $payCoreTransactionReport;
    public PosPaymentService $payCorePayment;
    public PosDiscountService $payCoreDiscount;
    public StockCategoryService $payCoreStockCategory;
    public StockProductService $payCoreStockProduct;
    public StockAdjustmentService $payCoreStockAdjustment;
    public InvoicingService $payCoreInvoicing;
    public CustomerService $payCoreCustomer;
    public FileUploadService $payCoreFileUpload;
    public UserService $payCoreUser;
    public TerminalAdminService $payCoreTerminalAdmin;

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
        $this->openVacancies = new OpenVacanciesCounter($this->nexora);
        $this->candidatoRoutes = new CandidatoRoutes();
        $this->carreira = new CarreiraController(
            $this->nexora,
            $this->security,
            $this->view,
            $this->openVacancies,
            dirname(__DIR__, 2) . '/src/View/templates',
            $this->candidatoRoutes
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
        $this->payCoreDashboard = new DashboardService($this->nexora);
        $this->payCoreCashDrawer = new PosCashDrawerService($this->nexora);
        $this->pos = new PosService($this->nexora);
        $this->payCoreTransactionReport = new PosTransactionReportService($this->nexora);
        $this->payCorePayment = new PosPaymentService($this->nexora);
        $this->payCoreDiscount = new PosDiscountService($this->nexora);
        $this->payCoreStockCategory = new StockCategoryService($this->nexora);
        $this->payCoreStockProduct = new StockProductService($this->nexora);
        $this->payCoreStockAdjustment = new StockAdjustmentService($this->nexora);
        $this->payCoreInvoicing = new InvoicingService($this->nexora);
        $this->payCoreCustomer = new CustomerService($this->nexora);
        $this->payCoreFileUpload = new FileUploadService($this->nexora);
        $this->payCoreUser = new UserService($this->nexora);
        $this->payCoreTerminalAdmin = new TerminalAdminService($this->nexora);
    }
}
