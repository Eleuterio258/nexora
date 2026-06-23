<?php

    $resp    = $app->nexora->call('GET', '/api/faturacao/receipts', null, ['limit' => 100]);
    $recibos = $resp['body'] ?? [];

    $faturasResp = $app->nexora->call('GET', '/api/faturacao/invoices', null, ['limit' => 200]);
    $faturas     = $faturasResp['body']['data'] ?? [];
    $faturaInfo  = [];
    foreach ($faturas as $f) {
        $faturaInfo[$f['id']] = $f;
    }

    $estadoBadges = [
        'pendente'   => ['adm-badge--yellow', 'Pendente'],
        'confirmado' => ['adm-badge--green',  'Confirmado'],
        'cancelado'  => ['adm-badge--red',    'Cancelado'],
    ];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Recibos';
    $activePage = 'recibos';
    $breadcrumb = [['Admin', '/nexora/'], ['Faturação', ''], ['Recibos', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Recibos</h1>
    <div class="adm-page-header-actions">
        <button class="adm-btn adm-btn-primary" onclick="openReciboModal()">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Novo Recibo
        </button>
    </div>
</div>

<div class="adm-card">
    <?php if ($recibos): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Número</th>
                    <th>Fatura</th>
                    <th>Valor</th>
                    <th>Data pagamento</th>
                    <th>Estado</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($recibos as $r):
                    $estadoBadge = $estadoBadges[$r['status']] ?? ['adm-badge--gray', $r['status']];
                    $faturaNum   = $faturaInfo[$r['invoice_id']]['numero'] ?? ('#' . $r['invoice_id']);
            ?>
            <tr>
                <td class="adm-fw-600"><?php echo htmlspecialchars($r['numero']) ?></td>
                <td><?php echo htmlspecialchars($faturaNum) ?></td>
                <td class="adm-fw-600"><?php echo number_format((float) $r['valor'], 2, ',', '.') ?></td>
                <td class="adm-text-muted"><?php echo $r['payment_date'] ? date('d/m/Y', strtotime($r['payment_date'])) : '—' ?></td>
                <td><span class="adm-badge <?php echo $estadoBadge[0] ?>"><?php echo $estadoBadge[1] ?></span></td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
        </svg>
        <p class="adm-empty-title">Nenhum recibo registado</p>
        <p class="adm-empty-sub">Regista o primeiro pagamento de uma fatura.</p>
    </div>
    <?php endif; ?>
</div>

<!-- Novo Recibo Modal -->
<div class="adm-modal-overlay" id="reciboModal">
    <div class="adm-modal" style="max-width:560px">
        <p class="adm-modal-title">Novo Recibo</p>

        <div class="adm-form-group">
            <label class="adm-label" for="r-invoice_id">Fatura <span style="color:var(--adm-red)">*</span></label>
            <select class="adm-select" id="r-invoice_id">
                <option value="">Seleciona uma fatura</option>
                <?php foreach ($faturas as $f): ?>
                <option value="<?php echo $f['id'] ?>"><?php echo htmlspecialchars($f['numero']) ?> — <?php echo number_format((float) $f['total'], 2, ',', '.') ?> <?php echo htmlspecialchars($f['moeda']) ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <p class="adm-text-muted adm-text-sm">O número será atribuído automaticamente pela série activa (Faturação → Séries Documentais).</p>
        <div class="adm-form-group">
            <label class="adm-label" for="r-valor">Valor <span style="color:var(--adm-red)">*</span></label>
            <input class="adm-input" type="number" id="r-valor" min="0.01" step="0.01" placeholder="0.00">
        </div>
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="r-payment_method_id">Método de Pagamento (ID)</label>
                <input class="adm-input" type="number" id="r-payment_method_id" min="1" step="1" placeholder="opcional">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="r-referencia">Referência</label>
                <input class="adm-input" type="text" id="r-referencia" maxlength="100">
            </div>
        </div>
        <div class="adm-form-group">
            <label class="adm-label" for="r-observacoes">Observações</label>
            <textarea class="adm-textarea" id="r-observacoes" rows="3"></textarea>
        </div>

        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-outline" onclick="closeReciboModal()">Fechar</button>
            <button class="adm-btn adm-btn-primary" onclick="saveRecibo()">Criar Recibo</button>
        </div>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

function openReciboModal() {
    document.getElementById('reciboModal').classList.add('open');
}
function closeReciboModal() {
    document.getElementById('reciboModal').classList.remove('open');
}
document.getElementById('reciboModal').addEventListener('click', e => {
    if (e.target === e.currentTarget) closeReciboModal();
});

async function saveRecibo() {
    const invoiceId = document.getElementById('r-invoice_id').value;
    const valor     = document.getElementById('r-valor').value;
    if (!invoiceId) { showToast('A fatura é obrigatória.', 'error'); return; }
    if (!valor || Number(valor) <= 0) { showToast('O valor deve ser superior a zero.', 'error'); return; }

    const methodId = document.getElementById('r-payment_method_id').value;

    const payload = {
        invoice_id: Number(invoiceId),
        valor: Number(valor),
        payment_method_id: methodId ? Number(methodId) : null,
        referencia: document.getElementById('r-referencia').value.trim() || null,
        observacoes: document.getElementById('r-observacoes').value.trim() || null,
        csrf: CSRF
    };

    try {
        const res  = await fetch('/nexora/api/recibo_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast('Recibo ' + (data.numero || '') + ' criado com sucesso.');
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
