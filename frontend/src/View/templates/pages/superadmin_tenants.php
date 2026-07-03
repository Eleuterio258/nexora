<?php

$search = $app->request->queryString('search');
$status = $app->request->queryString('status');
$page   = max(1, $app->request->queryInt('page', 1) ?? 1);
$limit  = 20;

$resp    = $app->nexora->call('GET', '/api/superadmin/tenants', null, ['search' => $search, 'status' => $status, 'page' => $page, 'limit' => $limit]);
$tenants = $resp['body']['data'] ?? [];
$meta    = $resp['body']['meta'] ?? ['total' => 0, 'page' => $page, 'limit' => $limit];
$totalPages = max(1, (int) ceil($meta['total'] / $limit));

$plansResp = $app->nexora->call('GET', '/api/superadmin/plans');
$plans     = $plansResp['body'] ?? [];

$csrf = $app->security->csrfToken();
$pageTitle  = 'Tenants';
$activePage = 'superadmin_tenants';
$breadcrumb = [['Nexora', '/nexora/superadmin'], ['Tenants', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Tenants</h1>
    <div class="adm-page-header-actions">
        <button class="adm-btn adm-btn-primary" onclick="openTenantModal()">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Novo Tenant
        </button>
    </div>
</div>

<div class="adm-card">
    <form method="get" class="adm-filter-bar">
        <div class="adm-search-wrap">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <input class="adm-input" type="search" name="search" placeholder="Pesquisar nome ou código…" value="<?= htmlspecialchars($search) ?>">
        </div>
        <select class="adm-select" name="status" style="width:160px">
            <option value="">Todos os estados</option>
            <option value="ativo" <?= $status === 'ativo' ? 'selected' : '' ?>>Ativos</option>
            <option value="suspenso" <?= $status === 'suspenso' ? 'selected' : '' ?>>Suspensos</option>
            <option value="inativo" <?= $status === 'inativo' ? 'selected' : '' ?>>Inativos</option>
        </select>
        <button type="submit" class="adm-btn adm-btn-outline adm-btn-sm">Filtrar</button>
        <span class="adm-filter-count"><?= $meta['total'] ?> tenant<?= $meta['total'] != 1 ? 's' : '' ?></span>
    </form>

    <?php if ($tenants): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Código</th>
                    <th>Nome</th>
                    <th>Estado</th>
                    <th>Plano</th>
                    <th>Domínio</th>
                    <th>Criado em</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($tenants as $t):
                $estadoBadge = match ($t['status']) {
                    'ativo'     => ['adm-badge--green', 'Ativo'],
                    'suspenso'  => ['adm-badge--yellow', 'Suspenso'],
                    'inativo'   => ['adm-badge--gray', 'Inativo'],
                    default     => ['adm-badge--gray', $t['status']],
                };
            ?>
            <tr>
                <td><code><?= htmlspecialchars($t['codigo']) ?></code></td>
                <td><div class="adm-fw-600"><?= htmlspecialchars($t['nome']) ?></div></td>
                <td><span class="adm-badge <?= $estadoBadge[0] ?>"><?= $estadoBadge[1] ?></span></td>
                <td><?= htmlspecialchars($t['plano_nome'] ?? '—') ?></td>
                <td><?= htmlspecialchars($t['dominio'] ?? '—') ?></td>
                <td class="adm-text-muted"><?= date('d/m/Y', strtotime($t['created_at'])) ?></td>
                <td>
                    <div class="adm-actions">
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="editTenant(<?= htmlspecialchars(json_encode($t), ENT_QUOTES, 'UTF-8') ?>)">Editar</button>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-green)"
                            onclick="openCriarFuncionarioModal(<?= (int)$t['id'] ?>, '<?= htmlspecialchars(addslashes($t['nome'])) ?>')">+ Funcionário</button>
                        <?php if ($t['status'] === 'ativo'): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="changeStatus(<?= $t['id'] ?>, 'suspenso')">Suspender</button>
                        <?php else: ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="changeStatus(<?= $t['id'] ?>, 'ativo')">Reativar</button>
                        <?php endif; ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-danger" onclick="deleteTenant(<?= $t['id'] ?>, '<?= htmlspecialchars(addslashes($t['nome'])) ?>')">Eliminar</button>
                    </div>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>

    <?php if ($totalPages > 1): ?>
    <div class="adm-pagination">
        <?php for ($i = 1; $i <= $totalPages; $i++): ?>
        <a href="?<?= http_build_query(array_filter(['search' => $search, 'status' => $status, 'page' => $i])) ?>" class="adm-btn adm-btn-sm <?= $i === $page ? 'adm-btn-primary' : 'adm-btn-ghost' ?>"><?= $i ?></a>
        <?php endfor; ?>
    </div>
    <?php endif; ?>

    <?php else: ?>
    <div class="adm-empty">Nenhum tenant encontrado.</div>
    <?php endif; ?>
</div>

<div class="adm-modal" id="tenantModal" style="display:none">
    <div class="adm-modal-content">
        <div class="adm-modal-header">
            <h3 id="tenantModalTitle">Novo Tenant</h3>
            <button class="adm-btn adm-btn-ghost adm-btn-icon" onclick="closeTenantModal()">&times;</button>
        </div>
        <form id="tenantForm" class="adm-form" onsubmit="return saveTenant(event)">
            <input type="hidden" name="id" id="tenantId" value="">
            <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrf) ?>">
            <div class="adm-form-group">
                <label>Código</label>
                <input class="adm-input" type="text" name="codigo" id="tenantCodigo" required>
            </div>
            <div class="adm-form-group">
                <label>Nome</label>
                <input class="adm-input" type="text" name="nome" id="tenantNome" required>
            </div>
            <div class="adm-form-group">
                <label>Domínio</label>
                <input class="adm-input" type="text" name="dominio" id="tenantDominio">
            </div>
            <div class="adm-form-group">
                <label>Plano</label>
                <select class="adm-select" name="plano_id" id="tenantPlano">
                    <option value="">—</option>
                    <?php foreach ($plans as $p): ?>
                    <option value="<?= $p['id'] ?>"><?= htmlspecialchars($p['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label>Limite Utilizadores</label>
                    <input class="adm-input" type="number" name="limite_utilizadores" id="tenantLimiteUsers">
                </div>
                <div class="adm-form-group">
                    <label>Limite Armazenamento (GB)</label>
                    <input class="adm-input" type="number" name="limite_armazenamento_gb" id="tenantLimiteStorage">
                </div>
            </div>
            <div class="adm-form-group">
                <label>Validade do Plano</label>
                <input class="adm-input" type="date" name="validade_plano" id="tenantValidade">
            </div>
            <div class="adm-modal-footer">
                <button type="button" class="adm-btn adm-btn-ghost" onclick="closeTenantModal()">Cancelar</button>
                <button type="submit" class="adm-btn adm-btn-primary">Guardar</button>
            </div>
        </form>
    </div>
</div>

<!-- Modal: Criar Funcionário em Tenant -->
<div class="adm-modal" id="criarFuncModal" style="display:none">
    <div class="adm-modal-content" style="max-width:660px">
        <div class="adm-modal-header">
            <h3>Novo Funcionário — <span id="criarFuncTenantNome"></span></h3>
            <button class="adm-btn adm-btn-ghost adm-btn-icon" onclick="closeCriarFuncionarioModal()">&times;</button>
        </div>
        <div style="padding:var(--adm-sp-5) var(--adm-sp-6);max-height:72vh;overflow-y:auto">
            <input type="hidden" id="criarFuncTenantId">
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label">Nome Completo <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="cf-nome" maxlength="150" placeholder="ex: Maria José Macamo">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Número de Funcionário</label>
                    <input class="adm-input" type="text" id="cf-numero" maxlength="30" placeholder="A gerar…" disabled style="background:var(--adm-gray-50);color:var(--adm-gray-500)">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Cargo / Função</label>
                    <input class="adm-input" type="text" id="cf-cargo" maxlength="120" placeholder="ex: Técnico Administrativo">
                </div>
            </div>
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label">Tipo de Contrato</label>
                    <select class="adm-select" id="cf-tipo-contrato">
                        <option value="efetivo">Efetivo</option>
                        <option value="termo_certo">Termo Certo</option>
                        <option value="termo_incerto">Termo Incerto</option>
                        <option value="estagio">Estágio</option>
                        <option value="prestacao_servico">Prestação de Serviço</option>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Data de Admissão</label>
                    <input class="adm-input" type="date" id="cf-data-admissao" value="<?= date('Y-m-d') ?>">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Estado</label>
                    <select class="adm-select" id="cf-estado">
                        <option value="ativo">Ativo</option>
                        <option value="suspenso">Suspenso</option>
                        <option value="licenca">Licença</option>
                        <option value="desligado">Desligado</option>
                    </select>
                </div>
            </div>
            <div class="adm-form-row-3">
                <div class="adm-form-group">
                    <label class="adm-label">Género</label>
                    <select class="adm-select" id="cf-genero">
                        <option value="">— Não especificado —</option>
                        <option value="M">Masculino</option>
                        <option value="F">Feminino</option>
                        <option value="outro">Outro</option>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">NUIT</label>
                    <input class="adm-input" type="text" id="cf-nuit" maxlength="30" placeholder="ex: 123456789">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Telefone</label>
                    <input class="adm-input" type="text" id="cf-telefone" maxlength="30" placeholder="ex: 84 123 4567">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label">Email</label>
                    <input class="adm-input" type="email" id="cf-email" maxlength="150" placeholder="ex: maria@empresa.co.mz">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Endereço</label>
                    <input class="adm-input" type="text" id="cf-endereco" maxlength="255" placeholder="ex: Av. Eduardo Mondlane, Maputo">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label">Data de Nascimento</label>
                    <input class="adm-input" type="date" id="cf-data-nasc">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label">Salário Base (MZN)</label>
                    <input class="adm-input" type="number" id="cf-salario" step="0.01" min="0" placeholder="ex: 25000.00">
                </div>
            </div>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-ghost" type="button" onclick="closeCriarFuncionarioModal()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" type="button" onclick="submitCriarFuncionario()">Criar Funcionário</button>
        </div>
    </div>
</div>

<script>
const tenantModal = document.getElementById('tenantModal');
function openTenantModal() {
    document.getElementById('tenantForm').reset();
    document.getElementById('tenantId').value = '';
    document.getElementById('tenantModalTitle').textContent = 'Novo Tenant';
    tenantModal.style.display = 'flex';
}
function closeTenantModal() { tenantModal.style.display = 'none'; }
function editTenant(t) {
    document.getElementById('tenantId').value = t.id;
    document.getElementById('tenantCodigo').value = t.codigo;
    document.getElementById('tenantNome').value = t.nome;
    document.getElementById('tenantDominio').value = t.dominio || '';
    document.getElementById('tenantPlano').value = t.plano_id || '';
    document.getElementById('tenantLimiteUsers').value = t.limite_utilizadores || '';
    document.getElementById('tenantLimiteStorage').value = t.limite_armazenamento_gb || '';
    document.getElementById('tenantValidade').value = t.validade_plano || '';
    document.getElementById('tenantModalTitle').textContent = 'Editar Tenant';
    tenantModal.style.display = 'flex';
}
async function saveTenant(e) {
    e.preventDefault();
    const fd = new FormData(e.target);
    const payload = Object.fromEntries(fd.entries());
    payload.plano_id = payload.plano_id ? parseInt(payload.plano_id) : null;
    payload.limite_utilizadores = payload.limite_utilizadores ? parseInt(payload.limite_utilizadores) : null;
    payload.limite_armazenamento_gb = payload.limite_armazenamento_gb ? parseInt(payload.limite_armazenamento_gb) : null;
    payload.validade_plano = payload.validade_plano || null;
    if (payload.id) payload.id = parseInt(payload.id);
    else delete payload.id;

    const res = await fetch('/nexora/api/superadmin_tenant_save', {
        method: 'POST',
        headers: {'Content-Type': 'application/json', 'X-CSRF-Token': payload.csrf_token},
        body: JSON.stringify(payload)
    }).then(r => r.json());
    if (res.ok) location.reload();
    else alert(res.error || 'Erro ao guardar tenant');
    return false;
}
async function changeStatus(id, status) {
    if (!confirm(`Alterar estado do tenant para ${status}?`)) return;
    const res = await fetch('/nexora/api/superadmin_tenant_status', {
        method: 'POST',
        headers: {'Content-Type': 'application/json', 'X-CSRF-Token': '<?= $csrf ?>'},
        body: JSON.stringify({id, status})
    }).then(r => r.json());
    if (res.ok) location.reload();
    else alert(res.error || 'Erro ao alterar estado');
}
async function deleteTenant(id, nome) {
    if (!confirm(`Eliminar tenant "${nome}"? Esta acção é irreversível.`)) return;
    const res = await fetch('/nexora/api/superadmin_tenant_delete', {
        method: 'POST',
        headers: {'Content-Type': 'application/json', 'X-CSRF-Token': '<?= $csrf ?>'},
        body: JSON.stringify({id})
    }).then(r => r.json());
    if (res.ok) location.reload();
    else alert(res.error || 'Erro ao eliminar tenant');
}

// ── Criar Funcionário em Tenant ──────────────────────────────
const _criarFuncModal = document.getElementById('criarFuncModal');

async function openCriarFuncionarioModal(tenantId, tenantNome) {
    document.getElementById('criarFuncTenantId').value = tenantId;
    document.getElementById('criarFuncTenantNome').textContent = tenantNome;
    ['cf-nome','cf-cargo','cf-nuit','cf-telefone','cf-email','cf-endereco','cf-data-nasc','cf-salario'].forEach(id => {
        const el = document.getElementById(id);
        if (el) el.value = '';
    });
    document.getElementById('cf-tipo-contrato').value = 'efetivo';
    document.getElementById('cf-estado').value = 'ativo';
    document.getElementById('cf-genero').value = '';
    const elNumero = document.getElementById('cf-numero');
    elNumero.value = '';
    elNumero.placeholder = 'A gerar…';
    _criarFuncModal.style.display = 'flex';
    try {
        const r = await fetch(`/nexora/api/superadmin_proximo_numero_funcionario?tenant_id=${tenantId}`);
        if (r.ok) { const d = await r.json(); elNumero.value = d.numero ?? ''; }
    } catch (_) {}
}

function closeCriarFuncionarioModal() { _criarFuncModal.style.display = 'none'; }
_criarFuncModal.addEventListener('click', e => { if (e.target === _criarFuncModal) closeCriarFuncionarioModal(); });

async function submitCriarFuncionario() {
    const nome = document.getElementById('cf-nome').value.trim();
    if (!nome) { showToast('O nome completo é obrigatório.', 'error'); return; }

    const tenantId = parseInt(document.getElementById('criarFuncTenantId').value);
    const salario  = document.getElementById('cf-salario').value;

    const res = await fetch('/nexora/api/superadmin_criar_funcionario', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            tenant_id:           tenantId,
            nome_completo:       nome,
            numero_funcionario:  document.getElementById('cf-numero').value.trim() || null,
            cargo:               document.getElementById('cf-cargo').value.trim() || null,
            tipo_contrato:       document.getElementById('cf-tipo-contrato').value,
            data_admissao:       document.getElementById('cf-data-admissao').value || null,
            estado:              document.getElementById('cf-estado').value,
            genero:              document.getElementById('cf-genero').value || null,
            nuit:                document.getElementById('cf-nuit').value.trim() || null,
            telefone:            document.getElementById('cf-telefone').value.trim() || null,
            email:               document.getElementById('cf-email').value.trim() || null,
            endereco:            document.getElementById('cf-endereco').value.trim() || null,
            data_nascimento:     document.getElementById('cf-data-nasc').value || null,
            salario_base:        salario ? Number(salario) : null,
            csrf_token:          '<?= $csrf ?>',
        })
    }).then(r => r.json());

    if (res.ok) {
        showToast(res.msg || 'Funcionário criado com sucesso.');
        closeCriarFuncionarioModal();
    } else {
        showToast(res.erro || res.error || 'Erro ao criar funcionário.', 'error');
    }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
