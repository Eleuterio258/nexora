<?php
declare(strict_types=1);

namespace E258Tech\Infrastructure\Pdf;

use Dompdf\Dompdf;
use Dompdf\Options;

/**
 * Gera o Contrato Individual de Trabalho oficial da E258Tech em PDF.
 * Baseado no modelo DOCX, com duas variantes:
 * - Com participação societária (50% das quotas)
 * - Sem participação societária
 */
final class ContratoE258TechBuilder
{
    public function build(array $d, bool $comParticipacao = false): string
    {
        $html = $this->render($d, $comParticipacao);

        $options = new Options();
        $options->set('isRemoteEnabled', false);
        $options->set('defaultFont', 'DejaVu Sans');
        $options->set('isHtml5ParserEnabled', true);

        $dompdf = new Dompdf($options);
        $dompdf->loadHtml($html, 'UTF-8');
        $dompdf->setPaper('A4', 'portrait');
        $dompdf->render();

        return $dompdf->output();
    }

    private function render(array $d, bool $comParticipacao): string
    {
        $empresa = $d['empresa'] ?? [];
        $func    = $d['funcionario'] ?? [];
        $contr   = $d['contrato'] ?? [];

        $empresaNome   = $this->e($empresa['nome'] ?? 'e258tech, Lda');
        $empresaNuit   = $this->e($empresa['nuit'] ?? '402134951');
        $empresaMorada = $this->e($empresa['morada'] ?? 'Maputo, Moçambique');

        $funcNome    = $this->e($func['nome_completo'] ?? '—');
        $funcBI      = $this->e($func['bi'] ?? ($func['nuit'] ?? '—'));
        $funcNuit    = $this->e($func['nuit'] ?? '—');
        $funcMorada  = $this->e($func['endereco'] ?? '—');
        $funcGenero  = ($func['genero'] ?? '') === 'F' ? 'F' : 'M';
        $artigoMai   = $funcGenero === 'F' ? 'A' : 'O';
        $artigoMin   = $funcGenero === 'F' ? 'a' : 'o';
        $trabalhador = $funcGenero === 'F' ? 'Trabalhadora' : 'Trabalhador';
        $cargo       = $this->e($contr['funcao'] ?? $func['cargo'] ?? '—');
        $salario     = $this->fmt($contr['salario'] ?? $func['salario_base'] ?? null);
        $dataExtenso = date('d/m/Y');
        $dataDia     = date('d');
        $dataMes     = date('m');
        $dataAno     = date('Y');

        $logo = $this->logoBase64();
        $logoHtml = $logo ? '<img src="' . $logo . '" style="height:34px;margin-bottom:8px;" alt="E258Tech">' : '';

        $clausula3 = $comParticipacao
            ? <<<CLAUSULA3
    <p><strong>Cláusula 3.ª – Participação Societária</strong></p>
    <p>A {$trabalhador} é titular de 50% das quotas da {$empresaNome}. A qualidade de sócia é independente da presente relação laboral. Os direitos societários são regulados pelo contrato de sociedade.</p>
CLAUSULA3
            : '';

        $numClausula4 = $comParticipacao ? '4' : '3';
        $numClausula5 = $comParticipacao ? '5' : '4';
        $numClausula6 = $comParticipacao ? '6' : '5';
        $numClausula7 = $comParticipacao ? '7' : '6';
        $numClausula8 = $comParticipacao ? '8' : '7';
        $numClausula9 = $comParticipacao ? '9' : '8';

        return <<<HTML
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<style>
    @page { margin: 30px 36px; }
    body { font-family: DejaVu Sans, sans-serif; font-size: 11px; line-height: 1.7; color: #111827; text-align: justify; }
    .header { text-align: center; border-bottom: 2px solid #1e40af; padding-bottom: 12px; margin-bottom: 24px; }
    .header h2 { margin: 0; font-size: 15px; color: #1e3a8a; }
    .title { text-align: center; font-size: 13px; font-weight: bold; text-transform: uppercase; margin: 18px 0 14px; color: #1e3a8a; }
    p { margin: 0 0 8px; }
    strong { color: #1e3a8a; }
    .signature { margin-top: 40px; width: 100%; }
    .signature td { width: 50%; text-align: center; vertical-align: top; padding-top: 30px; }
    .signature .line { border-top: 1px solid #6b7280; width: 200px; margin: 0 auto 4px; }
    .footer { margin-top: 30px; font-size: 8px; color: #6b7280; text-align: center; }
    .underline { display: inline-block; min-width: 120px; border-bottom: 1px solid #111827; text-align: center; }
</style>
</head>
<body>
    <div class="header">
        {$logoHtml}
        <h2>{$empresaNome}</h2>
        <div style="font-size:9px;color:#6b7280;">NUIT: {$empresaNuit} · {$empresaMorada}</div>
    </div>

    <div class="title">Contrato Individual de Trabalho</div>

    <p><strong>Entre:</strong> {$empresaNome}, sociedade comercial de direito moçambicano, com sede em <span class="underline">{$empresaMorada}</span>, NUIT <span class="underline">{$empresaNuit}</span>, representada por <span class="underline">&nbsp;</span>, doravante designada por <strong>EMPREGADOR</strong>.</p>

    <p><strong>E</strong></p>

    <p><strong>Nome:</strong> <span class="underline">{$funcNome}</span></p>
    <p><strong>BI:</strong> <span class="underline">{$funcBI}</span></p>
    <p><strong>NUIT:</strong> <span class="underline">{$funcNuit}</span></p>
    <p><strong>Morada:</strong> <span class="underline">{$funcMorada}</span></p>

    <p>Doravante designad{$artigoMin} por <strong>{$trabalhador}</strong>.</p>

    <p><strong>Cláusula 1.ª – Objecto</strong></p>
    <p>O presente contrato regula a prestação de trabalho subordinado d{$artigoMin} {$trabalhador} à {$empresaNome}.</p>

    <p><strong>Cláusula 2.ª – Cargo</strong></p>
    <p>{$artigoMai} {$trabalhador} exercerá o cargo de <strong>{$cargo}</strong>.</p>

{$clausula3}

    <p><strong>Cláusula {$numClausula4}.ª – Horário</strong></p>
    <p>Segunda a quinta-feira, das 08h00 às 16h00.</p>

    <p><strong>Cláusula {$numClausula5}.ª – Descanso</strong></p>
    <p>Dias de descanso: sexta-feira, sábado e domingo.</p>

    <p><strong>Cláusula {$numClausula6}.ª – Remuneração</strong></p>
    <p>{$artigoMai} {$trabalhador} receberá o valor líquido de <strong>{$salario}</strong> por mês. O pagamento será efectuado por transferência bancária entre o dia 30 do mês em curso e o dia 10 do mês seguinte. O Empregador suportará os encargos legais, incluindo INSS e demais impostos aplicáveis, para garantir o valor líquido acordado.</p>

    <p><strong>Cláusula {$numClausula7}.ª – Confidencialidade</strong></p>
    <p>{$artigoMai} {$trabalhador} manterá sigilo sobre todas as informações da empresa.</p>

    <p><strong>Cláusula {$numClausula8}.ª – Propriedade Intelectual</strong></p>
    <p>Todos os trabalhos desenvolvidos no âmbito das funções pertencem à {$empresaNome}, salvo acordo escrito em contrário.</p>

    <p><strong>Cláusula {$numClausula9}.ª – Disposições Finais</strong></p>
    <p>Os casos omissos serão regulados pela legislação moçambicana. Feito em duas vias.</p>

    <p>Maputo, {$dataDia}/{$dataMes}/{$dataAno}</p>

    <table class="signature">
        <tr>
            <td><div class="line"></div><div style="font-size:9px;color:#6b7280;">Pela {$empresaNome}</div></td>
            <td><div class="line"></div><div style="font-size:9px;color:#6b7280;">{$artigoMai} {$trabalhador}</div></td>
        </tr>
    </table>

    <div class="footer">Documento gerado automaticamente pelo Nexora ERP · {$dataExtenso}</div>
</body>
</html>
HTML;
    }

    private function logoBase64(): string
    {
        $path = dirname(__DIR__, 3) . '/assets/images/e258tech-logo.png';
        if (!is_file($path)) {
            return '';
        }
        return 'data:image/png;base64,' . base64_encode((string) file_get_contents($path));
    }

    private function e(?string $v): string
    {
        if ($v === null) {
            return '';
        }
        return htmlentities($v, ENT_QUOTES | ENT_HTML5, 'UTF-8');
    }

    private function fmt(?float $v): string
    {
        if ($v === null) {
            return '—';
        }
        return number_format($v, 2, ',', '.') . ' MT';
    }
}
