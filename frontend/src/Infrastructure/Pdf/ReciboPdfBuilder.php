<?php
declare(strict_types=1);

namespace E258Tech\Infrastructure\Pdf;

use Dompdf\Dompdf;
use Dompdf\Options;

/**
 * Gera o PDF do recibo de vencimento com a identidade visual E258Tech.
 * Layout em tabelas (o Dompdf não suporta bem flexbox/grid), cores da marca
 * em hexadecimal directo (--adm-green/--adm-green-dark de nexora.css).
 */
final class ReciboPdfBuilder
{
    private const VERDE       = '#10b981';
    private const VERDE_ESC   = '#059669';
    private const VERDE_CLARO = '#ecfdf5';
    private const CINZA_500   = '#6b7280';
    private const CINZA_100   = '#f3f4f6';
    private const CINZA_900   = '#111827';

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

    private function logoBase64(): string
    {
        $path = dirname(__DIR__, 3) . '/assets/images/e258tech-logo.png';
        if (!is_file($path)) {
            return '';
        }
        return 'data:image/png;base64,' . base64_encode((string) file_get_contents($path));
    }

    private function fmt(?float $v, bool $podeVer): string
    {
        if (!$podeVer || $v === null) {
            return '—';
        }
        return number_format($v, 2, ',', '.') . ' MT';
    }

    private function e(?string $v): string
    {
        return htmlspecialchars($v ?? '', ENT_QUOTES, 'UTF-8');
    }

