<?php

$invoiceIdPre = $app->request->queryInt('invoice_id') ?? '';

$resp    = $app->nexora->call('GET', '/api/faturacao/receipts', null, ['limit' => 100]);
$recibos = $resp['body'] ?? [];

$faturasResp = $app->nexora->call('GET', '/api/faturacao/invoices', null, ['limit' => 200]);
$faturas     = $faturasResp['body']['data'] ?? [];
$faturasPorId = [];
foreach ($faturas as $f) {
    $faturasPorId[(int) $f['id']] = $f;
}

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Recibos';
$activePage = 'recibos';
$breadcrumb = [['Admin', '/nexora/'], ['Faturação', ''], ['Recibos', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Recibos</h1>
</div>

<div id="formMsg"></div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Lista de recibos</h2></div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($recibos)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Número</th><th>Fatura</th><th>Data</th><th>Estado</th><th style="text-align:right">Valor</th></tr>
                </thead>
                <tbody>
                <?php foreach ($recibos as $r): ?>
                    <tr>
                        <td class="adm-fw-600"><?= htmlspecialchars($r['numero']) ?></td>
                        <td><?= htmlspecialchars($faturasPorId[(int) $r['invoice_id']]['numero'] ?? ('#' . $r['invoice_id'])) ?></td>
                        <td class="adm-text-muted"><?= date('d/m/Y', strtotime($r['payment_date'])) ?></td>
                        <td><span class="adm-badge adm-badge--green"><?= htmlspecialchars($r['status']) ?></span></td>
                        <td style="text-align:right" class="adm-fw-600"><?= number_format((float) $r['valor'], 2, ',', '.') ?></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-12)">
            <i class="fa-solid fa-circle-check" style="font-size:2rem;opacity:.2"></i>
            <p class="adm-empty-title">Sem recibos</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Novo Recibo</h2></div>
    <div class="adm-card-body">
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="f-fatura">Fatura <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="f-fatura">
                    <option value="">Seleccionar fatura…</option>
                    <?php foreach ($faturas as $f):
                        if (!in_array($f['status'], ['emitida', 'parcialmente_paga', 'vencida'], true)) {
                            continue;
                        }
                    ?>
                    <option value="<?= (int) $f['id'] ?>" <?= (string) $invoiceIdPre === (string) $f['id'] ? 'selected' : '' ?>>
                        <?= htmlspecialchars($f['numero']) ?> — <?= number_format((float) $f['total'], 2, ',', '.') ?> <?= htmlspecialchars($f['moeda']) ?>
                    </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="f-valor">Valor <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="number" id="f-valor" min="0.01" step="0.01" placeholder="0.00">
            </div>
        </div>
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="f-referencia">Referência</label>
                <input class="adm-input" type="text" id="f-referencia" maxlength="100" placeholder="ex: REF-00123">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="f-observacoes">Observações</label>
                <input class="adm-input" type="text" id="f-observacoes" maxlength="255">
            </div>
        </div>
        <button class="adm-btn adm-btn-primary" type="button" onclick="saveRecibo()">Registar Recibo</button>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

async function saveRecibo() {
    const invoiceId = document.getElementById('f-fatura').value;
    const valor = document.getElementById('f-valor').value;
    if (!invoiceId) { showToast('A fatura é obrigatória.', 'error'); return; }
    if (!valor || Number(valor) <= 0) { showToast('O valor deve ser superior a zero.', 'error'); return; }

    const payload = {
        invoice_id: Number(invoiceId),
        valor: Number(valor),
        referencia: document.getElementById('f-referencia').value.trim() || null,
        observacoes: document.getElementById('f-observacoes').value.trim() || null,
        csrf: CSRF
    };

    try {
        const res  = await fetch('/nexora/api/recibo_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) { showToast(data.msg || 'Recibo registado.'); setTimeout(() => location.reload(), 700); }
        else showToast(data.erro || 'Erro', 'error');
    } catch { showToast('Erro de ligação', 'error'); }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
