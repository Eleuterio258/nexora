<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin;

use E258Tech\Http\ApiResult;
use E258Tech\Infrastructure\Security\IdHasher;
use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\Authorization\AuthorizationAdminService;
use E258Tech\Model\Service\School\SchoolService;

final readonly class AdminApiDependencies
{
    public function __construct(
        public AdminApiKernel $kernel,
        public NexoraGateway $gateway,
        public AuthorizationAdminService $authorization,
        public SchoolService $school,
        public IdHasher $id,
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
