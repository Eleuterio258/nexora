<?php
declare(strict_types=1);

namespace E258Tech\Infrastructure\Pdf;

use Dompdf\Dompdf;
use Dompdf\Options;

/**
 * Gera o PDF de uma fatura (normal ou pró-forma) da Faturação.
 *
 * Auto-contido: o Dompdf corre com isRemoteEnabled=false, por isso todo o CSS
 * é inline e as cores da marca (--adm-green/… do nexora.css) vão em hexadecimal
 * directo. Layout em tabelas — o Dompdf não suporta bem flexbox/grid. Espelha
 * o documento_print.php (usado na pró-forma HTML), mas sem dependências externas.
 */
final class FaturaPdfBuilder
{
    private const VERDE     = '#10b981';
    private const CINZA_900 = '#111827';
    private const CINZA_700 = '#374151';
    private const CINZA_600 = '#4b5563';
    private const CINZA_500 = '#6b7280';
    private const CINZA_200 = '#e5e7eb';
    private const CINZA_100 = '#f3f4f6';
    private const CINZA_50  = '#f9fafb';

    public function build(array $d): string
    {
        $options = new Options();
        $options->set('isRemoteEnabled', false);
        $options->set('defaultFont', 'Helvetica');

        $dompdf = new Dompdf($options);
        $dompdf->loadHtml($this->render($d));
        $dompdf->setPaper('A4', 'portrait');
        $dompdf->render();

        return $dompdf->output();
    }

    private function e(?string $v): string
    {
        return htmlspecialchars($v ?? '', ENT_QUOTES, 'UTF-8');
    }

    private function n(float|int|string|null $v): string
    {
        return number_format((float) $v, 2, ',', '.');
    }

    /** Lê um campo de um array possivelmente nulo, com fallback. */
    private function field(?array $src, string $key, string $fallback = '—'): string
    {
        $v = $src[$key] ?? null;
        return ($v === null || $v === '') ? $fallback : $this->e((string) $v);
    }

