<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo htmlspecialchars($pageTitle) ?> · E258Tech</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/css/nexora.css">
    <style>
        @page { size: A4; margin: 18mm; }

        body {
            margin: 0;
            padding: var(--adm-sp-8);
            background: var(--adm-gray-50);
        }

        .proforma-actions {
            max-width: 210mm;
            margin: 0 auto var(--adm-sp-5);
            display: flex;
            justify-content: flex-end;
            gap: var(--adm-sp-3);
        }

        .proforma-sheet {
            max-width: 210mm;
            margin: 0 auto;
            background: #fff;
            padding: 16mm;
            border-radius: var(--adm-radius-lg);
            box-shadow: var(--adm-shadow-md);
        }

        .proforma-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            gap: var(--adm-sp-6);
            border-bottom: 2px solid var(--adm-gray-900);
            padding-bottom: var(--adm-sp-5);
            margin-bottom: var(--adm-sp-5);
        }

        .proforma-company h2 {
            font-family: var(--adm-font-h);
            font-size: 1.25rem;
            margin: 0 0 var(--adm-sp-2);
            color: var(--adm-gray-900);
        }

        .proforma-company p {
            margin: 0;
            font-size: var(--adm-text-sm);
            color: var(--adm-gray-600);
        }

        .proforma-doc {
            text-align: right;
        }

        .proforma-doc h1 {
            font-family: var(--adm-font-h);
            font-size: 1.5rem;
            letter-spacing: .05em;
            margin: 0 0 var(--adm-sp-2);
            color: var(--adm-gray-900);
        }

        .proforma-doc p {
            margin: 0;
            font-size: var(--adm-text-sm);
            color: var(--adm-gray-600);
        }

        .proforma-notice {
            background: var(--adm-gray-100);
            border: 1px solid var(--adm-gray-200);
            border-radius: var(--adm-radius-md);
            padding: var(--adm-sp-4);
            font-size: var(--adm-text-sm);
            font-weight: 600;
            color: var(--adm-gray-700);
            text-align: center;
            margin-bottom: var(--adm-sp-6);
        }

        .proforma-section-title {
            font-family: var(--adm-font-h);
            font-size: var(--adm-text-xs);
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: .05em;
            color: var(--adm-gray-500);
            margin: 0 0 var(--adm-sp-2);
        }

        .proforma-client {
            margin-bottom: var(--adm-sp-6);
        }

        .proforma-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: var(--adm-sp-6);
            font-size: var(--adm-text-sm);
        }

        .proforma-table th, .proforma-table td {
            border: 1px solid var(--adm-gray-200);
            padding: var(--adm-sp-2) var(--adm-sp-3);
            text-align: left;
        }

        .proforma-table th {
            background: var(--adm-gray-50);
            font-weight: 600;
            color: var(--adm-gray-700);
        }

        .proforma-table td.num, .proforma-table th.num {
            text-align: right;
        }

        .proforma-totals {
            width: 280px;
            margin-left: auto;
            margin-bottom: var(--adm-sp-6);
        }

        .proforma-totals div {
            display: flex;
            justify-content: space-between;
            padding: var(--adm-sp-1) 0;
            font-size: var(--adm-text-sm);
        }

        .proforma-totals .total {
            border-top: 2px solid var(--adm-gray-900);
            font-weight: 700;
            font-size: 1rem;
            margin-top: var(--adm-sp-2);
            padding-top: var(--adm-sp-2);
        }

        .proforma-observacoes {
            margin-bottom: var(--adm-sp-6);
        }

        .proforma-footer {
            margin-top: var(--adm-sp-8);
            padding-top: var(--adm-sp-4);
            border-top: 1px solid var(--adm-gray-200);
            font-size: var(--adm-text-xs);
            color: var(--adm-gray-500);
            text-align: center;
        }

        @media print {
            body { background: #fff; padding: 0; }
            .proforma-sheet { box-shadow: none; border-radius: 0; padding: 0; max-width: none; }
            .no-print { display: none !important; }
        }
    </style>
</head>
<body>

<div class="no-print proforma-actions">
    <a href="<?php echo htmlspecialchars($backUrl) ?>" class="adm-btn adm-btn-outline adm-btn-sm">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
        Voltar
    </a>
    <button class="adm-btn adm-btn-primary adm-btn-sm" onclick="window.print()">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg>
        Imprimir
    </button>
</div>

<div class="proforma-sheet">
    <div class="proforma-header">
        <div class="proforma-company">
            <h2><?php echo htmlspecialchars($companyNome) ?></h2>
            <p>NUIT: <?php echo $app->view->field($tax, 'nuit', '—') ?></p>
            <p>
                <?php echo $app->view->field($companyEndereco, 'endereco', '—') ?>
                <?php if (! empty($companyEndereco['cidade'])): ?>, <?php echo htmlspecialchars($companyEndereco['cidade']) ?><?php endif; ?>
            </p>
            <p>
                <?php if (! empty($companyContacto['telefone'])): ?>Tel: <?php echo htmlspecialchars($companyContacto['telefone']) ?><?php endif; ?>
                <?php if (! empty($companyContacto['email'])): ?> &middot; <?php echo htmlspecialchars($companyContacto['email']) ?><?php endif; ?>
            </p>
        </div>
        <div class="proforma-doc">
            <h1><?php echo htmlspecialchars($docTitulo) ?></h1>
            <p>Nº <?php echo htmlspecialchars($docNumero ?? '') ?></p>
            <?php foreach ($docDatasExtra as $label => $valor): ?>
            <p><?php echo htmlspecialchars($label) ?>: <?php echo htmlspecialchars($valor) ?></p>
            <?php endforeach; ?>
        </div>
    </div>

    <?php if (! empty($notice)): ?>
    <div class="proforma-notice">
        <?php echo htmlspecialchars($notice) ?>
    </div>
    <?php endif; ?>

    <div class="proforma-client">
        <p class="proforma-section-title">Cliente</p>
        <p style="font-weight:600;color:var(--adm-gray-900)"><?php echo htmlspecialchars($cliente['nome'] ?? ('#' . $customerId)) ?></p>
        <p>NUIT: <?php echo $app->view->field($cliente, 'nuit', '—') ?></p>
        <p>
            <?php echo $app->view->field($clienteEndereco, 'endereco', '—') ?>
            <?php if (! empty($clienteEndereco['cidade'])): ?>, <?php echo htmlspecialchars($clienteEndereco['cidade']) ?><?php endif; ?>
        </p>
        <p>
            <?php if (! empty($cliente['telefone'])): ?>Tel: <?php echo htmlspecialchars($cliente['telefone']) ?><?php endif; ?>
            <?php if (! empty($cliente['email'])): ?> &middot; <?php echo htmlspecialchars($cliente['email']) ?><?php endif; ?>
        </p>
    </div>

    <table class="proforma-table">
        <thead>
            <tr>
                <th>Descrição</th>
                <th class="num">Quantidade</th>
                <th class="num">Preço Unit.</th>
                <th class="num">Desconto %</th>
                <th class="num">Imposto %</th>
                <th class="num">Valor Imposto</th>
                <th class="num">Total</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($itens as $item): ?>
            <tr>
                <td><?php echo htmlspecialchars((string) ($item['descricao'] ?? '—')) ?></td>
                <td class="num"><?php echo number_format((float) $item['quantidade'], 2, ',', '.') ?></td>
                <td class="num"><?php echo number_format((float) $item['preco_unitario'], 2, ',', '.') ?></td>
                <td class="num"><?php echo number_format((float) $item['desconto_percent'], 2, ',', '.') ?>%</td>
                <td class="num"><?php echo number_format((float) $item['imposto_percent'], 2, ',', '.') ?>%</td>
                <td class="num"><?php echo number_format((float) $item['imposto_valor'], 2, ',', '.') ?></td>
                <td class="num"><?php echo number_format((float) $item['total'], 2, ',', '.') ?></td>
            </tr>
        <?php endforeach; ?>
        <?php if (! $itens): ?>
            <tr><td colspan="7" style="text-align:center;color:var(--adm-gray-500)">Sem itens registados.</td></tr>
        <?php endif; ?>
        </tbody>
    </table>

    <div class="proforma-totals">
        <div><span>Subtotal</span><span><?php echo number_format($subtotal, 2, ',', '.') ?></span></div>
        <div><span>Desconto</span><span><?php echo number_format($descontoTotal, 2, ',', '.') ?></span></div>
        <div><span>Imposto</span><span><?php echo number_format($impostoTotal, 2, ',', '.') ?></span></div>
        <div class="total"><span>Total</span><span><?php echo number_format($totalGeral, 2, ',', '.') ?> <?php echo htmlspecialchars($moeda) ?></span></div>
    </div>

    <?php if (! empty($observacoes)): ?>
    <div class="proforma-observacoes">
        <p class="proforma-section-title">Observações</p>
        <p><?php echo nl2br(htmlspecialchars($observacoes)) ?></p>
    </div>
    <?php endif; ?>

    <div class="proforma-footer">
        <?php echo htmlspecialchars($footerNote) ?>
    </div>
</div>

</body>
</html>
