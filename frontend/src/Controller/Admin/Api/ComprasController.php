<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class ComprasController
{
    public function compraDocumentoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $data = $request->all();
        $type = trim((string) ($data['type'] ?? ''));
        unset($data['type'], $data['csrf'], $data['csrf_token']);

        return $d->result(fn() => $d->purchases->createDocument($type, $data));
    }

    public function compraItemSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $data = $request->all();
        $type = trim((string) ($data['type'] ?? ''));
        unset($data['type'], $data['csrf'], $data['csrf_token']);

        return $d->result(fn() => $d->purchases->addItem($type, $data));
    }
}
