<?php
declare(strict_types=1);

$resp   = $app->nexora->call('GET', '/api/rh/cargos');
$cargos = is_array($resp['body'] ?? null) && array_is_list($resp['body']) ? $resp['body'] : [];

$ativos   = array_values(array_filter($cargos, fn($c) => $c['ativo']));
$inativos = array_values(array_filter($cargos, fn($c) => !$c['ativo']));

$podeGerir = $app->session->can('recursos-humanos', 'gerir_funcionarios');

$fmt = fn(?float $v) => $v !== null ? number_format($v, 0, ',', '.') . ' MT' : '—';

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Cargos';
$activePage = 'rh_cargos';
$breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Cargos', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Cargos</h1>
    <?php if ($podeGerir): ?>
    <div class="adm-page-header-actions">
        <button class="adm-btn adm-btn-primary" type="button" onclick="openModal()">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:5px"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Novo Cargo
        </button>
    </div>
    <?php endif; ?>
</div>

<!-- Stats -->
<div class="adm-stats-grid" style="grid-template-columns:repeat(4,1fr);margin-bottom:var(--adm-sp-6)">
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo count($cargos) ?></div>
            <div class="adm-stat-label">Cargos Total</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--green">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo count($ativos) ?></div>
            <div class="adm-stat-label">Activos</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo array_sum(array_column($cargos, 'num_funcionarios')) ?></div>
            <div class="adm-stat-label">Funcionários alocados</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--green">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php
                $maxSal = $cargos ? max(array_column($cargos, 'salario_max')) : 0;
                echo number_format((float)$maxSal, 0, ',', '.');
            ?></div>
            <div class="adm-stat-label">Sal. Máx. (MT)</div>
        </div>
    </div>
</div>

<!-- Tabela -->
<div class="adm-card">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Lista de Cargos</h2>
        <div style="display:flex;gap:var(--adm-sp-2)">
            <input class="adm-input" type="search" id="cargoSearch" placeholder="Pesquisar cargo…" oninput="filterCargos()" style="width:220px">
        </div>
    </div>
    <?php if ($cargos): ?>
    <div class="adm-table-wrap">
        <table class="adm-table" id="cargosTable">
            <thead>
                <tr>
                    <th>Código</th>
                    <th>Nome</th>
                    <th>Descrição</th>
                    <th>Sal. Mínimo</th>
                    <th>Sal. Máximo</th>
                    <th>Funcionários</th>
                    <th>Estado</th>
                    <?php if ($podeGerir): ?><th>Ações</th><?php endif; ?>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($cargos as $c): ?>
            <tr class="cargo-row" data-search="<?php echo strtolower(htmlspecialchars($c['codigo'].' '.$c['nome'].' '.($c['descricao']??''))) ?>">
                <td>
                    <code style="font-size:.78rem;background:var(--adm-gray-100);padding:2px 6px;border-radius:4px;color:var(--adm-gray-700)">
                        <?php echo htmlspecialchars($c['codigo']) ?>
                    </code>
                </td>
                <td class="adm-fw-600"><?php echo htmlspecialchars($c['nome']) ?></td>
                <td class="adm-text-muted" style="font-size:var(--adm-text-sm);max-width:260px">
                    <?php echo $c['descricao'] ? htmlspecialchars($c['descricao']) : '—' ?>
                </td>
                <td class="adm-text-muted"><?php echo $fmt($c['salario_min'] !== null ? (float)$c['salario_min'] : null) ?></td>
                <td class="adm-text-muted"><?php echo $fmt($c['salario_max'] !== null ? (float)$c['salario_max'] : null) ?></td>
                <td>
                    <?php if ((int)$c['num_funcionarios'] > 0): ?>
                    <span class="adm-badge adm-badge--blue"><?php echo (int)$c['num_funcionarios'] ?></span>
                    <?php else: ?>
                    <span class="adm-text-muted">—</span>
                    <?php endif; ?>
                </td>
                <td>
                    <span class="adm-badge <?php echo $c['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>">
                        <?php echo $c['ativo'] ? 'Activo' : 'Inactivo' ?>
                    </span>
                </td>
                <?php if ($podeGerir): ?>
                <td>
                    <div class="adm-row-actions">
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button"
                            onclick='openModal(<?php echo json_encode([
                                "id"         => $c["id"],
                                "codigo"     => $c["codigo"],
                                "nome"       => $c["nome"],
                                "descricao"  => $c["descricao"] ?? "",
                                "salario_min"=> $c["salario_min"],
                                "salario_max"=> $c["salario_max"],
                                "ativo"      => $c["ativo"],
                            ], JSON_UNESCAPED_UNICODE) ?>)'>
                            Editar
                        </button>
                        <?php if (!(int)$c['num_funcionarios']): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-red)" type="button"
                            onclick="eliminarCargo(<?php echo (int)$c['id'] ?>, '<?php echo htmlspecialchars(addslashes($c['nome'])) ?>')">
                            Eliminar
                        </button>
                        <?php endif; ?>
                    </div>
                </td>
                <?php endif; ?>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <p class="adm-empty-title">Nenhum cargo registado</p>
        <p class="adm-empty-sub">Clique em "Novo Cargo" para adicionar o primeiro.</p>
    </div>
    <?php endif; ?>