    private function render(array $d): string
    {
        $fatura   = $d['fatura'] ?? [];
        $itens    = $d['itens'] ?? [];
        $company  = $d['company'] ?? null;
        $tax      = $d['tax'] ?? null;
        $cEnd     = $d['companyEndereco'] ?? null;
        $cCont    = $d['companyContacto'] ?? null;
        $cliente  = $d['cliente'] ?? [];
        $clEnd    = $d['clienteEndereco'] ?? null;

        $companyNome = $d['companyNome'] ?? ($company['nome'] ?? 'Empresa');
        $isProforma  = ($fatura['tipo'] ?? 'normal') === 'proforma';
        $docTitulo   = $isProforma ? 'FATURA PRÓ-FORMA' : 'FATURA';

        $subtotal      = (float) ($d['subtotal'] ?? 0);
        $descontoTotal = (float) ($d['descontoTotal'] ?? 0);
        $impostoTotal  = (float) ($fatura['imposto_total'] ?? 0);
        $totalGeral    = (float) ($fatura['total'] ?? 0);
        $moeda         = (string) ($fatura['moeda'] ?? '');
        $observacoes   = $fatura['observacoes'] ?? null;

        $dataEmissao = !empty($fatura['invoice_date']) ? date('d/m/Y', strtotime($fatura['invoice_date'])) : '—';
        $dataVenc    = !empty($fatura['due_date']) ? date('d/m/Y', strtotime($fatura['due_date'])) : null;

        // ── Cliente ──
        $clienteCidade = !empty($clEnd['cidade']) ? ', ' . $this->e($clEnd['cidade']) : '';
        $clienteTel    = !empty($cliente['telefone']) ? 'Tel: ' . $this->e($cliente['telefone']) : '';
        $clienteEmail  = !empty($cliente['email']) ? ($clienteTel ? ' · ' : '') . $this->e($cliente['email']) : '';

        // ── Empresa ──
        $companyCidade = !empty($cEnd['cidade']) ? ', ' . $this->e($cEnd['cidade']) : '';
        $companyTel    = !empty($cCont['telefone']) ? 'Tel: ' . $this->e($cCont['telefone']) : '';
        $companyEmail  = !empty($cCont['email']) ? ($companyTel ? ' · ' : '') . $this->e($cCont['email']) : '';

        // ── Linhas de itens ──
        $linhas = '';
        if ($itens) {
            foreach ($itens as $item) {
                $linhas .= '<tr>'
                    . '<td>' . $this->e((string) ($item['descricao'] ?? '—')) . '</td>'
                    . '<td class="num">' . $this->n($item['quantidade'] ?? 0) . '</td>'
                    . '<td class="num">' . $this->n($item['preco_unitario'] ?? 0) . '</td>'
                    . '<td class="num">' . $this->n($item['desconto_percent'] ?? 0) . '%</td>'
                    . '<td class="num">' . $this->n($item['imposto_percent'] ?? 0) . '%</td>'
                    . '<td class="num">' . $this->n($item['imposto_valor'] ?? 0) . '</td>'
                    . '<td class="num">' . $this->n($item['total'] ?? 0) . '</td>'
                    . '</tr>';
            }
        } else {
            $linhas = '<tr><td colspan="7" style="text-align:center;color:' . self::CINZA_500 . '">Sem itens registados.</td></tr>';
        }

        $obsHtml = '';
        if (!empty($observacoes)) {
            $obsHtml = '<div style="margin-bottom:18px">'
                . '<p class="sec-title">Observações</p>'
                . '<p style="margin:0;font-size:11px;color:' . self::CINZA_700 . '">'
                . nl2br($this->e((string) $observacoes))
                . '</p></div>';
        }

        $vencHtml = $dataVenc ? '<p>Vencimento: ' . $this->e($dataVenc) . '</p>' : '';
        $geradoEm = date('d/m/Y H:i');

        return <<<HTML
<!DOCTYPE html>
<html lang="pt">
<head>
<meta charset="UTF-8">
<style>
    @page { margin: 16mm; }
    * { font-family: Helvetica, Arial, sans-serif; }
    body { margin: 0; color: {$this->cinza900()}; font-size: 11px; }

    .header { width: 100%; border-bottom: 2px solid {$this->cinza900()}; padding-bottom: 12px; margin-bottom: 16px; }
    .header td { vertical-align: top; }
    .company-name { font-size: 18px; font-weight: bold; color: {$this->cinza900()}; margin: 0 0 4px; }
    .company-line { margin: 1px 0; font-size: 10px; color: {$this->cinza600()}; }

    .doc-box { text-align: right; }
    .doc-title { font-size: 20px; font-weight: bold; letter-spacing: 1px; color: {$this->verde()}; margin: 0 0 4px; }
    .doc-line { margin: 1px 0; font-size: 10px; color: {$this->cinza600()}; }

    .sec-title { font-size: 9px; font-weight: bold; text-transform: uppercase; letter-spacing: .5px; color: {$this->cinza500()}; margin: 0 0 4px; }
    .client { margin-bottom: 18px; }
    .client .name { font-weight: bold; color: {$this->cinza900()}; font-size: 12px; margin: 0 0 2px; }
    .client p { margin: 1px 0; font-size: 10px; color: {$this->cinza600()}; }

    table.items { width: 100%; border-collapse: collapse; margin-bottom: 16px; font-size: 10px; }
    table.items th, table.items td { border: 1px solid {$this->cinza200()}; padding: 5px 7px; text-align: left; }
    table.items th { background: {$this->cinza50()}; font-weight: bold; color: {$this->cinza700()}; }
    table.items td.num, table.items th.num { text-align: right; }

    table.totals { width: 250px; margin-left: auto; margin-bottom: 18px; border-collapse: collapse; }
    table.totals td { padding: 3px 0; font-size: 11px; }
    table.totals td.val { text-align: right; }
    table.totals tr.total td { border-top: 2px solid {$this->cinza900()}; font-weight: bold; font-size: 13px; padding-top: 6px; }

    .footer { margin-top: 30px; padding-top: 8px; border-top: 1px solid {$this->cinza200()}; font-size: 9px; color: {$this->cinza500()}; text-align: center; }
</style>
</head>
<body>

<table class="header">
    <tr>
        <td style="width:60%">
            <p class="company-name">{$this->e($companyNome)}</p>
            <p class="company-line">NUIT: {$this->field($tax, 'nuit')}</p>
            <p class="company-line">{$this->field($cEnd, 'endereco')}{$companyCidade}</p>
            <p class="company-line">{$companyTel}{$companyEmail}</p>
        </td>
        <td class="doc-box" style="width:40%">
            <p class="doc-title">{$docTitulo}</p>
            <p class="doc-line">Nº {$this->e((string) ($fatura['numero'] ?? ''))}</p>
            <p class="doc-line">Emissão: {$this->e($dataEmissao)}</p>
            {$vencHtml}
        </td>
    </tr>
</table>

<div class="client">
    <p class="sec-title">Cliente</p>
    <p class="name">{$this->e((string) ($cliente['nome'] ?? ('#' . ($fatura['customer_id'] ?? ''))))}</p>
    <p>NUIT: {$this->field($cliente, 'nuit')}</p>
    <p>{$this->field($clEnd, 'endereco')}{$clienteCidade}</p>
    <p>{$clienteTel}{$clienteEmail}</p>
</div>

<table class="items">
    <thead>
        <tr>
            <th>Descrição</th>
            <th class="num">Qtd.</th>
            <th class="num">Preço Unit.</th>
            <th class="num">Desc. %</th>
            <th class="num">Imp. %</th>
            <th class="num">Valor Imp.</th>
            <th class="num">Total</th>
        </tr>
    </thead>
    <tbody>
        {$linhas}
    </tbody>
</table>

<table class="totals">
    <tr><td>Subtotal</td><td class="val">{$this->n($subtotal)}</td></tr>
    <tr><td>Desconto</td><td class="val">{$this->n($descontoTotal)}</td></tr>
    <tr><td>Imposto</td><td class="val">{$this->n($impostoTotal)}</td></tr>
    <tr class="total"><td>Total</td><td class="val">{$this->n($totalGeral)} {$this->e($moeda)}</td></tr>
</table>

{$obsHtml}

<div class="footer">Documento gerado em {$geradoEm}</div>

</body>
</html>
HTML;
    }

    private function verde(): string { return self::VERDE; }
    private function cinza900(): string { return self::CINZA_900; }
    private function cinza700(): string { return self::CINZA_700; }
    private function cinza600(): string { return self::CINZA_600; }
    private function cinza500(): string { return self::CINZA_500; }
    private function cinza200(): string { return self::CINZA_200; }
    private function cinza50(): string { return self::CINZA_50; }
}
