<?php

$resp       = $app->nexora->call('GET', '/api/faturacao/orders', null, ['limit' => 100]);
$encomendas = $resp['body'] ?? [];

$clientesResp = $app->nexora->call('GET', '/api/clientes', null, ['limit' => 200]);
$clientes     = $clientesResp['body']['data'] ?? [];
$clientesPorId = [];
foreach ($clientes as $c) {
    $clientesPorId[(int) $c['id']] = $c['nome'] ?? ('#' . $c['id']);
}

$statusBadges = [
    'rascunho'  => ['adm-badge--gray',  'Rascunho'],
    'confirmada' => ['adm-badge--green', 'Confirmada'],
    'cancelada' => ['adm-badge--red',   'Cancelada'],
];

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Encomendas';
$activePage = 'encomendas';
$breadcrumb = [['Admin', '/nexora/'], ['Faturação', ''], ['Encomendas', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Encomendas</h1>
</div>

<div id="formMsg"></div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Lista de encomendas</h2></div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($encomendas)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Número</th><th>Cliente</th><th>Estado</th><th style="text-align:right">Total</th><th></th></tr>
                </thead>
                <tbody>
                <?php foreach ($encomendas as $e):
                    $badge = $statusBadges[$e['status']] ?? ['adm-badge--gray', $e['status']];
                ?>
                    <tr>
                        <td class="adm-fw-600"><?= htmlspecialchars($e['numero']) ?></td>
                        <td><?= htmlspecialchars($clientesPorId[(int) $e['customer_id']] ?? ('#' . $e['customer_id'])) ?></td>
                        <td><span class="adm-badge <?= $badge[0] ?>"><?= $badge[1] ?></span></td>
                        <td style="text-align:right" class="adm-fw-600"><?= number_format((float) $e['total'], 2, ',', '.') ?> <?= htmlspecialchars($e['moeda']) ?></td>
                        <td>
                            <?php if ($e['status'] === 'rascunho'): ?>
                            <div class="adm-actions">
                                <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="setEstado(<?= (int) $e['id'] ?>, 'confirmar')">Confirmar</button>
                                <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-red)" onclick="setEstado(<?= (int) $e['id'] ?>, 'cancelar')">Cancelar</button>
                            </div>
                            <?php endif; ?>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-12)">
            <i class="fa-solid fa-box" style="font-size:2rem;opacity:.2"></i>
            <p class="adm-empty-title">Sem encomendas</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Nova Encomenda</h2></div>
    <div class="adm-card-body">
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="f-cliente">Cliente <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="f-cliente">
                    <option value="">Seleccionar cliente…</option>
                    <?php foreach ($clientes as $c): ?>
                    <option value="<?= (int) $c['id'] ?>"><?= htmlspecialchars(($c['codigo'] ?? '') . ' — ' . $c['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="f-moeda">Moeda</label>
                <input class="adm-input" type="text" id="f-moeda" value="MZN" maxlength="3">
            </div>
        </div>
        <div class="adm-form-group">
            <label class="adm-label" for="f-observacoes">Observações</label>
            <textarea class="adm-textarea" id="f-observacoes" rows="3"></textarea>
        </div>
        <button class="adm-btn adm-btn-primary" type="button" onclick="saveEncomenda()">Criar Encomenda</button>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

async function saveEncomenda() {
    const clienteId = document.getElementById('f-cliente').value;
    if (!clienteId) { showToast('O cliente é obrigatório.', 'error'); return; }

    const payload = {
        customer_id: Number(clienteId),
        moeda: document.getElementById('f-moeda').value.trim() || null,
        observacoes: document.getElementById('f-observacoes').value.trim() || null,
        csrf: CSRF
    };

    try {
        const res  = await fetch('/nexora/api/encomenda_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) { showToast(data.msg || 'Encomenda criada.'); setTimeout(() => location.reload(), 700); }
        else showToast(data.erro || 'Erro', 'error');
    } catch { showToast('Erro de ligação', 'error'); }
}

function setEstado(id, action) {
    openConfirm(
        'Actualizar estado',
        'Pretende ' + action + ' esta encomenda?',
        async () => {
            try {
                const res  = await fetch('/nexora/api/encomenda_estado', {
                    method: 'POST', headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id, action, csrf: CSRF})
                });
                const data = await res.json();
                if (data.ok) { showToast('Estado actualizado'); setTimeout(() => location.reload(), 700); }
                else showToast(data.erro || 'Erro', 'error');
            } catch { showToast('Erro de ligação', 'error'); }
        }
    );
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
