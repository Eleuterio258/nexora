<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin;

use E258Tech\Core\ApplicationContainer;
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
use E258Tech\Model\Service\Recruitment\RecruitmentAdminService;
use E258Tech\Infrastructure\Auth\PhpSessionAuthorization;
use E258Tech\Http\ApiResult;
use E258Tech\Controller\Admin\Api;

final readonly class AdminApiRuntime
{
    public AdminApiDependencies $dependencies;

    public function __construct(ApplicationContainer $app)
    {
        $gateway = $app->nexora;
        $this->dependencies = new AdminApiDependencies(
            new AdminApiKernel(
                new PhpSessionAuthorization(),
                $app->request,
                $app->security
            ),
            new LeadService($gateway),
            new OpportunityService($gateway),
            new ActivityService($gateway),
            new RecruitmentAdminService($gateway),
            new AuthorizationAdminService($gateway),
            new CompanyAdminService($gateway),
            new CustomerService($gateway),
            new InvoicingService($gateway),
            new ProductService($gateway),
            new PosService($gateway),
            new SistemaConfiguracaoService($gateway),
            new RecursosHumanosService($gateway),
            new ContabilidadeService($gateway),
            new CentrosCustoService($gateway),
            new PurchaseService($gateway),
            new StockService($gateway),
            new AdvancedTaxService($gateway),
            new SchoolService($gateway),
            new TesourariaService($gateway),
            new LogisticaService($gateway),
            new AssinaturasService($gateway),
            new FinanceiroService($gateway),
            new MultiMoedaService($gateway),
            new NotificacoesService($gateway),
            new SegurancaService($gateway),
            new SelfServiceService($gateway),
        );
    }

    public function result(callable $operation, string $errorKey = 'erro'): ApiResult
    {
        return $this->dependencies->result($operation, $errorKey);
    }

    public function normalizedPermissions(mixed $items): array
    {
        return $this->dependencies->normalizedPermissions($items);
    }

    public function dispatch(string $action): never
    {
        $routes = new \E258Tech\Routing\AdminApiRoutes();
        $def = $routes->definition($action);
        $controller = $this->resolveController($def['module']);
        $method = lcfirst(str_replace('_', '', ucwords($action, '_')));
        $httpMethod = $def['method'] ?? 'POST';

        $this->dependencies->kernel->handle(
            $def['module'],
            $def['action'],
            fn(\E258Tech\Http\Request $request): \E258Tech\Http\ApiResult
                => $controller->$method($request, $this->dependencies),
            $httpMethod
        );
    }

    private function resolveController(string $module): object
    {
        return match ($module) {
            'assinaturas'          => new Api\AssinaturasController(),
            'auth'                 => new Api\AuthController(),
            'autorizacao'          => new Api\AutorizacaoController(),
            'centros-custo'        => new Api\CentrosCustoController(),
            'clientes'             => new Api\ClientesController(),
            'compras'              => new Api\ComprasController(),
            'contabilidade'        => new Api\ContabilidadeController(),
            'crm'                  => new Api\CrmController(),
            'empresa'              => new Api\EmpresaController(),
            'faturacao'            => new Api\FaturacaoController(),
            'financeiro'           => new Api\FinanceiroController(),
            'gestao-escolar'       => new Api\GestaoEscolarController(),
            'impostos'             => new Api\ImpostosController(),
            'logistica'            => new Api\LogisticaController(),
            'multi-moeda'          => new Api\MultiMoedaController(),
            'notificacoes'         => new Api\NotificacoesController(),
            'pos'                  => new Api\PosController(),
            'pedido-ferias'        => new Api\PedidoFeriasController(),
            'recursos-humanos'     => new Api\RecursosHumanosController(),
            'recrutamento'         => new Api\RecrutamentoController(),
            'seguranca'            => new Api\SegurancaController(),
            'sistema-configuracao' => new Api\SistemaController(),
            'stock'                => new Api\StockController(),
            'tesouraria'           => new Api\TesourariaController(),
            'chat'                 => new Api\SelfServiceController(),
            'assiduidade'          => new Api\SelfServiceController(),
            'perfil'               => new Api\SelfServiceController(),
            default                => throw new \InvalidArgumentException("Controller nao encontrado para modulo: $module"),
        };
    }
}
