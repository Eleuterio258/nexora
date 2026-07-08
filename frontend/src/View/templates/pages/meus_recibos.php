<?php

$mesAtual = (int) date('m');
$anoAtual = (int) date('Y');
$anoFiltro = $app->request->queryInt('ano', $anoAtual);
if ($anoFiltro < 2020 || $anoFiltro > $anoAtual + 1) $anoFiltro = $anoAtual;

$resp    = $app->nexora->call('GET', '/api/self-service/recibos');
$recibos = ($resp['status'] === 200 && is_array($resp['body']) && array_is_list($resp['body']))
         ? $resp['body'] : [];

// Filtra pelo ano seleccionado
$recibos = array_filter($recibos, fn($r) => (int)($r['ano'] ?? 0) === $anoFiltro);

$mesesLabels = [1=>'Janeiro',2=>'Fevereiro',3=>'Março',4=>'Abril',5=>'Maio',6=>'Junho',
                7=>'Julho',8=>'Agosto',9=>'Setembro',10=>'Outubro',11=>'Novembro',12=>'Dezembro'];

$estadoBadges = [
    'pendente' => ['adm-badge--gray',  'Pendente'],
    'pago'     => ['adm-badge--green', 'Pago'],
];

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Meus Recibos';
$activePage = 'meus_recibos';
$breadcrumb = [['Admin', '/nexora/'], ['Meus Recibos', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Meus Recibos de Vencimento</h1>
</div>

<!-- Filtro de ano -->
<div class="adm-card adm-mb-4">
    <div class="adm-card-body" style="padding:var(--adm-sp-4) var(--adm-sp-6)">
        <form method="get" style="display:flex;align-items:center;gap:var(--adm-sp-3)">
            <label class="adm-label" style="margin:0">Ano:</label>
            <select class="adm-select" name="ano" style="width:120px" onchange="this.form.submit()">
                <?php for ($y = $anoAtual; $y >= 2020; $y--): ?>
                <option value="<?php echo $y ?>" <?php echo $y === $anoFiltro ? 'selected' : '' ?>><?php echo $y ?></option>
                <?php endfor; ?>
            </select>
        </form>
    </div>
</div>

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Recibos — <?php echo $anoFiltro ?></h2></div>
    <?php if ($recibos): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Período</th>
                    <th>Salário Base</th>
                    <th>Total Proventos</th>
                    <th>Total Descontos</th>
                    <th>Salário Líquido</th>
                    <th>Estado</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($recibos as $rv):
                $badge  = $estadoBadges[$rv['estado']] ?? ['adm-badge--gray', $rv['estado']];
                $periodo = ($mesesLabels[$rv['mes']] ?? $rv['mes']) . ' ' . (int)$rv['ano'];
                $fmt = fn($v) => number_format((float)$v, 2, ',', '.') . ' MT';
            ?>
            <tr>
                <td class="adm-fw-600"><?php echo htmlspecialchars($periodo) ?></td>
                <td><?php echo $fmt($rv['salario_base']) ?></td>
                <td><?php echo $fmt($rv['total_proventos']) ?></td>
                <td style="color:var(--adm-red)"><?php echo $fmt($rv['total_descontos']) ?></td>
                <td class="adm-fw-600" style="color:var(--adm-green-dark)"><?php echo $fmt($rv['salario_liquido']) ?></td>
                <td><span class="adm-badge <?php echo $badge[0] ?>"><?php echo $badge[1] ?></span></td>
                <td>
                    <a class="adm-btn adm-btn-ghost adm-btn-sm" href="/nexora/meu-recibo?id=<?php echo $app->id->encode((int)$rv['id']) ?>">
                        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                        Ver / Imprimir
                    </a>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="color:var(--adm-gray-300)"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
        <p class="adm-empty-title">Sem recibos para <?php echo $anoFiltro ?></p>
        <p class="adm-empty-sub">Os recibos são gerados após o processamento mensal da folha salarial.</p>
    </div>
    <?php endif; ?>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
