<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class PosController
{
    public function posCatalogoRemove(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->pos->removeCatalogItem($request->int('id') ?? 0));
    }

    public function posCatalogoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'product_id' => $request->int('product_id') ?? 0,
            'product_variant_id' => $request->int('product_variant_id'),
            'codigo_barra' => $request->string('codigo_barra') ?: null,
            'preco_venda' => $request->float('preco_venda') ?? 0,
            'moeda' => $request->string('moeda') ?: 'MZN',
        ];

        return $d->result(fn() => $d->pos->addCatalogItem($payload));
    }

    public function posProdutosBuscar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->pos->searchProdutos($request->string('q'), $request->int('warehouse_id'))
        );
    }

    public function posSessaoAbrir(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'terminal_id' => $request->int('terminal_id') ?? 0,
            'opening_amount' => $request->float('opening_amount') ?? 0,
        ];

        return $d->result(fn() => $d->pos->openSession($payload));
    }

    public function posSessaoFechar(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'closing_amount' => $request->float('closing_amount') ?? 0,
        ];

        return $d->result(fn() => $d->pos->closeSession($request->int('id') ?? 0, $payload));
    }

    public function posTerminalSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'codigo' => $request->string('codigo'),
            'nome' => $request->string('nome'),
            'warehouse_id' => $request->int('warehouse_id'),
        ];

        return $d->result(fn() => $d->pos->createTerminal($payload));
    }

    public function posVendaCancelar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->pos->cancelSale($request->int('id') ?? 0));
    }

    public function posVendaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $data = $request->all();
        $payload = [
            'pos_session_id' => $request->int('pos_session_id') ?? 0,
            'customer_id' => $request->int('customer_id'),
            'itens' => $data['itens'] ?? [],
            'pagamentos' => $data['pagamentos'] ?? [],
        ];

        return $d->result(fn() => $d->pos->createSale($payload));
    }
}