</div>

<!-- Modal Cargo -->
<div class="adm-modal" id="cargoModal" style="display:none">
    <div class="adm-modal-content" style="max-width:560px">
        <div class="adm-modal-header">
            <h3 id="cargoModalTitle">Novo Cargo</h3>
            <button class="adm-btn adm-btn-ghost adm-btn-icon" type="button" onclick="closeModal()">&times;</button>
        </div>
        <div style="padding:var(--adm-sp-5) var(--adm-sp-6);max-height:70vh;overflow-y:auto">
            <input type="hidden" id="cargo-id">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="cargo-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="cargo-codigo" maxlength="30" placeholder="ex: GEST-PROJ" style="font-family:monospace">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="cargo-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="cargo-nome" maxlength="100" placeholder="ex: Gestor de Projetos">
                </div>
            </div>
            <div class="adm-form-group adm-mb-4">
                <label class="adm-label" for="cargo-descricao">Descrição</label>
                <input class="adm-input" type="text" id="cargo-descricao" maxlength="200" placeholder="ex: Coordenação e gestão de projetos">
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="cargo-sal-min">Salário Mínimo (MT)</label>
                    <input class="adm-input" type="number" id="cargo-sal-min" step="500" min="0" placeholder="ex: 45000">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="cargo-sal-max">Salário Máximo (MT)</label>
                    <input class="adm-input" type="number" id="cargo-sal-max" step="500" min="0" placeholder="ex: 90000">
                </div>
            </div>
            <div class="adm-form-group" id="cargo-ativo-group" style="display:none">
                <label class="adm-label" for="cargo-ativo">Estado</label>
                <select class="adm-select" id="cargo-ativo">
                    <option value="true">Activo</option>
                    <option value="false">Inactivo</option>
                </select>
            </div>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-ghost" type="button" onclick="closeModal()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" type="button" onclick="saveCargo()">Guardar</button>
        </div>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';
const _cargoModal = document.getElementById('cargoModal');

function openModal(data) {
    document.getElementById('cargo-id').value      = data?.id ?? '';
    document.getElementById('cargo-codigo').value   = data?.codigo ?? '';
    document.getElementById('cargo-nome').value     = data?.nome ?? '';
    document.getElementById('cargo-descricao').value= data?.descricao ?? '';
    document.getElementById('cargo-sal-min').value  = data?.salario_min ?? '';
    document.getElementById('cargo-sal-max').value  = data?.salario_max ?? '';
    document.getElementById('cargo-ativo').value    = data?.ativo !== false ? 'true' : 'false';
    document.getElementById('cargo-ativo-group').style.display = data?.id ? '' : 'none';
    document.getElementById('cargoModalTitle').textContent = data?.id ? 'Editar Cargo' : 'Novo Cargo';
    document.getElementById('cargo-codigo').disabled = !!data?.id;
    _cargoModal.style.display = 'flex';
}
function closeModal() { _cargoModal.style.display = 'none'; }
_cargoModal.addEventListener('click', e => { if (e.target === _cargoModal) closeModal(); });

async function saveCargo() {
    const id     = document.getElementById('cargo-id').value;
    const codigo = document.getElementById('cargo-codigo').value.trim().toUpperCase();
    const nome   = document.getElementById('cargo-nome').value.trim();
    if (!nome) { showToast('O nome é obrigatório.', 'error'); return; }
    if (!id && !codigo) { showToast('O código é obrigatório.', 'error'); return; }

    const payload = {
        codigo,
        nome,
        descricao:   document.getElementById('cargo-descricao').value.trim() || null,
        salario_min: parseFloat(document.getElementById('cargo-sal-min').value) || null,
        salario_max: parseFloat(document.getElementById('cargo-sal-max').value) || null,
        ativo:       document.getElementById('cargo-ativo').value === 'true',
        csrf: CSRF,
    };
    if (id) payload._id = Number(id);

    try {
        const res  = await fetch('/nexora/api/rh_operacao', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ operation: id ? 'cargo.update' : 'cargo.create', id: id ? Number(id) : null, payload, csrf: CSRF })
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Cargo guardado com sucesso.');
            closeModal();
            setTimeout(() => location.reload(), 600);
        } else {
            showToast(data.erro || 'Erro ao guardar.', 'error');
        }
    } catch { showToast('Erro de ligação.', 'error'); }
}

function eliminarCargo(id, nome) {
    openConfirm(`Eliminar cargo "${nome}"`, 'Esta acção não pode ser revertida.', async () => {
        try {
            const res  = await fetch('/nexora/api/rh_operacao', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ operation: 'cargo.delete', id, payload: {}, csrf: CSRF })
            });
            const data = await res.json();
            if (data.ok) { showToast('Cargo eliminado.'); setTimeout(() => location.reload(), 600); }
            else showToast(data.erro || 'Erro.', 'error');
        } catch { showToast('Erro de ligação.', 'error'); }
    });
}

function filterCargos() {
    const q = document.getElementById('cargoSearch').value.toLowerCase();
    document.querySelectorAll('.cargo-row').forEach(tr => {
        tr.style.display = tr.dataset.search.includes(q) ? '' : 'none';
    });
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
