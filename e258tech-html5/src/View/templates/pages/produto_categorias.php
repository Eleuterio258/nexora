<?php

    $categorias = $app->nexora->call('GET', '/api/produtos/categorias')['body'] ?? [];
    $marcas     = $app->nexora->call('GET', '/api/produtos/marcas')['body'] ?? [];
    $unidades   = $app->nexora->call('GET', '/api/produtos/unidades')['body'] ?? [];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Categorias, Marcas & Unidades';
    $activePage = 'produtos';
    $breadcrumb = [['Admin', '/nexora/'], ['Produtos', '/nexora/produtos'], ['Categorias & Marcas', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Categorias, Marcas &amp; Unidades</h1>
    <div class="adm-page-header-actions">
        <a href="/nexora/produtos" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
            Voltar
        </a>
    </div>
</div>

<div class="adm-tabs" id="mainTabs">
    <button class="adm-tab active" onclick="switchTab('categorias',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/></svg>
        Categorias
        <?php if (count($categorias)): ?><span class="adm-tab-badge"><?php echo count($categorias) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('marcas',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
        Marcas
        <?php if (count($marcas)): ?><span class="adm-tab-badge"><?php echo count($marcas) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('unidades',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18"/><path d="M9 21V9"/></svg>
        Unidades
        <?php if (count($unidades)): ?><span class="adm-tab-badge"><?php echo count($unidades) ?></span><?php endif; ?>
    </button>
</div>

<!-- ── Categorias ─────────────────────────────────────────── -->
<div class="adm-tab-panel active" id="tab-categorias">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Categorias</h2></div>
        <?php if ($categorias): ?>
        <div class="adm-table-wrap">
            <table class="adm-table" id="categoriasTable">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Descrição</th><th>Estado</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($categorias as $c): ?>
                <tr data-id="<?php echo (int) $c['id'] ?>"
                    data-codigo="<?php echo htmlspecialchars((string) ($c['codigo'] ?? '')) ?>"
                    data-nome="<?php echo htmlspecialchars($c['nome']) ?>"
                    data-descricao="<?php echo htmlspecialchars((string) ($c['descricao'] ?? '')) ?>"
                    data-ativo="<?php echo $c['ativo'] ? '1' : '0' ?>">
                    <td class="adm-text-muted"><?php echo htmlspecialchars((string) ($c['codigo'] ?? '—')) ?></td>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($c['nome']) ?></td>
                    <td class="adm-text-sm adm-text-muted"><?php echo $c['descricao'] ? htmlspecialchars($c['descricao']) : '—' ?></td>
                    <td><span class="adm-badge <?php echo $c['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $c['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                    <td>
                        <div class="adm-actions">
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="editCategoria(this)">Editar</button>
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-red)"
                                    onclick="deleteCategoria(<?php echo (int) $c['id'] ?>, '<?php echo htmlspecialchars(addslashes($c['nome'])) ?>')">Eliminar</button>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                <?php if (! $categorias): ?>
                <tr><td colspan="5" class="adm-text-muted adm-text-sm" style="text-align:center;padding:var(--adm-sp-4)">Nenhuma categoria criada.</td></tr>
                <?php endif; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-card-body">
            <p class="adm-text-muted adm-text-sm" style="margin:0">Nenhuma categoria criada.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title" id="categoriaFormTitle">Adicionar Categoria</h2></div>
        <div class="adm-card-body">
            <input type="hidden" id="c-id" value="">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="c-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="c-codigo" maxlength="50" placeholder="ex: CAT-001">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="c-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="c-nome" maxlength="120" placeholder="ex: Materiais de Construção">
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="c-descricao">Descrição</label>
                <textarea class="adm-textarea" id="c-descricao" rows="2"></textarea>
            </div>
            <label class="adm-toggle" style="margin-bottom:var(--adm-sp-4)">
                <input type="checkbox" id="c-ativo" checked>
                <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                <span class="adm-toggle-label">Ativo</span>
            </label>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-outline" type="button" onclick="resetCategoriaForm()">Limpar</button>
                <button class="adm-btn adm-btn-primary" type="button" id="btnCategoriaSave" onclick="saveCategoria()">Adicionar Categoria</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Marcas ─────────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-marcas">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Marcas</h2></div>
        <?php if ($marcas): ?>
        <div class="adm-table-wrap">
            <table class="adm-table" id="marcasTable">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Descrição</th><th>Estado</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($marcas as $m): ?>
                <tr data-id="<?php echo (int) $m['id'] ?>"
                    data-codigo="<?php echo htmlspecialchars((string) ($m['codigo'] ?? '')) ?>"
                    data-nome="<?php echo htmlspecialchars($m['nome']) ?>"
                    data-descricao="<?php echo htmlspecialchars((string) ($m['descricao'] ?? '')) ?>"
                    data-ativo="<?php echo $m['ativo'] ? '1' : '0' ?>">
                    <td class="adm-text-muted"><?php echo htmlspecialchars((string) ($m['codigo'] ?? '—')) ?></td>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($m['nome']) ?></td>
                    <td class="adm-text-sm adm-text-muted"><?php echo $m['descricao'] ? htmlspecialchars($m['descricao']) : '—' ?></td>
                    <td><span class="adm-badge <?php echo $m['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $m['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                    <td>
                        <div class="adm-actions">
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="editMarca(this)">Editar</button>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                <?php if (! $marcas): ?>
                <tr><td colspan="5" class="adm-text-muted adm-text-sm" style="text-align:center;padding:var(--adm-sp-4)">Nenhuma marca criada.</td></tr>
                <?php endif; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-card-body">
            <p class="adm-text-muted adm-text-sm" style="margin:0">Nenhuma marca criada.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title" id="marcaFormTitle">Adicionar Marca</h2></div>
        <div class="adm-card-body">
            <input type="hidden" id="m-id" value="">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="m-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="m-codigo" maxlength="50" placeholder="ex: MRC-001">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="m-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="m-nome" maxlength="120" placeholder="ex: Cimentos de Moçambique">
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="m-descricao">Descrição</label>
                <textarea class="adm-textarea" id="m-descricao" rows="2"></textarea>
            </div>
            <label class="adm-toggle" style="margin-bottom:var(--adm-sp-4)">
                <input type="checkbox" id="m-ativo" checked>
                <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                <span class="adm-toggle-label">Ativo</span>
            </label>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-outline" type="button" onclick="resetMarcaForm()">Limpar</button>
                <button class="adm-btn adm-btn-primary" type="button" id="btnMarcaSave" onclick="saveMarca()">Adicionar Marca</button>
            </div>
        </div>
    </div>
</div>

<!-- ── Unidades ───────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-unidades">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Unidades</h2></div>
        <?php if ($unidades): ?>
        <div class="adm-table-wrap">
            <table class="adm-table" id="unidadesTable">
                <thead>
                    <tr><th>Código</th><th>Nome</th><th>Símbolo</th><th>Ações</th></tr>
                </thead>
                <tbody>
                <?php foreach ($unidades as $u): ?>
                <tr data-id="<?php echo (int) $u['id'] ?>"
                    data-codigo="<?php echo htmlspecialchars((string) ($u['codigo'] ?? '')) ?>"
                    data-nome="<?php echo htmlspecialchars($u['nome']) ?>"
                    data-simbolo="<?php echo htmlspecialchars((string) ($u['simbolo'] ?? '')) ?>">
                    <td class="adm-text-muted"><?php echo htmlspecialchars((string) ($u['codigo'] ?? '—')) ?></td>
                    <td class="adm-fw-600"><?php echo htmlspecialchars($u['nome']) ?></td>
                    <td><?php echo $u['simbolo'] ? htmlspecialchars($u['simbolo']) : '—' ?></td>
                    <td>
                        <div class="adm-actions">
                            <button class="adm-btn adm-btn-ghost adm-btn-sm" onclick="editUnidade(this)">Editar</button>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                <?php if (! $unidades): ?>
                <tr><td colspan="4" class="adm-text-muted adm-text-sm" style="text-align:center;padding:var(--adm-sp-4)">Nenhuma unidade criada.</td></tr>
                <?php endif; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-card-body">
            <p class="adm-text-muted adm-text-sm" style="margin:0">Nenhuma unidade criada.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title" id="unidadeFormTitle">Adicionar Unidade</h2></div>
        <div class="adm-card-body">
            <input type="hidden" id="u-id" value="">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="u-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="u-codigo" maxlength="20" placeholder="ex: UN, KG, M2">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="u-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="u-nome" maxlength="100" placeholder="ex: Unidade, Quilograma">
                </div>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="u-simbolo">Símbolo</label>
                <input class="adm-input" type="text" id="u-simbolo" maxlength="10" placeholder="ex: un, kg, m²">
            </div>
            <div style="display:flex;gap:var(--adm-sp-3)">
                <button class="adm-btn adm-btn-outline" type="button" onclick="resetUnidadeForm()">Limpar</button>
                <button class="adm-btn adm-btn-primary" type="button" id="btnUnidadeSave" onclick="saveUnidade()">Adicionar Unidade</button>
            </div>
        </div>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

// ── Tabs ─────────────────────────────────────────────────────
function switchTab(name, btn) {
    document.querySelectorAll('.adm-tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.adm-tab').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
}

document.addEventListener('DOMContentLoaded', () => {
    const tabs = ['categorias', 'marcas', 'unidades'];
    const hash = location.hash.replace('#', '');
    const idx  = tabs.indexOf(hash);
    if (idx > 0) {
        const btn = document.querySelectorAll('#mainTabs .adm-tab')[idx];
        if (btn) switchTab(hash, btn);
    }
});

// ── Categorias ───────────────────────────────────────────────
function resetCategoriaForm() {
    document.getElementById('c-id').value = '';
    document.getElementById('c-codigo').value = '';
    document.getElementById('c-codigo').disabled = false;
    document.getElementById('c-nome').value = '';
    document.getElementById('c-descricao').value = '';
    document.getElementById('c-ativo').checked = true;
    document.getElementById('categoriaFormTitle').textContent = 'Adicionar Categoria';
    document.getElementById('btnCategoriaSave').textContent = 'Adicionar Categoria';
}

function editCategoria(btn) {
    const row = btn.closest('tr');
    document.getElementById('c-id').value = row.dataset.id;
    document.getElementById('c-codigo').value = row.dataset.codigo;
    document.getElementById('c-codigo').disabled = true;
    document.getElementById('c-nome').value = row.dataset.nome;
    document.getElementById('c-descricao').value = row.dataset.descricao;
    document.getElementById('c-ativo').checked = row.dataset.ativo === '1';
    document.getElementById('categoriaFormTitle').textContent = 'Editar Categoria';
    document.getElementById('btnCategoriaSave').textContent = 'Guardar';
    document.getElementById('tab-categorias').scrollIntoView({behavior: 'smooth', block: 'end'});
}

async function saveCategoria() {
    const id     = document.getElementById('c-id').value;
    const codigo = document.getElementById('c-codigo').value.trim();
    const nome   = document.getElementById('c-nome').value.trim();

    if (!id && (!codigo || !nome)) { showToast('Código e nome são obrigatórios.', 'error'); return; }
    if (id && !nome) { showToast('O nome é obrigatório.', 'error'); return; }

    const payload = {
        id: id ? Number(id) : null,
        nome,
        descricao: document.getElementById('c-descricao').value.trim() || null,
        ativo: document.getElementById('c-ativo').checked,
        csrf: CSRF
    };
    if (!id) payload.codigo = codigo;

    try {
        const res  = await fetch('/nexora/api/produto_categoria_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Categoria guardada com sucesso.');
            location.hash = 'categorias';
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

function deleteCategoria(id, nome) {
    openConfirm(
        'Eliminar categoria',
        'Eliminar a categoria "' + nome + '"?',
        async () => {
            try {
                const res  = await fetch('/nexora/api/produto_categoria_remover', {
                    method: 'POST', headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id, csrf: CSRF})
                });
                const data = await res.json();
                if (data.ok) {
                    showToast('Categoria eliminada');
                    location.hash = 'categorias';
                    setTimeout(() => location.reload(), 700);
                } else {
                    showToast(data.erro || 'Erro', 'error');
                }
            } catch { showToast('Erro de ligação', 'error'); }
        }
    );
}

// ── Marcas ───────────────────────────────────────────────────
function resetMarcaForm() {
    document.getElementById('m-id').value = '';
    document.getElementById('m-codigo').value = '';
    document.getElementById('m-codigo').disabled = false;
    document.getElementById('m-nome').value = '';
    document.getElementById('m-descricao').value = '';
    document.getElementById('m-ativo').checked = true;
    document.getElementById('marcaFormTitle').textContent = 'Adicionar Marca';
    document.getElementById('btnMarcaSave').textContent = 'Adicionar Marca';
}

function editMarca(btn) {
    const row = btn.closest('tr');
    document.getElementById('m-id').value = row.dataset.id;
    document.getElementById('m-codigo').value = row.dataset.codigo;
    document.getElementById('m-codigo').disabled = true;
    document.getElementById('m-nome').value = row.dataset.nome;
    document.getElementById('m-descricao').value = row.dataset.descricao;
    document.getElementById('m-ativo').checked = row.dataset.ativo === '1';
    document.getElementById('marcaFormTitle').textContent = 'Editar Marca';
    document.getElementById('btnMarcaSave').textContent = 'Guardar';
    document.getElementById('tab-marcas').scrollIntoView({behavior: 'smooth', block: 'end'});
}

async function saveMarca() {
    const id     = document.getElementById('m-id').value;
    const codigo = document.getElementById('m-codigo').value.trim();
    const nome   = document.getElementById('m-nome').value.trim();

    if (!id && (!codigo || !nome)) { showToast('Código e nome são obrigatórios.', 'error'); return; }
    if (id && !nome) { showToast('O nome é obrigatório.', 'error'); return; }

    const payload = {
        id: id ? Number(id) : null,
        nome,
        descricao: document.getElementById('m-descricao').value.trim() || null,
        ativo: document.getElementById('m-ativo').checked,
        csrf: CSRF
    };
    if (!id) payload.codigo = codigo;

    try {
        const res  = await fetch('/nexora/api/produto_marca_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Marca guardada com sucesso.');
            location.hash = 'marcas';
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

// ── Unidades ─────────────────────────────────────────────────
function resetUnidadeForm() {
    document.getElementById('u-id').value = '';
    document.getElementById('u-codigo').value = '';
    document.getElementById('u-codigo').disabled = false;
    document.getElementById('u-nome').value = '';
    document.getElementById('u-simbolo').value = '';
    document.getElementById('unidadeFormTitle').textContent = 'Adicionar Unidade';
    document.getElementById('btnUnidadeSave').textContent = 'Adicionar Unidade';
}

function editUnidade(btn) {
    const row = btn.closest('tr');
    document.getElementById('u-id').value = row.dataset.id;
    document.getElementById('u-codigo').value = row.dataset.codigo;
    document.getElementById('u-codigo').disabled = true;
    document.getElementById('u-nome').value = row.dataset.nome;
    document.getElementById('u-simbolo').value = row.dataset.simbolo;
    document.getElementById('unidadeFormTitle').textContent = 'Editar Unidade';
    document.getElementById('btnUnidadeSave').textContent = 'Guardar';
    document.getElementById('tab-unidades').scrollIntoView({behavior: 'smooth', block: 'end'});
}

async function saveUnidade() {
    const id     = document.getElementById('u-id').value;
    const codigo = document.getElementById('u-codigo').value.trim();
    const nome   = document.getElementById('u-nome').value.trim();

    if (!id && (!codigo || !nome)) { showToast('Código e nome são obrigatórios.', 'error'); return; }
    if (id && !nome) { showToast('O nome é obrigatório.', 'error'); return; }

    const payload = {
        id: id ? Number(id) : null,
        nome,
        simbolo: document.getElementById('u-simbolo').value.trim() || null,
        csrf: CSRF
    };
    if (!id) payload.codigo = codigo;

    try {
        const res  = await fetch('/nexora/api/produto_unidade_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Unidade guardada com sucesso.');
            location.hash = 'unidades';
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
