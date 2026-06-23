<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;
use E258Tech\Infrastructure\Auth\PhpSessionAuthorization;

final class StockController
{
    public function stockOperacao(Request $request, AdminApiDependencies $d): ApiResult
    {
        $operation = $request->string('operation');
        $action = str_ends_with($operation, '.delete') ? 'eliminar'
            : (str_ends_with($operation, '.create') ? 'criar' : 'editar');
        $authorization = new PhpSessionAuthorization();
        if (!$authorization->can('stock', $action)) {
            return new ApiResult(['erro' => 'Sem permissao para executar esta acao.'], 403);
        }
        $payload = $request->all()['payload'] ?? [];
        return $d->result(fn() => $d->stock->execute(
            $operation,
            $request->int('id'),
            is_array($payload) ? $payload : []
        ));
    }

    public function produtoCategoriaRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->products->deleteCategory($request->int('id') ?? 0));
    }

    public function produtoCategoriaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');
        $action = $id ? 'editar' : 'criar';

        $authorization = new PhpSessionAuthorization();
        if (!$authorization->can('stock', $action)) {
            return new ApiResult(['erro' => 'Sem permissao para executar esta acao.'], 403);
        }

        $payload = $id
            ? [
                'nome' => $request->string('nome') ?: null,
                'ativo' => $request->bool('ativo'),
            ]
            : [
                'codigo' => $request->string('codigo') ?: null,
                'nome' => $request->string('nome'),
                'descricao' => $request->string('descricao') ?: null,
            ];

        return $d->result(fn() => $d->products->saveCategory($id, $payload));
    }

    public function produtoMarcaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');
        $action = $id ? 'editar' : 'criar';

        $authorization = new PhpSessionAuthorization();
        if (!$authorization->can('stock', $action)) {
            return new ApiResult(['erro' => 'Sem permissao para executar esta acao.'], 403);
        }

        $payload = $id
            ? [
                'nome' => $request->string('nome') ?: null,
                'ativo' => $request->bool('ativo'),
            ]
            : [
                'codigo' => $request->string('codigo') ?: null,
                'nome' => $request->string('nome'),
                'descricao' => $request->string('descricao') ?: null,
            ];

        return $d->result(fn() => $d->products->saveBrand($id, $payload));
    }

    public function produtoPrecoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'tipo_preco' => $request->string('tipo_preco') ?: null,
            'moeda' => $request->string('moeda') ?: null,
            'valor' => $request->float('valor'),
            'inicia_em' => $request->string('inicia_em') ?: null,
            'fim_em' => $request->string('fim_em') ?: null,
        ];

        return $d->result(fn() => $d->products->setPrice($request->int('product_id') ?? 0, $payload));
    }

    public function produtoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');
        $action = $id ? 'editar' : 'criar';

        $authorization = new PhpSessionAuthorization();
        if (!$authorization->can('stock', $action)) {
            return new ApiResult(['erro' => 'Sem permissao para executar esta acao.'], 403);
        }

        $payload = $id
            ? [
                'nome' => $request->string('nome') ?: null,
                'descricao' => $request->string('descricao') ?: null,
                'ativo' => $request->bool('ativo'),
                'product_category_id' => $request->int('product_category_id'),
                'product_brand_id' => $request->int('product_brand_id'),
                'iva_percentual' => $request->float('iva_percentual'),
            ]
            : [
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'tipo' => $request->string('tipo') ?: null,
                'descricao' => $request->string('descricao') ?: null,
                'product_category_id' => $request->int('product_category_id'),
                'product_brand_id' => $request->int('product_brand_id'),
                'product_unit_id' => $request->int('product_unit_id'),
                'iva_percentual' => $request->float('iva_percentual'),
                'stock_minimo' => $request->float('stock_minimo'),
            ];

        return $d->result(fn() => $d->products->saveProduct($id, $payload));
    }

    public function produtoUnidadeSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');
        $action = $id ? 'editar' : 'criar';

        $authorization = new PhpSessionAuthorization();
        if (!$authorization->can('stock', $action)) {
            return new ApiResult(['erro' => 'Sem permissao para executar esta acao.'], 403);
        }

        $payload = $id
            ? [
                'nome' => $request->string('nome') ?: null,
                'simbolo' => $request->string('simbolo') ?: null,
            ]
            : [
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'simbolo' => $request->string('simbolo') ?: null,
            ];

        return $d->result(fn() => $d->products->saveUnit($id, $payload));
    }

    public function produtoVarianteSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'sku' => $request->string('sku'),
            'nome' => $request->string('nome') ?: null,
        ];

        return $d->result(fn() => $d->products->createVariant($request->int('product_id') ?? 0, $payload));
    }
}
