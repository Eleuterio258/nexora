<?php
declare(strict_types=1);

$pageTitle  = 'Portal do Aluno — Gestão';
$activePage = 'aluno_portal';
$breadcrumb = $app->routes->alunoBreadcrumb([['Portal do Aluno', '']]);

try {
    $alunos  = $app->nexora->call('GET', '/api/escolar/portal/alunos')['body']  ?? [];
    $turmas  = $app->nexora->call('GET', '/api/escolar/classes')['body']        ?? [];
    $sessoes = $app->nexora->call('GET', '/api/escolar/portal/sessions')['body'] ?? [];
} catch (\Throwable) {
    $alunos = $turmas = $sessoes = [];
}

if (!is_array($alunos))  $alunos  = [];
if (!is_array($turmas))  $turmas  = [];
if (!is_array($sessoes)) $sessoes = [];

$csrf = $app->security->csrfToken();

$totalAlunos   = count($alunos);
$totalActivos  = count(array_filter($alunos, fn($a) => !empty($a['portal_ativo'])));
$totalConvites = count(array_filter($alunos, fn($a) => !empty($a['convite_pendente'])));
$totalSemPortal = $totalAlunos - $totalActivos;

include dirname(__DIR__) . '/layouts/' . (!empty($GLOBALS['_escolarPanel']) ? 'escola_top' : 'top') . '.php';
?>

