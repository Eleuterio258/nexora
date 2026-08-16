<?php

$id = $app->request->queryInt('id');
if (!$id) {
    header('Location: ' . $app->routes->path('orcamentos'));
    exit;
}

$resp = $app->nexora->call('GET', "/api/faturacao/quotes/$id");
if ($resp['status'] !== 200) {
    header('Location: ' . $app->routes->path('orcamentos'));
    exit;
}
$orcamento = $resp['body']['orcamento'] ?? [];
$itens     = $resp['body']['itens'] ?? [];

$cliente = $app->nexora->call('GET', '/api/clientes/' . $orcamento['customer_id'])['body'] ?? [];

$companies = $app->nexora->call('GET', '/api/companies')['body'] ?? [];
$company   = $companies[0] ?? [];
$companyNome = $company['nome_comercial'] ?? ($company['nome'] ?? 'Empresa');
?>
<!doctype html>
<html lang="pt">
<head>
<meta charset="utf-8">
<title>Orçamento <?= htmlspecialchars($orcamento['numero']) ?></title>
<style>
    body { font-family: Arial, sans-serif; color: #1a1a1a; padding: 40px; max-width: 800px; margin: 0 auto; }
    h1 { font-size: 20px; margin-bottom: 4px; }
    .muted { color: #666; font-size: 13px; }
    .head { display: flex; justify-content: space-between; margin-bottom: 24px; }
    table { width: 100%; border-collapse: collapse; margin-top: 16px; }
    th, td { padding: 8px; border-bottom: 1px solid #e5e5e5; text-align: left; font-size: 13px; }
    th { background: #f5f5f5; }
    .right { text-align: right; }
    .total-row td { font-weight: 700; border-top: 2px solid #333; }
    .print-btn { margin-top: 24px; }
    @media print { .print-btn { display: none; } }
</style>
</head>
<body>
<div class="head">
    <div>
        <h1><?= htmlspecialchars($companyNome) ?></h1>
        <?php if (!empty($company['nuit'])): ?><div class="muted">NUIT <?= htmlspecialchars($company['nuit']) ?></div><?php endif; ?>
    </div>
    <div style="text-align:right">
        <h1>Orçamento <?= htmlspecialchars($orcamento['numero']) ?></h1>
        <div class="muted">Data: <?= date('d/m/Y', strtotime($orcamento['created_at'])) ?></div>
        <?php if (!empty($orcamento['validade'])): ?><div class="muted">Validade: <?= date('d/m/Y', strtotime($orcamento['validade'])) ?></div><?php endif; ?>
    </div>
</div>

<div><strong>Cliente:</strong> <?= htmlspecialchars($cliente['nome'] ?? ('#' . $orcamento['customer_id'])) ?></div>
<?php if (!empty($cliente['nuit'])): ?><div class="muted">NUIT <?= htmlspecialchars($cliente['nuit']) ?></div><?php endif; ?>

<table>
    <thead>
        <tr><th>Descrição</th><th class="right">Qtd.</th><th class="right">Preço Unit.</th><th class="right">Desc.</th><th class="right">IVA</th><th class="right">Total</th></tr>
    </thead>
    <tbody>
    <?php foreach ($itens as $it): ?>
        <tr>
            <td><?= htmlspecialchars($it['descricao'] ?? '') ?></td>
            <td class="right"><?= number_format((float) $it['quantidade'], 2, ',', '.') ?></td>
            <td class="right"><?= number_format((float) $it['preco_unitario'], 2, ',', '.') ?></td>
            <td class="right"><?= number_format((float) $it['desconto_percent'], 1, ',', '.') ?>%</td>
            <td class="right"><?= number_format((float) $it['imposto_percent'], 1, ',', '.') ?>%</td>
            <td class="right"><?= number_format((float) $it['total'], 2, ',', '.') ?></td>
        </tr>
    <?php endforeach; ?>
    <tr class="total-row">
        <td colspan="5" class="right">Total</td>
        <td class="right"><?= number_format((float) $orcamento['total'], 2, ',', '.') ?> <?= htmlspecialchars($orcamento['moeda']) ?></td>
    </tr>
    </tbody>
</table>

<?php if (!empty($orcamento['observacoes'])): ?>
<p class="muted"><?= nl2br(htmlspecialchars($orcamento['observacoes'])) ?></p>
<?php endif; ?>

<div class="print-btn">
    <button onclick="window.print()">Imprimir</button>
</div>
</body>
</html>
