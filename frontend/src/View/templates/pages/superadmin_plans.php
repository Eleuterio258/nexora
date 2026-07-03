<?php

$resp  = $app->nexora->call('GET', '/api/superadmin/plans');
$plans = $resp['body'] ?? [];

$csrf = $app->security->csrfToken();
$pageTitle  = 'Planos';
$activePage = 'superadmin_plans';
$breadcrumb = [['Nexora', '/nexora/superadmin'], ['Planos', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Planos Globais</h1>
    <div class="adm-page-header-actions">
        <button class="adm-btn adm-btn-primary" onclick="openPlanModal()">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Novo Plano
        </button>
    </div>
</div>

<div class="adm-card">
    <?php if ($plans): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Código</th>
                    <th>Nome</th>
                    <th>Preço Mensal</th>
                    <th>Preço Anual</th>
                    <th>Moeda</th>
                    <th>Ativo</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($plans as $p): ?>
            <tr>
                <td><code><?= htmlspecialchars($p['codigo']) ?></code></td>
                <td><div class="adm-fw-600"><?= htmlspecialchars($p['nome']) ?></div></td>
                <td><?= number_format((float) $p['preco_mensal'], 2, ',', '.') ?></td>
                <td><?= number_format((float) $p['preco_anual'], 2, ',', '.') ?></td>
                <td><?= htmlspecialchars($p['moeda']) ?></td>
                <td><span class="adm-badge <?= ($p['ativo'] ?? false) ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?= ($p['ativo'] ?? false) ? 'Sim' : 'Não' ?></span></td>
                <td>
                    <div class="adm-actions">
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="editPlan(<?= htmlspecialchars(json_encode($p), ENT_QUOTES, 'UTF-8') ?>)">Editar</button>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-danger" onclick="deletePlan(<?= $p['id'] ?>, '<?= htmlspecialchars(addslashes($p['nome'])) ?>')">Eliminar</button>
                    </div>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">Nenhum plano encontrado.</div>
    <?php endif; ?>
</div>

<div class="adm-modal" id="planModal" style="display:none">
    <div class="adm-modal-content">
        <div class="adm-modal-header">
            <h3 id="planModalTitle">Novo Plano</h3>
            <button class="adm-btn adm-btn-ghost adm-btn-icon" onclick="closePlanModal()">&times;</button>
        </div>
        <form id="planForm" class="adm-form" onsubmit="return savePlan(event)">
            <input type="hidden" name="id" id="planId" value="">
            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
            <div class="adm-form-group">
                <label>Código</label>
                <input class="adm-input" type="text" name="codigo" id="planCodigo" required>
            </div>
            <div class="adm-form-group">
                <label>Nome</label>
                <input class="adm-input" type="text" name="nome" id="planNome" required>
            </div>
            <div class="adm-form-group">
                <label>Descrição</label>
                <textarea class="adm-input" name="descricao" id="planDescricao" rows="2"></textarea>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label>Preço Mensal</label>
                    <input class="adm-input" type="number" step="0.01" name="preco_mensal" id="planPrecoMensal" required>
                </div>
                <div class="adm-form-group">
                    <label>Preço Anual</label>
                    <input class="adm-input" type="number" step="0.01" name="preco_anual" id="planPrecoAnual" required>
                </div>
                <div class="adm-form-group">
                    <label>Moeda</label>
                    <input class="adm-input" type="text" name="moeda" id="planMoeda" value="MZN" required>
                </div>
            </div>
            <div class="adm-form-group">
                <label>
                    <input type="checkbox" name="ativo" id="planAtivo" checked> Ativo
                </label>
            </div>
            <div class="adm-modal-footer">
                <button type="button" class="adm-btn adm-btn-ghost" onclick="closePlanModal()">Cancelar</button>
                <button type="submit" class="adm-btn adm-btn-primary">Guardar</button>
            </div>
        </form>
    </div>
</div>

<script>
const planModal = document.getElementById('planModal');
function openPlanModal() {
    document.getElementById('planForm').reset();
    document.getElementById('planId').value = '';
    document.getElementById('planModalTitle').textContent = 'Novo Plano';
    planModal.style.display = 'flex';
}
function closePlanModal() { planModal.style.display = 'none'; }
function editPlan(p) {
    document.getElementById('planId').value = p.id;
    document.getElementById('planCodigo').value = p.codigo;
    document.getElementById('planNome').value = p.nome;
    document.getElementById('planDescricao').value = p.descricao || '';
    document.getElementById('planPrecoMensal').value = p.preco_mensal;
    document.getElementById('planPrecoAnual').value = p.preco_anual;
    document.getElementById('planMoeda').value = p.moeda;
    document.getElementById('planAtivo').checked = p.ativo;
    document.getElementById('planModalTitle').textContent = 'Editar Plano';
    planModal.style.display = 'flex';
}
async function savePlan(e) {
    e.preventDefault();
    const fd = new FormData(e.target);
    const payload = Object.fromEntries(fd.entries());
    payload.preco_mensal = parseFloat(payload.preco_mensal);
    payload.preco_anual = parseFloat(payload.preco_anual);
    payload.ativo = !!fd.get('ativo');
    if (payload.id) payload.id = parseInt(payload.id);
    else delete payload.id;

    const res = await fetch('/nexora/api/superadmin_plan_save', {
        method: 'POST',
        headers: {'Content-Type': 'application/json', 'X-CSRF-Token': payload.csrf_token},
        body: JSON.stringify(payload)
    }).then(r => r.json());
    if (res.ok) location.reload();
    else alert(res.error || 'Erro ao guardar plano');
    return false;
}
async function deletePlan(id, nome) {
    if (!confirm(`Eliminar plano "${nome}"?`)) return;
    const res = await fetch('/nexora/api/superadmin_plan_delete', {
        method: 'POST',
        headers: {'Content-Type': 'application/json', 'X-CSRF-Token': '<?= $csrf ?>'},
        body: JSON.stringify({id})
    }).then(r => r.json());
    if (res.ok) location.reload();
    else alert(res.error || 'Erro ao eliminar plano');
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
