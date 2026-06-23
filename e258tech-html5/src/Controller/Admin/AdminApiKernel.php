<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin;

use E258Tech\Model\Contract\Authorization;
use E258Tech\Infrastructure\Http\HttpClientException;
use E258Tech\Infrastructure\Security\WebSecurity;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;
use E258Tech\Http\ServerRequest;
use Throwable;

final class AdminApiKernel
{
    public function __construct(
        private readonly Authorization $authorization,
        private readonly ServerRequest $request,
        private readonly WebSecurity $security
    ) {
    }

    public function handle(
        string $module,
        string $action,
        callable $handler,
        string $method = 'POST',
        string $errorKey = 'erro'
    ): never {
        try {
            if ($this->request->method() !== strtoupper($method)) {
                $this->respond([$errorKey => 'Metodo nao permitido.'], 405);
            }

            if (!$this->authorization->isAuthenticated()) {
                $this->respond([$errorKey => 'Nao autorizado.'], 401);
            }

            if ($action !== '' && !$this->authorization->can($module, $action)) {
                $this->respond([$errorKey => 'Sem permissao para executar esta acao.'], 403);
            }

            $request = Request::fromServerRequest($this->request);
            if (strtoupper($method) !== 'GET') {
                if (!$this->security->hasValidCsrf($request->csrfToken())) {
                    $this->respond([$errorKey => 'Token CSRF invalido.'], 403);
                }
            }

            $result = $handler($request);
            if (!$result instanceof ApiResult) {
                throw new \LogicException('O endpoint deve devolver ApiResult.');
            }

            $this->respond($result->body, $result->status);
        } catch (HttpClientException $exception) {
            error_log('[admin-api] ' . $exception->getMessage());
            $this->respond([$errorKey => 'Servico Nexora temporariamente indisponivel.'], 503);
        } catch (Throwable $exception) {
            error_log(sprintf(
                '[admin-api] %s em %s:%d',
                $exception->getMessage(),
                $exception->getFile(),
                $exception->getLine()
            ));
            $this->respond([$errorKey => 'Erro interno do servidor.'], 500);
        }
    }

    private function respond(array $body, int $status): never
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($body, JSON_UNESCAPED_UNICODE);
        exit;
    }
}
