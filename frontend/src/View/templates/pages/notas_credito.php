<?php

    $resp          = $app->nexora->call('GET', '/api/faturacao/credit-notes', null, ['limit' => 100]);
    $notasCredito  = $resp['body'] ?? [];

    $clientesResp = $app->nexora->call('GET', '/api/clientes', null, ['limit' => 200]);
    $clientes     = $clientesResp['body']['data'] ?? [];
    $clienteNomes = array_column($clientes, 'nome', 'id');

    $faturasResp  = $app->nexora->call('GET', '/api/faturacao/invoices', null, ['limit' => 200]);
    $faturas      = $faturasResp['body']['data'] ?? [];
    $faturaNomes  = array_column($faturas, 'numero', 'id');

    $estadoBadges = [
        'rascunho'  => ['adm-badge--gray',  'Rascunho'],
        'emitida'   => ['adm-badge--blue',  'Emitida'],
        'aplicada'  => ['adm-badge--green', 'Aplicada'],
        'cancelada' => ['adm-badge--red',   'Cancelada'],
    ];

    $csrf       = $app->security->csrfToken();
    $canEmitirNotasCredito = $app->session->can('faturacao', 'emitir_notas_credito');
    $pageTitle  = 'Notas de Crédito';
    $activePage = 'notas_credito';
    $breadcrumb = [['Admin', '/nexora/'], ['Faturação', ''], ['Notas de Crédito', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Notas de Crédito</h1>
    <?php if ($canEmitirNotasCredito): ?>
    <div class="adm-page-header-actions">
        <button class="adm-btn adm-btn-primary" onclick="openNotaModal()">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Nova Nota de Crédito
        </button>
    </div>
    <?php endif; ?>
</div>

<div class="adm-card">
    <?php if ($notasCredito): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Número</th>
                    <th>Cliente</th>
                    <th>Fatura associada</th>
                    <th>Total</th>
                    <th>Moeda</th>
                    <th>Estado</th>
                    <th>Data</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($notasCredito as $n):
                    $estadoBadge = $estadoBadges[$n['status']] ?? ['adm-badge--gray', $n['status']];
                    $clienteNome = $clienteNomes[$n['customer_id']] ?? ('#' . $n['customer_id']);
                    $faturaNome  = $n['invoice_id'] ? ($faturaNomes[$n['invoice_id']] ?? ('#' . $n['invoice_id'])) : '—';
            ?>
            <tr>
                <td class="adm-fw-600"><?php echo htmlspecialchars($n['numero']) ?></td>
                <td><?php echo htmlspecialchars($clienteNome) ?></td>
                <td><?php echo htmlspecialchars($faturaNome) ?></td>
                <td class="adm-fw-600"><?php echo number_format((float) $n['total'], 2, ',', '.') ?></td>
                <td><?php echo htmlspecialchars($n['moeda']) ?></td>
                <td><span class="adm-badge <?php echo $estadoBadge[0] ?>"><?php echo $estadoBadge[1] ?></span></td>
                <td class="adm-text-muted"><?php echo $n['created_at'] ? date('d/m/Y', strtotime($n['created_at'])) : '—' ?></td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/>
            <line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/>
        </svg>
        <p class="adm-empty-title">Nenhuma nota de crédito criada</p>
        <p class="adm-empty-sub">Cria a primeira nota de crédito.</p>
    </div>
    <?php endif; ?>
</div>

<?php if ($canEmitirNotasCredito): ?>
<!-- Nova Nota de Crédito Modal -->
<div class="adm-modal-overlay" id="notaModal">
    <div class="adm-modal" style="max-width:560px">
        <p class="adm-modal-title">Nova Nota de Crédito</p>

        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="n-customer_id">Cliente <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="n-customer_id">
                    <option value="">Seleciona um cliente</option>
                    <?php foreach ($clientes as $c): ?>
                    <option value="<?php echo $c['id'] ?>"><?php echo htmlspecialchars($c['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="n-invoice_id">Fatura associada</label>
                <select class="adm-select" id="n-invoice_id">
                    <option value="">Nenhuma (independente)</option>
                    <?php foreach ($faturas as $f): ?>
                    <option value="<?php echo $f['id'] ?>"><?php echo htmlspecialchars($f['numero']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
        </div>
        <p class="adm-text-muted adm-text-sm">O número será atribuído automaticamente pela série activa (Faturação → Séries Documentais).</p>
        <div class="adm-form-group">
            <label class="adm-label" for="n-moeda">Moeda</label>
            <select class="adm-select" id="n-moeda">
                <?php foreach (['MZN', 'USD', 'EUR', 'ZAR'] as $m): ?>
                <option value="<?php echo $m ?>" <?php echo $m === 'MZN' ? 'selected' : '' ?>><?php echo $m ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div class="adm-form-group">
            <label class="adm-label" for="n-motivo">Motivo <span style="color:var(--adm-red)">*</span></label>
            <input class="adm-input" type="text" id="n-motivo" maxlength="255" placeholder="ex: Devolução de mercadoria">
        </div>
        <div class="adm-form-group">
            <label class="adm-label" for="n-observacoes">Observações</label>
            <textarea class="adm-textarea" id="n-observacoes" rows="3"></textarea>
        </div>

        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-outline" onclick="closeNotaModal()">Fechar</button>
            <button class="adm-btn adm-btn-primary" onclick="saveNota()">Criar Nota de Crédito</button>
        </div>
    </div>
</div>
<?php endif; ?>

<script>
const CSRF = '<?php echo $csrf ?>';

function openNotaModal() {
    document.getElementById('notaModal').classList.add('open');
}
function closeNotaModal() {
    document.getElementById('notaModal').classList.remove('open');
}
document.getElementById('notaModal').addEventListener('click', e => {
    if (e.target === e.currentTarget) closeNotaModal();
});

async function saveNota() {
    const customerId = document.getElementById('n-customer_id').value;
    const motivo      = document.getElementById('n-motivo').value.trim();
    if (!customerId) { showToast('O cliente é obrigatório.', 'error'); return; }
    if (!motivo) { showToast('O motivo é obrigatório.', 'error'); return; }

    const invoiceId = document.getElementById('n-invoice_id').value;

    const payload = {
        customer_id: Number(customerId),
        invoice_id: invoiceId ? Number(invoiceId) : null,
        motivo,
        moeda: document.getElementById('n-moeda').value,
        observacoes: document.getElementById('n-observacoes').value.trim() || null,
        csrf: CSRF
    };

    try {
        const res  = await fetch('/nexora/api/nota_credito_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast('Nota de crédito ' + (data.numero || '') + ' criada com sucesso.');
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