<style>
.portal-kpi-grid { display:grid; grid-template-columns:repeat(4,1fr); gap:var(--adm-sp-4); margin-bottom:var(--adm-sp-5); }
.portal-kpi { background:#fff; border:1px solid var(--adm-border); border-radius:12px; padding:var(--adm-sp-4); }
.portal-kpi-val { font-size:1.75rem; font-weight:800; color:#0C4A6E; }
.portal-kpi-label { font-size:.8rem; color:var(--adm-muted); margin-top:.25rem; }

.portal-badge { display:inline-flex; align-items:center; gap:.3rem; padding:.2rem .6rem;
    border-radius:20px; font-size:.75rem; font-weight:600; white-space:nowrap; }
.portal-badge-activo   { background:#DCFCE7; color:#15803D; }
.portal-badge-inactivo { background:#F1F5F9; color:#64748B; }
.portal-badge-convite  { background:#FEF3C7; color:#B45309; }
.portal-badge-bloqueado{ background:#FEE2E2; color:#B91C1C; }

.portal-acoes { display:flex; gap:.35rem; flex-wrap:wrap; }
.portal-acoes .adm-btn { padding:.3rem .65rem; font-size:.78rem; }

.portal-tabs { display:flex; gap:0; border-bottom:2px solid var(--adm-border); margin-bottom:var(--adm-sp-5); }
.portal-tab { padding:.6rem 1.2rem; font-size:.875rem; font-weight:600; color:var(--adm-muted);
    border:none; background:none; cursor:pointer; border-bottom:2px solid transparent; margin-bottom:-2px; }
.portal-tab.active { color:#0369A1; border-bottom-color:#0369A1; }
</style>

<div class="adm-page-header">
    <div>
        <h1 class="adm-page-title">Portal do Aluno</h1>
        <p class="adm-text-muted">Activação, convites e acessos ao portal self-service dos alunos.</p>
    </div>
    <button class="adm-btn adm-btn-primary" onclick="document.getElementById('modalInviteTurma').style.display='flex'">
        <i class="fa-solid fa-paper-plane"></i> Convidar Turma
    </button>
</div>

<!-- KPIs -->
<div class="portal-kpi-grid">
    <div class="portal-kpi">
        <div class="portal-kpi-val"><?= $totalAlunos ?></div>
        <div class="portal-kpi-label">Total de alunos</div>
    </div>
    <div class="portal-kpi">
        <div class="portal-kpi-val" style="color:#15803D"><?= $totalActivos ?></div>
        <div class="portal-kpi-label">Portal activo</div>
    </div>
    <div class="portal-kpi">
        <div class="portal-kpi-val" style="color:#B45309"><?= $totalConvites ?></div>
        <div class="portal-kpi-label">Convites pendentes</div>
    </div>
    <div class="portal-kpi">
        <div class="portal-kpi-val" style="color:#64748B"><?= $totalSemPortal ?></div>
        <div class="portal-kpi-label">Sem portal</div>
    </div>
</div>

<!-- Tabs -->
<div class="portal-tabs">
    <button class="portal-tab active" onclick="switchTab('alunos',this)">
        <i class="fa-solid fa-users"></i> Alunos (<?= $totalAlunos ?>)
    </button>
    <button class="portal-tab" onclick="switchTab('sessoes',this)">
        <i class="fa-solid fa-clock-rotate-left"></i> Relatório de Acessos
    </button>
</div>

<!-- TAB: Alunos -->
<div id="tab-alunos">
    <div class="adm-card" style="padding:0;overflow:hidden">
        <div style="padding:var(--adm-sp-3) var(--adm-sp-4);border-bottom:1px solid var(--adm-border);display:flex;align-items:center;gap:var(--adm-sp-3)">
            <input type="search" class="adm-input" placeholder="Filtrar por nome ou código..." id="filtroAlunos"
                   oninput="filtrarAlunos()" style="max-width:280px;padding:.45rem .75rem;font-size:.85rem">
            <select class="adm-input" id="filtroEstado" onchange="filtrarAlunos()"
                    style="max-width:180px;padding:.45rem .75rem;font-size:.85rem">
                <option value="">Todos os estados</option>
                <option value="activo">Portal activo</option>
                <option value="convite">Convite pendente</option>
                <option value="inactivo">Sem portal</option>
                <option value="bloqueado">Bloqueados</option>
            </select>
        </div>
        <table class="adm-table" id="tabelaAlunos">
            <thead>
                <tr>
                    <th>Aluno</th>
                    <th>Email portal</th>
                    <th>Estado</th>
                    <th>Último acesso</th>
                    <th>Sessões</th>
                    <th>Acções</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($alunos as $a):
                $bloqueado = !empty($a['portal_bloqueado_ate']) && strtotime($a['portal_bloqueado_ate']) > time();
            ?>
            <tr data-nome="<?= strtolower(htmlspecialchars($a['nome'] ?? '')) ?>"
                data-codigo="<?= strtolower(htmlspecialchars($a['codigo'] ?? '')) ?>"
                data-estado="<?= $bloqueado ? 'bloqueado' : (!empty($a['portal_ativo']) ? 'activo' : (!empty($a['convite_pendente']) ? 'convite' : 'inactivo')) ?>">
                <td>
                    <div style="font-weight:600;font-size:.875rem"><?= htmlspecialchars($a['nome'] ?? '') ?></div>
                    <div style="font-size:.78rem;color:var(--adm-muted)"><?= htmlspecialchars($a['codigo'] ?? '') ?></div>
                </td>
                <td style="font-size:.85rem;color:var(--adm-muted)">
                    <?= htmlspecialchars($a['portal_email'] ?? '—') ?>
                </td>
                <td>
                    <?php if ($bloqueado): ?>
                        <span class="portal-badge portal-badge-bloqueado"><i class="fa-solid fa-lock"></i> Bloqueado</span>
                    <?php elseif (!empty($a['portal_ativo'])): ?>
                        <span class="portal-badge portal-badge-activo"><i class="fa-solid fa-circle-check"></i> Activo</span>
                    <?php elseif (!empty($a['convite_pendente'])): ?>
                        <span class="portal-badge portal-badge-convite"><i class="fa-solid fa-envelope"></i> Convite enviado</span>
                    <?php else: ?>
                        <span class="portal-badge portal-badge-inactivo"><i class="fa-solid fa-circle-xmark"></i> Inactivo</span>
                    <?php endif; ?>
                </td>
                <td style="font-size:.82rem;color:var(--adm-muted)">
                    <?= !empty($a['portal_ultimo_login']) ? date('d/m/Y H:i', strtotime($a['portal_ultimo_login'])) : '—' ?>
                </td>
                <td style="font-size:.82rem;text-align:center">
                    <span title="Sessões activas" style="font-weight:600;color:<?= ($a['sessoes_activas'] ?? 0) > 0 ? '#15803D' : 'var(--adm-muted)' ?>">
                        <?= (int)($a['sessoes_activas'] ?? 0) ?>
                    </span>
                </td>
                <td>
                    <div class="portal-acoes">
                        <?php if (empty($a['portal_ativo'])): ?>
                        <button class="adm-btn adm-btn-primary" title="Activar portal"
                                onclick="activarPortal(<?= (int)$a['id'] ?>, '<?= htmlspecialchars($a['nome'] ?? '', ENT_QUOTES) ?>')">
                            <i class="fa-solid fa-toggle-on"></i> Activar
                        </button>
                        <button class="adm-btn" title="Enviar convite"
                                onclick="convidarAluno(<?= (int)$a['id'] ?>, '<?= htmlspecialchars($a['nome'] ?? '', ENT_QUOTES) ?>')">
                            <i class="fa-solid fa-paper-plane"></i> Convidar
                        </button>
                        <?php else: ?>
                        <button class="adm-btn" title="Desactivar portal"
                                onclick="desactivarPortal(<?= (int)$a['id'] ?>, '<?= htmlspecialchars($a['nome'] ?? '', ENT_QUOTES) ?>')">
                            <i class="fa-solid fa-toggle-off"></i> Desactivar
                        </button>
                        <button class="adm-btn" title="Redefinir senha"
                                onclick="resetSenha(<?= (int)$a['id'] ?>, '<?= htmlspecialchars($a['nome'] ?? '', ENT_QUOTES) ?>')">
                            <i class="fa-solid fa-key"></i> Reset senha
                        </button>
                        <?php endif; ?>
                    </div>
                </td>
            </tr>
            <?php endforeach; ?>
            <?php if (empty($alunos)): ?>
            <tr><td colspan="6" style="text-align:center;padding:2rem;color:var(--adm-muted)">Nenhum aluno encontrado.</td></tr>
            <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- TAB: Relatório de Acessos -->
<div id="tab-sessoes" style="display:none">
    <div class="adm-card" style="padding:0;overflow:hidden">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Aluno</th>
                    <th>Email</th>
                    <th>Estado</th>
                    <th>Último acesso</th>
                    <th>Total sessões (30d)</th>
                    <th>Sessões activas</th>
                    <th>IPs distintos</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($sessoes as $s): ?>
            <tr>
                <td>
                    <div style="font-weight:600;font-size:.875rem"><?= htmlspecialchars($s['nome'] ?? '') ?></div>
                    <div style="font-size:.78rem;color:var(--adm-muted)"><?= htmlspecialchars($s['codigo'] ?? '') ?></div>
                </td>
                <td style="font-size:.85rem;color:var(--adm-muted)"><?= htmlspecialchars($s['portal_email'] ?? '—') ?></td>
                <td>
                    <?php if (!empty($s['portal_ativo'])): ?>
                        <span class="portal-badge portal-badge-activo">Activo</span>
                    <?php else: ?>
                        <span class="portal-badge portal-badge-inactivo">Inactivo</span>
                    <?php endif; ?>
                </td>
                <td style="font-size:.82rem;color:var(--adm-muted)">
                    <?= !empty($s['ultimo_acesso']) ? date('d/m/Y H:i', strtotime($s['ultimo_acesso'])) : '—' ?>
                </td>
                <td style="text-align:center;font-weight:600"><?= (int)($s['total_sessoes'] ?? 0) ?></td>
                <td style="text-align:center;color:<?= ($s['sessoes_activas'] ?? 0) > 0 ? '#15803D' : 'var(--adm-muted)' ?>;font-weight:600">
                    <?= (int)($s['sessoes_activas'] ?? 0) ?>
                </td>
                <td style="text-align:center"><?= (int)($s['ips_distintos'] ?? 0) ?></td>
            </tr>
            <?php endforeach; ?>
            <?php if (empty($sessoes)): ?>
            <tr><td colspan="7" style="text-align:center;padding:2rem;color:var(--adm-muted)">Sem registos de acesso.</td></tr>
            <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Modal: Activar Portal -->
<div id="modalActivar" class="adm-modal-overlay" style="display:none" onclick="if(event.target===this)this.style.display='none'">
    <div class="adm-modal-content" style="max-width:440px">
        <div class="adm-modal-header">
            <h3 class="adm-modal-title">Activar Portal</h3>
            <button class="adm-modal-close" onclick="document.getElementById('modalActivar').style.display='none'">&times;</button>
        </div>
        <div class="adm-modal-body">
            <p style="font-size:.875rem;color:var(--adm-muted);margin-bottom:1rem">
                A activar portal para: <strong id="activarNome"></strong>
            </p>
            <div class="adm-form-group">
                <label class="adm-label">Email do portal</label>
                <input type="email" class="adm-input" id="activarEmail" placeholder="aluno@escola.mz">
            </div>
            <div class="adm-form-group">
                <label class="adm-label">Password inicial</label>
                <input type="password" class="adm-input" id="activarPassword" placeholder="Mínimo 6 caracteres">
            </div>
            <div id="activarMsg"></div>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn" onclick="document.getElementById('modalActivar').style.display='none'">Cancelar</button>
            <button class="adm-btn adm-btn-primary" id="btnActivar" onclick="confirmarActivar()">
                <i class="fa-solid fa-toggle-on"></i> Activar
            </button>
        </div>
    </div>
</div>

<!-- Modal: Convidar Aluno -->
<div id="modalConvidar" class="adm-modal-overlay" style="display:none" onclick="if(event.target===this)this.style.display='none'">
    <div class="adm-modal-content" style="max-width:440px">
        <div class="adm-modal-header">
            <h3 class="adm-modal-title">Enviar Convite</h3>
            <button class="adm-modal-close" onclick="document.getElementById('modalConvidar').style.display='none'">&times;</button>
        </div>
        <div class="adm-modal-body">
            <p style="font-size:.875rem;color:var(--adm-muted);margin-bottom:1rem">
                Enviar link de convite para: <strong id="convidarNome"></strong>
            </p>
            <div class="adm-form-group">
                <label class="adm-label">Email do aluno</label>
                <input type="email" class="adm-input" id="convidarEmail" placeholder="aluno@escola.mz">
            </div>
            <div id="convidarMsg"></div>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn" onclick="document.getElementById('modalConvidar').style.display='none'">Cancelar</button>
            <button class="adm-btn adm-btn-primary" id="btnConvidar" onclick="confirmarConvite()">
                <i class="fa-solid fa-paper-plane"></i> Enviar Convite
            </button>
        </div>
    </div>
</div>

<!-- Modal: Reset Senha -->
<div id="modalReset" class="adm-modal-overlay" style="display:none" onclick="if(event.target===this)this.style.display='none'">
    <div class="adm-modal-content" style="max-width:420px">
        <div class="adm-modal-header">
            <h3 class="adm-modal-title">Redefinir Senha</h3>
            <button class="adm-modal-close" onclick="document.getElementById('modalReset').style.display='none'">&times;</button>
        </div>
        <div class="adm-modal-body">
            <p style="font-size:.875rem;color:var(--adm-muted);margin-bottom:1rem">
                Redefinir senha de: <strong id="resetNome"></strong>
            </p>
            <div class="adm-form-group">
                <label class="adm-label">Nova password</label>
                <input type="password" class="adm-input" id="resetPassword" placeholder="Mínimo 6 caracteres">
            </div>
            <div id="resetMsg"></div>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn" onclick="document.getElementById('modalReset').style.display='none'">Cancelar</button>
            <button class="adm-btn adm-btn-primary" id="btnReset" onclick="confirmarReset()">
                <i class="fa-solid fa-key"></i> Redefinir
            </button>
        </div>
    </div>
</div>

<!-- Modal: Convidar Turma Inteira -->
<div id="modalInviteTurma" class="adm-modal-overlay" style="display:none" onclick="if(event.target===this)this.style.display='none'">
    <div class="adm-modal-content" style="max-width:460px">
        <div class="adm-modal-header">
            <h3 class="adm-modal-title">Convidar Turma Inteira</h3>
            <button class="adm-modal-close" onclick="document.getElementById('modalInviteTurma').style.display='none'">&times;</button>
        </div>
        <div class="adm-modal-body">
            <p style="font-size:.875rem;color:var(--adm-muted);margin-bottom:1rem">
                Gera convites para todos os alunos activos da turma que ainda não têm portal. O email é gerado automaticamente como <code>codigo@dominio</code>.
            </p>
            <div class="adm-form-group">
                <label class="adm-label">Turma</label>
                <select class="adm-input" id="inviteTurmaId">
                    <option value="">Seleccione a turma...</option>
                    <?php foreach ($turmas as $t): ?>
                    <option value="<?= (int)$t['id'] ?>"><?= htmlspecialchars($t['nome'] ?? '') ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label">Domínio de email</label>
                <input type="text" class="adm-input" id="inviteEmailDomain" placeholder="escola.mz">
                <p style="font-size:.78rem;color:var(--adm-muted);margin-top:.3rem">
                    Os emails serão gerados como: <strong>codigo_aluno@dominio</strong>
                </p>
            </div>
            <div id="inviteTurmaMsg"></div>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn" onclick="document.getElementById('modalInviteTurma').style.display='none'">Cancelar</button>
            <button class="adm-btn adm-btn-primary" id="btnInviteTurma" onclick="confirmarInviteTurma()">
                <i class="fa-solid fa-paper-plane"></i> Gerar Convites
            </button>
        </div>
    </div>
</div>

<script>
const CSRF = '<?= htmlspecialchars($csrf) ?>';
let _currentStudentId = null;

// ── Tabs ──────────────────────────────────────────────────────────────────────
function switchTab(tab, btn) {
    document.querySelectorAll('[id^="tab-"]').forEach(el => el.style.display = 'none');
    document.querySelectorAll('.portal-tab').forEach(el => el.classList.remove('active'));
    document.getElementById('tab-' + tab).style.display = '';
    btn.classList.add('active');
}

// ── Filtro da tabela ──────────────────────────────────────────────────────────
function filtrarAlunos() {
    const q     = document.getElementById('filtroAlunos').value.toLowerCase();
    const estado = document.getElementById('filtroEstado').value;
    document.querySelectorAll('#tabelaAlunos tbody tr').forEach(tr => {
        const nome   = tr.dataset.nome   || '';
        const codigo = tr.dataset.codigo || '';
        const est    = tr.dataset.estado || '';
        const matchQ = !q || nome.includes(q) || codigo.includes(q);
        const matchE = !estado || est === estado;
        tr.style.display = (matchQ && matchE) ? '' : 'none';
    });
}

// ── Helpers ───────────────────────────────────────────────────────────────────
async function apiPost(path, data) {
    const r = await fetch('/nexora/api/proxy?path=' + encodeURIComponent(path), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': CSRF },
        body: JSON.stringify(data),
    });
    return { status: r.status, body: await r.json().catch(() => ({})) };
}
function msgBox(el, tipo, texto) {
    const bg = tipo === 'ok' ? '#DCFCE7' : '#FEE2E2';
    const cor = tipo === 'ok' ? '#15803D' : '#B91C1C';
    el.innerHTML = `<div style="background:${bg};color:${cor};padding:.5rem .75rem;border-radius:6px;font-size:.82rem;margin-top:.5rem">${texto}</div>`;
}

// ── Activar ───────────────────────────────────────────────────────────────────
function activarPortal(id, nome) {
    _currentStudentId = id;
    document.getElementById('activarNome').textContent = nome;
    document.getElementById('activarEmail').value = '';
    document.getElementById('activarPassword').value = '';
    document.getElementById('activarMsg').innerHTML = '';
    document.getElementById('modalActivar').style.display = 'flex';
}
async function confirmarActivar() {
    const email = document.getElementById('activarEmail').value.trim();
    const pass  = document.getElementById('activarPassword').value;
    const msg   = document.getElementById('activarMsg');
    if (!email || pass.length < 6) { msgBox(msg, 'err', 'Email e password (mín. 6 chars) são obrigatórios.'); return; }
    const btn = document.getElementById('btnActivar');
    btn.disabled = true;
    const r = await apiPost(`/api/escolar/students/${_currentStudentId}/portal/activate`, { email, password: pass });
    btn.disabled = false;
    if (r.status === 200) { msgBox(msg, 'ok', 'Portal activado! A recarregar...'); setTimeout(() => location.reload(), 1200); }
    else { msgBox(msg, 'err', r.body?.error || r.body?.erro || 'Erro ao activar.'); }
}

// ── Convidar ──────────────────────────────────────────────────────────────────
function convidarAluno(id, nome) {
    _currentStudentId = id;
    document.getElementById('convidarNome').textContent = nome;
    document.getElementById('convidarEmail').value = '';
    document.getElementById('convidarMsg').innerHTML = '';
    document.getElementById('modalConvidar').style.display = 'flex';
}
async function confirmarConvite() {
    const email = document.getElementById('convidarEmail').value.trim();
    const msg   = document.getElementById('convidarMsg');
    if (!email) { msgBox(msg, 'err', 'Email é obrigatório.'); return; }
    const btn = document.getElementById('btnConvidar');
    btn.disabled = true;
    const r = await apiPost(`/api/escolar/students/${_currentStudentId}/portal/invite`, { email });
    btn.disabled = false;
    if (r.status === 200) {
        const url = r.body?.invite_url ?? '';
        msgBox(msg, 'ok', `Convite gerado! Link: <code style="word-break:break-all">${url}</code>`);
        setTimeout(() => location.reload(), 3000);
    } else { msgBox(msg, 'err', r.body?.error || r.body?.erro || 'Erro ao gerar convite.'); }
}

// ── Desactivar ────────────────────────────────────────────────────────────────
async function desactivarPortal(id, nome) {
    if (!confirm(`Desactivar portal de "${nome}"? Todas as sessões activas serão encerradas.`)) return;
    const r = await apiPost(`/api/escolar/students/${id}/portal/deactivate`, {});
    if (r.status === 200) location.reload();
    else alert(r.body?.error || r.body?.erro || 'Erro ao desactivar.');
}

// ── Reset Senha ───────────────────────────────────────────────────────────────
function resetSenha(id, nome) {
    _currentStudentId = id;
    document.getElementById('resetNome').textContent = nome;
    document.getElementById('resetPassword').value = '';
    document.getElementById('resetMsg').innerHTML = '';
    document.getElementById('modalReset').style.display = 'flex';
}
async function confirmarReset() {
    const pass = document.getElementById('resetPassword').value;
    const msg  = document.getElementById('resetMsg');
    if (pass.length < 6) { msgBox(msg, 'err', 'Password mínima de 6 caracteres.'); return; }
    const btn = document.getElementById('btnReset');
    btn.disabled = true;
    const r = await apiPost(`/api/escolar/students/${_currentStudentId}/portal/reset-senha`, { password: pass });
    btn.disabled = false;
    if (r.status === 200) { msgBox(msg, 'ok', 'Senha redefinida com sucesso!'); setTimeout(() => location.reload(), 1200); }
    else { msgBox(msg, 'err', r.body?.error || r.body?.erro || 'Erro ao redefinir.'); }
}

// ── Convidar Turma ────────────────────────────────────────────────────────────
async function confirmarInviteTurma() {
    const classId = document.getElementById('inviteTurmaId').value;
    const domain  = document.getElementById('inviteEmailDomain').value.trim();
    const msg     = document.getElementById('inviteTurmaMsg');
    if (!classId)  { msgBox(msg, 'err', 'Seleccione uma turma.'); return; }
    if (!domain)   { msgBox(msg, 'err', 'Domínio de email é obrigatório.'); return; }
    const btn = document.getElementById('btnInviteTurma');
    btn.disabled = true;
    const r = await apiPost(`/api/escolar/classes/${classId}/portal/invite-all`, { email_domain: domain });
    btn.disabled = false;
    if (r.status === 200) {
        msgBox(msg, 'ok', r.body?.mensagem || `${r.body?.convidados ?? 0} convites gerados.`);
        setTimeout(() => location.reload(), 2000);
    } else { msgBox(msg, 'err', r.body?.error || r.body?.erro || 'Erro ao gerar convites.'); }
}
</script>

<?php include dirname(__DIR__) . '/layouts/' . (!empty($GLOBALS['_escolarPanel']) ? 'escola_bottom' : 'bottom') . '.php'; ?>

