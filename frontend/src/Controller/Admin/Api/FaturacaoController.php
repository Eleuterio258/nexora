<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class FaturacaoController
{
    // ── Séries ───────────────────────────────────────────────────────────

    public function serieSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'tipo' => $request->string('tipo'),
            'prefixo' => $request->string('prefixo'),
            'ano' => $request->int('ano'),
        ];

        return $d->result(fn() => $d->faturacao->createSeries($payload));
    }

    public function serieEstado(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->faturacao->setSeriesActive(
                $request->int('id') ?? 0,
                $request->bool('ativo')
            )
        );
    }

    // ── Orçamentos ───────────────────────────────────────────────────────

    public function orcamentoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'customer_id' => $request->int('customer_id') ?? 0,
            'moeda' => $request->string('moeda') ?: null,
            'validade' => $request->string('validade') ?: null,
            'observacoes' => $request->string('observacoes') ?: null,
        ];

        return $d->result(fn() => $d->faturacao->createQuote($payload));
    }

    public function orcamentoItemSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'product_id' => $request->int('product_id'),
            'descricao' => $request->string('descricao') ?: null,
            'quantidade' => $request->float('quantidade') ?? 0,
            'preco_unitario' => $request->float('preco_unitario') ?? 0,
            'desconto_percent' => $request->float('desconto_percent') ?? 0,
            'imposto_percent' => $request->float('imposto_percent') ?? 0,
        ];

        return $d->result(
            fn() => $d->faturacao->addQuoteItem($request->int('quote_id') ?? 0, $payload)
        );
    }

    public function orcamentoItemDelete(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->faturacao->removeQuoteItem(
                $request->int('quote_id') ?? 0,
                $request->int('item_id') ?? 0
            )
        );
    }

    public function orcamentoEstado(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->faturacao->setQuoteStatus(
                $request->int('id') ?? 0,
                $request->string('action')
            )
        );
    }

    // ── Encomendas ───────────────────────────────────────────────────────

    public function encomendaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'customer_id' => $request->int('customer_id') ?? 0,
            'moeda' => $request->string('moeda') ?: null,
            'observacoes' => $request->string('observacoes') ?: null,
        ];

        return $d->result(fn() => $d->faturacao->createOrder($payload));
    }

    public function encomendaEstado(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->faturacao->setOrderStatus(
                $request->int('id') ?? 0,
                $request->string('action')
            )
        );
    }

    // ── Faturas ──────────────────────────────────────────────────────────

    public function faturaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'customer_id' => $request->int('customer_id') ?? 0,
            'tipo' => $request->string('tipo') ?: 'normal',
            'moeda' => $request->string('moeda') ?: null,
            'due_date' => $request->string('due_date') ?: null,
            'observacoes' => $request->string('observacoes') ?: null,
        ];

        return $d->result(fn() => $d->faturacao->createInvoice($payload));
    }

    public function faturaItemSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'product_id' => $request->int('product_id'),
            'descricao' => $request->string('descricao') ?: null,
            'quantidade' => $request->float('quantidade') ?? 0,
            'preco_unitario' => $request->float('preco_unitario') ?? 0,
            'desconto_percent' => $request->float('desconto_percent') ?? 0,
            'imposto_percent' => $request->float('imposto_percent') ?? 0,
        ];

        return $d->result(
            fn() => $d->faturacao->addInvoiceItem($request->int('invoice_id') ?? 0, $payload)
        );
    }

    public function faturaEstado(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->faturacao->setInvoiceStatus(
                $request->int('id') ?? 0,
                $request->string('action')
            )
        );
    }

    /**
     * Serve o PDF de uma fatura já gerada no backend.
     * GET /nexora/api/fatura_pdf?id=<id>
     */
    public function faturaPdf(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = (int) ($_GET['id'] ?? 0);
        if ($id <= 0) {
            return new ApiResult(['erro' => 'Fatura invalida.'], 400);
        }

        $response = $d->gateway->download("/api/faturacao/invoices/$id/pdf");
        if ($response->status !== 200) {
            return new ApiResult(['erro' => 'PDF nao encontrado.'], $response->status);
        }

        header('Content-Type: ' . ($response->contentType ?: 'application/pdf'));
        header('Content-Disposition: inline; filename="fatura-' . $id . '.pdf"');
        echo $response->body;
        exit;
    }

    // ── Recibos ──────────────────────────────────────────────────────────

    public function reciboSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'invoice_id' => $request->int('invoice_id') ?? 0,
            'valor' => $request->float('valor') ?? 0,
            'payment_method_id' => $request->int('payment_method_id'),
            'referencia' => $request->string('referencia') ?: null,
            'observacoes' => $request->string('observacoes') ?: null,
        ];

        return $d->result(fn() => $d->faturacao->createReceipt($payload));
    }

    // ── Notas de crédito ─────────────────────────────────────────────────

    public function notaCreditoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'customer_id' => $request->int('customer_id') ?? 0,
            'invoice_id' => $request->int('invoice_id'),
            'motivo' => $request->string('motivo'),
            'moeda' => $request->string('moeda') ?: null,
            'observacoes' => $request->string('observacoes') ?: null,
        ];

        return $d->result(fn() => $d->faturacao->createCreditNote($payload));
    }

    public function notaCreditoItemSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'product_id' => $request->int('product_id'),
            'descricao' => $request->string('descricao') ?: null,
            'quantidade' => $request->float('quantidade') ?? 0,
            'preco_unitario' => $request->float('preco_unitario') ?? 0,
            'imposto_percent' => $request->float('imposto_percent') ?? 0,
        ];

        return $d->result(
            fn() => $d->faturacao->addCreditNoteItem($request->int('credit_note_id') ?? 0, $payload)
        );
    }

    public function notaCreditoEstado(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->faturacao->setCreditNoteStatus(
                $request->int('id') ?? 0,
                $request->string('action')
            )
        );
    }
}
