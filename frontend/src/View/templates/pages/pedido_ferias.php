<?php

    $pedidosResp = $app->nexora->call('GET', '/api/pedido-ferias/');
    $pedidos = ($pedidosResp['status'] === 200 && is_array($pedidosResp['body']) && array_is_list($pedidosResp['body']))
        ? $pedidosResp['body'] : [];

    $tiposResp = $app->nexora->call('GET', '/api/pedido-ferias/tipos');
    $tipos = ($tiposResp['status'] === 200 && is_array($tiposResp['body']) && array_is_list($tiposResp['body']))
        ? $tiposResp['body'] : [];
    $csrf    = $app->security->csrfToken();

    $estadoBadge = [
        'pendente'  => ['adm-badge--yellow', 'Pendente'],
        'aprovado'  => ['adm-badge--green',  'Aprovado'],
        'rejeitado' => ['adm-badge--red',    'Rejeitado'],
        'cancelado' => ['adm-badge--gray',   'Cancelado'],
    ];

    $pageTitle  = 'Pedido de Férias';
    $activePage = 'pedido_ferias';
    $breadcrumb = [['Admin', '/nexora/'], ['Pedido de Férias', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Pedido de Férias</h1>
    <div class="adm-page-header-actions">
        <button class="adm-btn adm-btn-primary" onclick="abrirModal()">
            <i class="fa-solid fa-plus"></i> Novo Pedido
        </button>
    </div>
</div>

<!-- Lista de pedidos -->
<div class="adm-card">
    <?php if (empty($pedidos)): ?>
    <div class="adm-empty">
        <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M3 17l9-9 4 4 5-5"/><path d="M14 8h7v7"/></svg>
        <p class="adm-empty-title">Sem pedidos</p>
        <p class="adm-empty-sub">Ainda não fez nenhum pedido de férias ou ausência.</p>
        <button class="adm-btn adm-btn-primary" onclick="abrirModal()">
            <i class="fa-solid fa-plus"></i> Fazer Pedido
        </button>
    </div>
    <?php else: ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Tipo</th>
                    <th>De</th>
                    <th>Até</th>
                    <th>Dias</th>
                    <th>Motivo</th>
                    <th>Estado</th>
                    <th>Pedido em</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($pedidos as $p): ?>
            <?php [$badgeClass, $badgeLabel] = $estadoBadge[$p['estado']] ?? ['adm-badge--gray', $p['estado']]; ?>
            <tr>
                <td class="adm-fw-600"><?= htmlspecialchars($p['tipo_nome'] ?? '—') ?></td>
                <td><?= htmlspecialchars(substr($p['data_inicio'], 0, 10)) ?></td>
                <td><?= htmlspecialchars(substr($p['data_fim'], 0, 10)) ?></td>
                <td><?= htmlspecialchars((string)($p['dias'] ?? '—')) ?></td>
                <td class="adm-text-muted adm-truncate" style="max-width:200px"><?= htmlspecialchars($p['motivo'] ?? '—') ?></td>
                <td><span class="adm-badge <?= $badgeClass ?>"><?= $badgeLabel ?></span></td>
                <td class="adm-text-muted"><?= htmlspecialchars(substr($p['criado_em'], 0, 10)) ?></td>
                <td>
                    <?php if ($p['estado'] === 'pendente'): ?>
                    <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="cancelar(<?= (int)$p['id'] ?>)">
                        <i class="fa-solid fa-xmark"></i> Cancelar
                    </button>
                    <?php endif; ?>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php endif; ?>
</div>

<!-- Modal: novo pedido -->
<div class="adm-modal-overlay" id="modalFerias">
    <div class="adm-modal" style="max-width:480px">
        <p class="adm-modal-title">Novo Pedido de Férias / Ausência</p>
        <div id="modalErro" class="adm-alert adm-alert--error" style="display:none"></div>

        <div class="adm-form-group">
            <label class="adm-label" for="fTipo">Tipo de ausência</label>
            <select class="adm-select" id="fTipo">
                <option value="">— seleccionar —</option>
                <?php foreach ($tipos as $t): ?>
                <option value="<?= (int)$t['id'] ?>"><?= htmlspecialchars($t['nome']) ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="fInicio">Data de início</label>
                <input type="date" class="adm-input" id="fInicio">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="fFim">Data de fim</label>
                <input type="date" class="adm-input" id="fFim">
            </div>
        </div>
        <div class="adm-form-group">
            <label class="adm-label" for="fMotivo">Motivo <span class="adm-text-muted">(opcional)</span></label>
            <textarea class="adm-textarea" id="fMotivo" rows="3" placeholder="Descreva brevemente o motivo…"></textarea>
        </div>

        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-outline" onclick="fecharModal()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" id="btnSubmit" onclick="submeter()">
                <i class="fa-solid fa-paper-plane"></i> Enviar Pedido
            </button>
        </div>
    </div>
</div>

<script>
const CSRF = <?= json_encode($csrf) ?>;

function abrirModal() {
    document.getElementById('modalFerias').classList.add('open');
    document.getElementById('modalErro').style.display = 'none';
}
function fecharModal() {
    document.getElementById('modalFerias').classList.remove('open');
}
document.getElementById('modalFerias').addEventListener('click', function(e) {
    if (e.target === this) fecharModal();
});

async function submeter() {
    const tipo   = document.getElementById('fTipo').value;
    const inicio = document.getElementById('fInicio').value;
    const fim    = document.getElementById('fFim').value;
    const motivo = document.getElementById('fMotivo').value.trim();
    const erro   = document.getElementById('modalErro');

    if (!tipo || !inicio || !fim) {
        erro.textContent = 'Preencha o tipo, a data de início e a data de fim.';
        erro.style.display = 'flex';
        return;
    }

    const btn = document.getElementById('btnSubmit');
    btn.disabled = true;

    const resp = await fetch('/nexora/api/pedido_ferias_criar', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tipo_id: parseInt(tipo), data_inicio: inicio, data_fim: fim, motivo: motivo || null, csrf_token: CSRF })
    });
    const data = await resp.json();
    btn.disabled = false;

    if (!resp.ok) {
        erro.textContent = data.error ?? 'Erro ao submeter o pedido.';
        erro.style.display = 'flex';
        return;
    }
    showToast('Pedido enviado com sucesso!');
    setTimeout(() => location.reload(), 900);
}

function cancelar(id) {
    openConfirm('Cancelar pedido', 'Tem a certeza que deseja cancelar este pedido?', async () => {
        const resp = await fetch('/nexora/api/pedido_ferias_cancelar', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id, csrf_token: CSRF })
        });
        if (resp.ok || resp.status === 204) {
            showToast('Pedido cancelado.');
            setTimeout(() => location.reload(), 900);
        } else {
            const d = await resp.json().catch(() => ({}));
            showToast(d.error ?? 'Erro ao cancelar.', 'error');
        }
    });
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
