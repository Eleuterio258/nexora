<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin;

use E258Tech\Model\Service\Authorization\AuthorizationAdminService;
use E258Tech\Model\Service\CentrosCusto\CentrosCustoService;
use E258Tech\Model\Service\Company\CompanyAdminService;
use E258Tech\Model\Service\Contabilidade\ContabilidadeService;
use E258Tech\Model\Service\Crm\ActivityService;
use E258Tech\Model\Service\Crm\LeadService;
use E258Tech\Model\Service\Crm\OpportunityService;
use E258Tech\Model\Service\Customer\CustomerService;
use E258Tech\Model\Service\Invoicing\InvoicingService;
use E258Tech\Model\Service\Pos\PosService;
use E258Tech\Model\Service\Product\ProductService;
use E258Tech\Model\Service\Purchase\PurchaseService;
use E258Tech\Model\Service\Recruitment\RecruitmentAdminService;
use E258Tech\Model\Service\RH\RecursosHumanosService;
use E258Tech\Model\Service\School\SchoolService;
use E258Tech\Model\Service\Sistema\SistemaConfiguracaoService;
use E258Tech\Model\Service\Logistica\LogisticaService;
use E258Tech\Model\Service\Stock\StockService;
use E258Tech\Model\Service\Tax\AdvancedTaxService;
use E258Tech\Model\Service\Tesouraria\TesourariaService;
use E258Tech\Model\Service\Assinaturas\AssinaturasService;
use E258Tech\Model\Service\Financeiro\FinanceiroService;
use E258Tech\Model\Service\MultiMoeda\MultiMoedaService;
use E258Tech\Model\Service\Notificacoes\NotificacoesService;
use E258Tech\Model\Service\Seguranca\SegurancaService;
use E258Tech\Model\Service\SelfService\SelfServiceService;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Http\ApiResult;

final readonly class AdminApiDependencies
{
    public function __construct(
        public AdminApiKernel $kernel,
        public LeadService $leads,
        public OpportunityService $opportunities,
        public ActivityService $activities,
        public RecruitmentAdminService $recruitment,
        public AuthorizationAdminService $authorization,
        public CompanyAdminService $companies,
        public CustomerService $customers,
        public InvoicingService $invoicing,
        public ProductService $products,
        public PosService $pos,
        public SistemaConfiguracaoService $sistema,
        public RecursosHumanosService $rh,
        public ContabilidadeService $contabilidade,
        public CentrosCustoService $centrosCusto,
        public PurchaseService $purchases,
        public StockService $stock,
        public AdvancedTaxService $taxes,
        public SchoolService $school,
        public TesourariaService $tesouraria,
        public LogisticaService $logistica,
        public AssinaturasService $assinaturas,
        public FinanceiroService $financeiro,
        public MultiMoedaService $multiMoeda,
        public NotificacoesService $notificacoes,
        public SegurancaService $seguranca,
        public SelfServiceService $selfService,
    ) {
    }

    public function result(callable $operation, string $errorKey = 'erro'): ApiResult
    {
        try {
            return new ApiResult($operation());
        } catch (OperationException $exception) {
            $status = $exception->status >= 400 && $exception->status <= 599
                ? $exception->status
                : 422;
            return new ApiResult([$errorKey => $exception->getMessage()], $status);
        }
    }

    public function normalizedPermissions(mixed $items): array
    {
        $permissions = [];
        foreach ((array) $items as $item) {
            $module = trim((string) ($item['modulo'] ?? ''));
            $action = trim((string) ($item['acao'] ?? ''));
            if ($module !== '' && $action !== '') {
                $permissions[] = ['modulo' => $module, 'acao' => $action];
            }
        }
        return $permissions;
    }
}
