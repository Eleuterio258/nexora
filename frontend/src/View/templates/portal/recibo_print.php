<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recibo · <?= htmlspecialchars($cobranca['numero'] ?? '') ?></title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: Arial, sans-serif; font-size: 11pt; color: #000; background: #fff; padding: 1.5cm; }

        .header { display: flex; justify-content: space-between; align-items: flex-start;
            margin-bottom: 1.5rem; border-bottom: 2px solid #0369A1; padding-bottom: .75rem; }
        .header-school { font-size: 13pt; font-weight: bold; color: #0369A1; }

        h2 { font-size: 16pt; color: #0C4A6E; margin-bottom: 1rem; text-align: center; }

        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: .5rem 2rem;
            border: 1px solid #ddd; border-radius: 6px; padding: 1rem; margin-bottom: 1rem; font-size: 10pt; }
        .info-row { display: flex; flex-direction: column; }
        .info-label { font-size: 8.5pt; color: #666; text-transform: uppercase; letter-spacing: .03em; }
        .info-val { font-weight: bold; color: #000; margin-top: .15rem; }

        .amount-box { background: #F0FDF4; border: 1.5px solid #86EFAC; border-radius: 8px;
            padding: 1rem; text-align: center; margin: 1rem 0; }
        .amount-label { font-size: 9pt; color: #15803D; text-transform: uppercase; }
        .amount-val { font-size: 22pt; font-weight: bold; color: #15803D; margin-top: .25rem; }

        table { width: 100%; border-collapse: collapse; font-size: 10pt; margin-top: .5rem; }
        th { background: #f1f5f9; padding: .4rem .6rem; text-align: left; font-size: 9pt; border-bottom: 1px solid #ddd; }
        td { padding: .35rem .6rem; border-bottom: 1px solid #e5e7eb; }

        .footer { margin-top: 2rem; font-size: 8pt; color: #666; border-top: 1px solid #ddd;
            padding-top: .5rem; display: flex; justify-content: space-between; }
        .stamp { text-align: center; margin-top: 1.5rem; border: 1px dashed #0369A1;
            border-radius: 8px; padding: .75rem; color: #0369A1; font-size: 9pt; }

        @media print {
            body { padding: 1cm; }
            @page { margin: 1.5cm; size: A5; }
        }
    </style>
</head>
<body>

<div class="header">
    <div>
        <div class="header-school">Portal Escolar — Nexora ERP</div>
        <div style="font-size:9pt;color:#555;margin-top:.2rem">Comprovativo de Pagamento</div>
    </div>
    <div style="font-size:9pt;color:#555;text-align:right">
        Emitido: <?= date('d/m/Y H:i') ?><br>
        Nº <?= htmlspecialchars($cobranca['numero'] ?? '') ?>
    </div>
</div>

<h2>Recibo de Pagamento</h2>

<!-- Info da cobrança -->
<div class="info-grid">
    <div class="info-row">
        <span class="info-label">Aluno</span>
        <span class="info-val"><?= htmlspecialchars($cobranca['aluno']['nome'] ?? '') ?></span>
    </div>
    <div class="info-row">
        <span class="info-label">Código</span>
        <span class="info-val"><?= htmlspecialchars($cobranca['aluno']['codigo'] ?? '') ?></span>
    </div>
    <div class="info-row">
        <span class="info-label">Descrição</span>
        <span class="info-val"><?= htmlspecialchars($cobranca['descricao'] ?? '') ?></span>
    </div>
    <div class="info-row">
        <span class="info-label">Referência / Período</span>
        <span class="info-val"><?= htmlspecialchars($cobranca['mes_referencia'] ?? $cobranca['numero'] ?? '') ?></span>
    </div>
    <?php if (!empty($cobranca['data_vencimento'])): ?>
    <div class="info-row">
        <span class="info-label">Data de vencimento</span>
        <span class="info-val"><?= date('d/m/Y', strtotime($cobranca['data_vencimento'])) ?></span>
    </div>
    <?php endif; ?>
    <div class="info-row">
        <span class="info-label">Estado</span>
        <span class="info-val" style="color:#15803D"><?= ucfirst($cobranca['status'] ?? '') ?></span>
    </div>
</div>

<!-- Valor total pago -->
<?php $valorPago = (float)($cobranca['valor_pago'] ?? $cobranca['valor'] ?? 0); ?>
<div class="amount-box">
    <div class="amount-label">Total pago</div>
    <div class="amount-val"><?= number_format($valorPago, 2, ',', '.') ?> <?= htmlspecialchars($cobranca['moeda'] ?? 'MZN') ?></div>
</div>

<!-- Detalhe dos pagamentos -->
<?php if (!empty($cobranca['pagamentos'])): ?>
<h3 style="font-size:11pt;margin:.75rem 0 .4rem;color:#334155">Histórico de pagamentos</h3>
<table>
    <thead>
        <tr>
            <th>Data</th>
            <th>Método</th>
            <th>Referência</th>
            <th style="text-align:right">Valor</th>
        </tr>
    </thead>
    <tbody>
    <?php foreach ($cobranca['pagamentos'] as $p): ?>
    <tr>
        <td><?= !empty($p['pago_em']) ? date('d/m/Y H:i', strtotime($p['pago_em'])) : '—' ?></td>
        <td><?= htmlspecialchars(strtoupper($p['metodo'] ?? '')) ?></td>
        <td style="font-size:.9em;color:#555"><?= htmlspecialchars($p['referencia'] ?? '—') ?></td>
        <td style="text-align:right;font-weight:bold"><?= number_format((float)($p['valor'] ?? 0), 2, ',', '.') ?> <?= htmlspecialchars($p['moeda'] ?? 'MZN') ?></td>
    </tr>
    <?php endforeach; ?>
    </tbody>
</table>
<?php endif; ?>

<div class="stamp">
    <i style="font-size:1.2em">✓</i> Pagamento confirmado pelo sistema em <?= date('d/m/Y') ?>
</div>

<div class="footer">
    <span>Nexora ERP · Portal do Aluno</span>
    <span>Gerado em <?= date('d/m/Y \à\s H:i') ?></span>
</div>

<script>window.onload = function() { window.print(); }</script>
</body>
</html>