    private function render(array $d): string
    {
        $podeVer   = $d['podeVerSalarios'] ?? true;
        $proventos = $d['proventos'] ?? [];
        $descontos = $d['descontos'] ?? [];
        $logo      = $this->logoBase64();
        $estadoPago = ($d['estado'] ?? '') === 'pago';
        $estadoLabel = $estadoPago ? 'Pago' : 'Pendente';

        $verde       = self::VERDE;
        $verdeEsc    = self::VERDE_ESC;
        $verdeClaro  = self::VERDE_CLARO;
        $cinza500    = self::CINZA_500;
        $cinza100    = self::CINZA_100;
        $cinza900    = self::CINZA_900;

        $linhasProventos = '<tr><td>Salário Base</td><td class="val">' . $this->fmt((float) ($d['salarioBase'] ?? 0), $podeVer) . '</td></tr>';
        foreach ($proventos as $p) {
            $linhasProventos .= '<tr><td>' . $this->e($p['nome']) . '</td><td class="val">' . $this->fmt($p['valor'] !== null ? (float) $p['valor'] : null, $podeVer) . '</td></tr>';
        }
        $totalBruto = (float) ($d['salarioBase'] ?? 0) + (float) ($d['totalProventos'] ?? 0);
        $linhasProventos .= '<tr class="total"><td>Total Proventos</td><td class="val">' . $this->fmt($totalBruto, $podeVer) . '</td></tr>';

        if ($descontos) {
            $linhasDescontos = '';
            foreach ($descontos as $dsc) {
                $linhasDescontos .= '<tr><td>' . $this->e($dsc['nome']) . '</td><td class="val">' . $this->fmt($dsc['valor'] !== null ? (float) $dsc['valor'] : null, $podeVer) . '</td></tr>';
            }
        } else {
            $linhasDescontos = '<tr><td colspan="2" class="muted"><em>Sem descontos registados</em></td></tr>';
        }
        $linhasDescontos .= '<tr class="total"><td>Total Descontos</td><td class="val">' . $this->fmt((float) ($d['totalDescontos'] ?? 0), $podeVer) . '</td></tr>';

        $func = $d['funcionario'] ?? [];
        $infoRows = [
            ['Nome Completo', $func['nomeCompleto'] ?? '—'],
            ['Nº Funcionário', $func['numeroFuncionario'] ?? '—'],
            ['NUIT', $func['nuit'] ?? '—'],
            ['Cargo', $func['cargo'] ?? '—'],
            ['Departamento', $func['unidadeNome'] ?? '—'],
        ];
        if (!empty($func['tipoContratoLabel'])) {
            $infoRows[] = ['Tipo de Contrato', $func['tipoContratoLabel']];
        }
        $infoHtml = '';
        foreach (array_chunk($infoRows, 3) as $linha) {
            $infoHtml .= '<tr>';
            foreach ($linha as $par) {
                $infoHtml .= '<td class="info-label">' . $this->e($par[0]) . '<br><span class="info-value">' . $this->e((string) $par[1]) . '</span></td>';
            }
            $infoHtml .= '</tr>';
        }

        return <<<HTML
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
    @page { margin: 28px 34px; }
    body { font-family: Helvetica, sans-serif; font-size: 10.5px; color: {$cinza900}; }
    table { width: 100%; border-collapse: collapse; }
    .header-table td { vertical-align: top; padding-bottom: 14px; border-bottom: 2px solid {$verde}; }
    .logo { height: 30px; margin-bottom: 6px; }
    .empresa h2 { font-size: 13px; margin: 0 0 2px; }
    .empresa p { font-size: 9px; color: {$cinza500}; margin: 1px 0; }
    .titulo { text-align: right; }
    .titulo h3 { font-size: 12px; color: {$verdeEsc}; margin: 0 0 4px; }
    .titulo p { font-size: 9px; margin: 1px 0; }
    .badge { display:inline-block; padding: 2px 8px; border-radius: 10px; font-size: 8px; font-weight: bold; }
    .badge-pago { background: {$verdeClaro}; color: {$verdeEsc}; }
    .badge-pendente { background: {$cinza100}; color: {$cinza500}; }
    .section-title { font-size: 8.5px; font-weight: bold; text-transform: uppercase; letter-spacing: .04em; color: {$verdeEsc}; margin: 14px 0 6px; }
    .info-table { background: #f9fafb; border-radius: 6px; }
    .info-table td { padding: 6px 10px; width: 33%; }
    .info-label { font-size: 8px; color: {$cinza500}; }
    .info-value { font-size: 10px; font-weight: bold; }
    .items-table th { background: {$verdeClaro}; color: {$verdeEsc}; text-align: left; padding: 5px 8px; font-size: 8.5px; text-transform: uppercase; }
    .items-table td { padding: 4px 8px; border-bottom: 1px solid {$cinza100}; }
    .items-table td.val { text-align: right; font-weight: bold; }
    .items-table tr.total td { background: #f9fafb; font-weight: bold; }
    .muted { color: {$cinza500}; }
    .totais-table { margin-top: 14px; background: {$verdeEsc}; border-radius: 6px; color: #fff; }
    .totais-table td { text-align: center; padding: 10px; width: 33%; }
    .totais-table .label { font-size: 8px; opacity: .85; }
    .totais-table .value { font-size: 12px; font-weight: bold; }
    .totais-table .liquido { background: rgba(255,255,255,.18); border-radius: 4px; }
    .totais-table .liquido .value { font-size: 14px; }
    .footer-table { margin-top: 20px; padding-top: 10px; border-top: 1px solid {$cinza100}; font-size: 8.5px; color: {$cinza500}; }
    .assinatura { text-align: center; }
    .assinatura .linha { border-top: 1px solid #9ca3af; width: 140px; margin: 20px auto 3px; }
</style>
</head>
<body>
    <table class="header-table">
        <tr>
            <td class="empresa" style="width:60%">
                {$this->imgTag($logo)}
                <h2>{$this->e($d['empresaNome'] ?? 'Empresa')}</h2>
                {$this->optionalP($d['empresaNuit'] ?? null, 'NUIT: ')}
                {$this->optionalP($d['empresaMorada'] ?? null, '')}
            </td>
            <td class="titulo" style="width:40%">
                <h3>Recibo de Vencimento</h3>
                <p><strong>Período:</strong> {$this->e($d['periodo'] ?? '')}</p>
                <p><strong>Nº Recibo:</strong> RV-{$this->e(str_pad((string) ($d['reciboId'] ?? 0), 6, '0', STR_PAD_LEFT))}</p>
                <p><span class="badge {$this->badgeClass($estadoPago)}">{$estadoLabel}</span></p>
            </td>
        </tr>
    </table>

    <div class="section-title">Dados do Funcionário</div>
    <table class="info-table">{$infoHtml}</table>

    <div class="section-title">Rendimentos</div>
    <table class="items-table">
        <thead><tr><th>Descrição</th><th style="text-align:right">Valor (MT)</th></tr></thead>
        <tbody>{$linhasProventos}</tbody>
    </table>

    <div class="section-title">Descontos</div>
    <table class="items-table">
        <thead><tr><th>Descrição</th><th style="text-align:right">Valor (MT)</th></tr></thead>
        <tbody>{$linhasDescontos}</tbody>
    </table>

    <table class="totais-table">
        <tr>
            <td><div class="label">Salário Bruto</div><div class="value">{$this->fmt($totalBruto, $podeVer)}</div></td>
            <td><div class="label">Total Descontos</div><div class="value">{$this->fmt((float) ($d['totalDescontos'] ?? 0), $podeVer)}</div></td>
            <td class="liquido"><div class="label">Salário Líquido</div><div class="value">{$this->fmt($d['salarioLiquido'] !== null ? (float) $d['salarioLiquido'] : null, $podeVer)}</div></td>
        </tr>
    </table>

    <table class="footer-table">
        <tr>
            <td style="width:34%">Gerado em: {$this->e($d['geradoEm'] ?? '')}</td>
            <td class="assinatura" style="width:33%"><div class="linha"></div>Assinatura do Funcionário</td>
            <td class="assinatura" style="width:33%"><div class="linha"></div>Recursos Humanos</td>
        </tr>
    </table>
</body>
</html>
HTML;
    }

    private function imgTag(string $base64): string
    {
        return $base64 === '' ? '' : '<img class="logo" src="' . $base64 . '" alt="E258Tech">';
    }

    private function optionalP(?string $valor, string $prefixo): string
    {
        if (empty($valor)) {
            return '';
        }
        return '<p>' . $this->e($prefixo . $valor) . '</p>';
    }

    private function badgeClass(bool $pago): string
    {
        return $pago ? 'badge-pago' : 'badge-pendente';
    }
}
