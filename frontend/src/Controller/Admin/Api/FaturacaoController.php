<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class FaturacaoController
{
    public function encomendaEstado(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->invoicing->setOrderStatus(
                $request->int('id') ?? 0,
                $request->string('action')
            )
        );
    }

    public function encomendaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'customer_id' => $request->int('customer_id') ?? 0,
            'moeda' => $request->string('moeda') ?: null,
            'observacoes' => $request->string('observacoes') ?: null,
        ];

        return $d->result(fn() => $d->invoicing->createOrder($payload));
    }

    public function faturaEstado(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->invoicing->setInvoiceStatus(
                $request->int('id') ?? 0,
                $request->string('action')
            )
        );
    }

    public function faturaItemSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'product_id' => $request->int('product_id') ?? 0,
            'descricao' => $request->string('descricao') ?: null,
            'quantidade' => $request->float('quantidade') ?? 0,
            'preco_unitario' => $request->float('preco_unitario') ?? 0,
            'desconto_percent' => $request->float('desconto_percent') ?? 0,
            'imposto_percent' => $request->float('imposto_percent') ?? 0,
        ];

        return $d->result(
            fn() => $d->invoicing->addInvoiceItem($request->int('invoice_id') ?? 0, $payload)
        );
    }

    public function faturaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'customer_id' => $request->int('customer_id') ?? 0,
            'tipo' => $request->string('tipo') ?: 'normal',
            'moeda' => $request->string('moeda') ?: null,
            'due_date' => $request->string('due_date') ?: null,
            'observacoes' => $request->string('observacoes') ?: null,
        ];

        return $d->result(fn() => $d->invoicing->createInvoice($payload));
    }

    public function notaCreditoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'customer_id' => $request->int('customer_id') ?? 0,
            'invoice_id' => $request->int('invoice_id'),
            'motivo' => $request->string('motivo'),
            'moeda' => $request->string('moeda') ?: null,
            'observacoes' => $request->string('observacoes') ?: null,
        ];

        return $d->result(fn() => $d->invoicing->createCreditNote($payload));
    }

    public function orcamentoEstado(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->invoicing->setQuoteStatus(
                $request->int('id') ?? 0,
                $request->string('action')
            )
        );
    }

    public function orcamentoItemDelete(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->invoicing->removeQuoteItem(
                $request->int('quote_id') ?? 0,
                $request->int('item_id') ?? 0
            )
        );
    }

    public function orcamentoItemSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'product_id' => $request->int('product_id') ?? 0,
            'descricao' => $request->string('descricao') ?: null,
            'quantidade' => $request->float('quantidade') ?? 0,
            'preco_unitario' => $request->float('preco_unitario') ?? 0,
            'desconto_percent' => $request->float('desconto_percent') ?? 0,
            'imposto_percent' => $request->float('imposto_percent') ?? 0,
        ];

        return $d->result(
            fn() => $d->invoicing->addQuoteItem($request->int('quote_id') ?? 0, $payload)
        );
    }

    public function orcamentoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'customer_id' => $request->int('customer_id') ?? 0,
            'moeda' => $request->string('moeda') ?: null,
            'validade' => $request->string('validade') ?: null,
            'observacoes' => $request->string('observacoes') ?: null,
        ];

        return $d->result(fn() => $d->invoicing->createQuote($payload));
    }

    public function reciboSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'invoice_id' => $request->int('invoice_id') ?? 0,
            'valor' => $request->float('valor') ?? 0,
            'payment_method_id' => $request->int('payment_method_id'),
            'referencia' => $request->string('referencia') ?: null,
            'observacoes' => $request->string('observacoes') ?: null,
        ];

        return $d->result(fn() => $d->invoicing->createReceipt($payload));
    }

    public function serieEstado(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->invoicing->setSeriesActive(
                $request->int('id') ?? 0,
                $request->bool('ativo')
            )
        );
    }

    public function serieSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'tipo' => $request->string('tipo'),
            'prefixo' => $request->string('prefixo'),
            'ano' => $request->int('ano'),
        ];

        return $d->result(fn() => $d->invoicing->createSeries($payload));
    }
}
