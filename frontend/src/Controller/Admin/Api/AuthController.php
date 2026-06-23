<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class AuthController
{
    public function sessaoRevogar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->authorization->revokeSessions(
                $request->int('id'),
                $request->bool('all')
            ),
            'error'
        );
    }
}
