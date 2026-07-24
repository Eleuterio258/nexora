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

    /**
     * Gera e serve o PDF de uma fatura (normal ou pró-forma).
     * GET /nexora/api/fatura_pdf?id=<hash>
     *
     * Corre no PHP (não passa pelo middleware idhash do Go), por isso
     * descodificamos o id aqui. Junta os mesmos dados da pró-forma HTML
     * (empresa, cliente, itens) e produz um PDF com o FaturaPdfBuilder.
     */
    public function faturaPdf(Request $request, AdminApiDependencies $d): ApiResult
    {
        $authorization = new \E258Tech\Infrastructure\Auth\PhpSessionAuthorization();
        if (!$authorization->isAuthenticated() || !$authorization->can('faturacao', 'ver_documentos')) {
            return new ApiResult(['erro' => 'Sem permissao.'], 403);
        }

        $rawId = (string) ($_GET['id'] ?? '');
        $id = ctype_digit($rawId) ? (int) $rawId : $d->id->decode($rawId);
        if ($id <= 0) {
            return new ApiResult(['erro' => 'Fatura invalida.'], 400);
        }

        $faturaResp = $d->gateway->request('GET', "/api/faturacao/invoices/$id");
        if (!$faturaResp->successful()) {
            return new ApiResult(['erro' => 'Fatura nao encontrada.'], $faturaResp->status);
        }
        $fatura = $faturaResp->body['fatura'] ?? [];
        $itens  = $faturaResp->body['itens'] ?? [];

        // Cliente + endereço principal
        $customerId = (int) ($fatura['customer_id'] ?? 0);
        $cliente = $d->gateway->request('GET', "/api/clientes/$customerId")->body ?? [];
        $clienteEnderecos = $d->gateway->request('GET', "/api/clientes/$customerId/enderecos")->body ?? [];
        $clienteEndereco = $this->principal($clienteEnderecos, 'principal');

        // Empresa emitente (primeira empresa do tenant) + fiscal/endereço/contacto
        $companies = $d->gateway->request('GET', '/api/companies')->body ?? [];
        $company   = $companies[0] ?? null;
        $tax = $companyEndereco = $companyContacto = null;
        if ($company) {
            $cid = (int) $company['id'];
            $tax = $d->gateway->request('GET', "/api/companies/$cid/tax-info")->body ?? null;
            $addrs = $d->gateway->request('GET', "/api/companies/$cid/addresses")->body ?? [];
            $companyEndereco = $this->principalTipo($addrs, 'principal');
            $contacts = $d->gateway->request('GET', "/api/companies/$cid/contacts")->body ?? [];
            $companyContacto = $this->principal($contacts, 'principal');
        }
        $companyNome = !empty($company['nome_comercial']) ? $company['nome_comercial'] : ($company['nome'] ?? 'Empresa');

        // Totais derivados (subtotal / desconto), como na pró-forma
        $subtotal = $descontoTotal = 0.0;
        foreach ($itens as $item) {
            $base = (float) ($item['quantidade'] ?? 0) * (float) ($item['preco_unitario'] ?? 0);
            $subtotal      += $base;
            $descontoTotal += $base * (float) ($item['desconto_percent'] ?? 0) / 100;
        }

        $pdf = (new \E258Tech\Infrastructure\Pdf\FaturaPdfBuilder())->build([
            'fatura'          => $fatura,
            'itens'           => $itens,
            'company'         => $company,
            'companyNome'     => $companyNome,
            'tax'             => $tax,
            'companyEndereco' => $companyEndereco,
            'companyContacto' => $companyContacto,
            'cliente'         => is_array($cliente) ? $cliente : [],
            'clienteEndereco' => $clienteEndereco,
            'subtotal'        => $subtotal,
            'descontoTotal'   => $descontoTotal,
        ]);

        $nome = 'fatura-' . preg_replace('/[^A-Za-z0-9._-]/', '_', (string) ($fatura['numero'] ?? $id)) . '.pdf';
        header('Content-Type: application/pdf');
        header('Content-Disposition: inline; filename="' . $nome . '"');
        header('Content-Length: ' . (string) strlen($pdf));
        echo $pdf;
        exit;
    }

    /** Devolve o primeiro item marcado como principal (flag booleana), senão o primeiro. */
    private function principal(mixed $items, string $flag): ?array
    {
        if (!is_array($items) || !$items) {
            return null;
        }
        foreach ($items as $it) {
            if (!empty($it[$flag])) {
                return $it;
            }
        }
        return $items[0] ?? null;
    }

    /** Como principal(), mas o "principal" é um valor de campo tipo (ex.: tipo='principal'). */
    private function principalTipo(mixed $items, string $valor): ?array
    {
        if (!is_array($items) || !$items) {
            return null;
        }
        foreach ($items as $it) {
            if (($it['tipo'] ?? '') === $valor) {
                return $it;
            }
        }
        return $items[0] ?? null;
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
