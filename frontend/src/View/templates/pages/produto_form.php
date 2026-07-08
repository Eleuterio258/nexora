<?php

    $idHash = $app->request->queryString('id');
    $isEdit = $idHash !== '';

    $produto   = null;
    $precos    = [];
    $variantes = [];

    if ($isEdit) {
        $resp = $app->nexora->call('GET', "/api/produtos/$idHash");
        if ($resp['status'] !== 200) {
            header('Location: /nexora/produtos');
            exit;
        }
        $produto = $resp['body'];

        $precos    = $app->nexora->call('GET', "/api/produtos/$id/precos")['body'] ?? [];
        $variantes = $app->nexora->call('GET', "/api/produtos/$id/variantes")['body'] ?? [];
    }

    $categorias = $app->nexora->call('GET', '/api/produtos/categorias')['body'] ?? [];
    $marcas     = $app->nexora->call('GET', '/api/produtos/marcas')['body'] ?? [];
    $unidades   = $app->nexora->call('GET', '/api/produtos/unidades')['body'] ?? [];

    $unidadeNomes = array_column($unidades, 'nome', 'id');

    $tipoLabels = [
        'simples'  => 'Simples',
        'variavel' => 'Variável',
        'kit'      => 'Kit',
        'servico'  => 'Serviço',
    ];

    $tipoPrecoLabels = [
        'custo'       => 'Custo',
        'venda'       => 'Venda',
        'atacado'     => 'Atacado',
        'promocional' => 'Promocional',
    ];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = $isEdit ? 'Editar Produto' : 'Novo Produto';
    $activePage = 'produtos';
    $breadcrumb = [['Admin', '/nexora/'], ['Produtos', '/nexora/produtos'], [$pageTitle, '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header" style="align-items:flex-start">
    <div style="display:flex;align-items:center;gap:var(--adm-sp-3)">
        <h1 class="adm-page-title" style="margin:0"><?php echo $pageTitle ?></h1>
        <?php if ($isEdit): ?>
        <span class="adm-badge <?php echo $produto['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $produto['ativo'] ? 'Ativo' : 'Inativo' ?></span>
        <?php endif; ?>
    </div>
    <div class="adm-page-header-actions">
        <a href="/nexora/produtos" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
            Voltar
        </a>
    </div>
</div>

<?php if ($app->request->queryString('msg') !== ''): ?>
<div class="adm-alert adm-alert--success">
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
    <?php echo htmlspecialchars($app->request->queryString('msg')) ?>
</div>
<?php endif; ?>

<div id="formMsg"></div>

<?php if ($isEdit): ?>
<div class="adm-detail-grid">
<div>
<div class="adm-tabs" id="mainTabs">
    <button class="adm-tab active" onclick="switchTab('info',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
        Informação
    </button>
    <button class="adm-tab" onclick="switchTab('precos',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
        Preços
        <?php if (count($precos)): ?><span class="adm-tab-badge"><?php echo count($precos) ?></span><?php endif; ?>
    </button>
    <button class="adm-tab" onclick="switchTab('variantes',this)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/></svg>
        Variantes
        <?php if (count($variantes)): ?><span class="adm-tab-badge"><?php echo count($variantes) ?></span><?php endif; ?>
    </button>
</div>

<div class="adm-tab-panel active" id="tab-info">
<?php endif; ?>

<form id="produtoForm">
    <input type="hidden" name="csrf_token" value="<?php echo $csrf ?>">
    <?php if ($isEdit): ?><input type="hidden" name="id" value="<?php echo $id ?>"><?php endif; ?>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Identificação</h2></div>
        <div class="adm-card-body">
            <?php if (! $isEdit): ?>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="f-codigo" name="codigo" required maxlength="50"
                           placeholder="ex: PRD-0001">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-tipo">Tipo</label>
                    <select class="adm-select" id="f-tipo" name="tipo">
                        <?php foreach ($tipoLabels as $key => $label): ?>
                        <option value="<?php echo $key ?>" <?php echo $key === 'simples' ? 'selected' : '' ?>><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <?php endif; ?>
            <div class="adm-form-group">
                <label class="adm-label" for="f-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="text" id="f-nome" name="nome" required maxlength="150"
                       placeholder="ex: Cimento 50kg"
                       value="<?php echo $app->view->field($produto, 'nome') ?>">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="f-descricao">Descrição</label>
                <textarea class="adm-textarea" id="f-descricao" name="descricao" rows="3" maxlength="2000"
                          placeholder="Descrição do produto..."><?php echo $app->view->field($produto, 'descricao') ?></textarea>
            </div>
            <?php if ($isEdit): ?>
            <label class="adm-toggle" style="margin-top:var(--adm-sp-2)">
                <input type="checkbox" name="ativo" value="1" <?php echo $produto['ativo'] ? 'checked' : '' ?>>
                <span class="adm-toggle-track"><span class="adm-toggle-thumb"></span></span>
                <span class="adm-toggle-label">Produto ativo</span>
            </label>
            <?php endif; ?>
        </div>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Classificação</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="f-categoria">Categoria</label>
                    <select class="adm-select" id="f-categoria" name="product_category_id">
                        <option value="">Sem categoria</option>
                        <?php foreach ($categorias as $c): ?>
                        <option value="<?php echo $c['id'] ?>" <?php echo (int) ($produto['product_category_id'] ?? 0) === (int) $c['id'] ? 'selected' : '' ?>><?php echo htmlspecialchars($c['nome']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-marca">Marca</label>
                    <select class="adm-select" id="f-marca" name="product_brand_id">
                        <option value="">Sem marca</option>
                        <?php foreach ($marcas as $m): ?>
                        <option value="<?php echo $m['id'] ?>" <?php echo (int) ($produto['product_brand_id'] ?? 0) === (int) $m['id'] ? 'selected' : '' ?>><?php echo htmlspecialchars($m['nome']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div class="adm-form-row">
                <?php if (! $isEdit): ?>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-unidade">Unidade</label>
                    <select class="adm-select" id="f-unidade" name="product_unit_id">
                        <option value="">Sem unidade</option>
                        <?php foreach ($unidades as $u): ?>
                        <option value="<?php echo $u['id'] ?>"><?php echo htmlspecialchars($u['nome']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <?php endif; ?>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-iva">IVA (%)</label>
                    <input class="adm-input" type="number" id="f-iva" name="iva_percentual" min="0" max="100" step="0.01"
                           value="<?php echo $isEdit ? htmlspecialchars((string) $produto['iva_percentual']) : '17.00' ?>">
                </div>
                <?php if (! $isEdit): ?>
                <div class="adm-form-group">
                    <label class="adm-label" for="f-stock-minimo">Stock Mínimo</label>
                    <input class="adm-input" type="number" id="f-stock-minimo" name="stock_minimo" min="0" step="0.01" value="0">
                </div>
                <?php endif; ?>
            </div>
        </div>
    </div>

    <div style="display:flex;gap:var(--adm-sp-3);justify-content:flex-end;padding-bottom:var(--adm-sp-8)">
        <a href="/nexora/produtos" class="adm-btn adm-btn-outline">Cancelar</a>
        <button type="submit" class="adm-btn adm-btn-primary" id="btnSave">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
                <polyline points="17 21 17 13 7 13 7 21"/>
                <polyline points="7 3 7 8 15 8"/>
            </svg>
            <?php echo $isEdit ? 'Guardar alterações' : 'Criar Produto' ?>
        </button>
    </div>
</form>

<?php if ($isEdit): ?>
</div> <!-- /tab-info -->

<!-- ── Preços ─────────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-precos">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Preços</h2></div>
        <?php if ($precos): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Tipo</th><th>Moeda</th><th>Valor</th><th>Início</th><th>Fim</th><th>Estado</th></tr>
                </thead>
                <tbody>
                <?php foreach ($precos as $p): ?>
                <tr>
                    <td><?php echo $tipoPrecoLabels[$p['tipo_preco']] ?? htmlspecialchars((string) $p['tipo_preco']) ?></td>
                    <td><?php echo htmlspecialchars((string) $p['moeda']) ?></td>
                    <td class="adm-fw-600"><?php echo number_format((float) $p['valor'], 2, ',', '.') ?></td>
                    <td class="adm-text-muted"><?php echo ! empty($p['inicia_em']) ? date('d/m/Y', strtotime($p['inicia_em'])) : '—' ?></td>
                    <td class="adm-text-muted"><?php echo ! empty($p['fim_em']) ? date('d/m/Y', strtotime($p['fim_em'])) : '—' ?></td>
                    <td><span class="adm-badge <?php echo $p['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $p['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-card-body">
            <p class="adm-text-muted adm-text-sm" style="margin:0">Sem preços registados.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Adicionar Preço</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="pr-tipo">Tipo <span style="color:var(--adm-red)">*</span></label>
                    <select class="adm-select" id="pr-tipo">
                        <?php foreach ($tipoPrecoLabels as $key => $label): ?>
                        <option value="<?php echo $key ?>"><?php echo $label ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="pr-moeda">Moeda</label>
                    <select class="adm-select" id="pr-moeda">
                        <option value="MZN">MZN</option>
                        <option value="USD">USD</option>
                        <option value="EUR">EUR</option>
                        <option value="ZAR">ZAR</option>
                    </select>
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="pr-valor">Valor <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="number" id="pr-valor" min="0" step="0.01" placeholder="0.00">
                </div>
            </div>
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="pr-inicio">Início</label>
                    <input class="adm-input" type="date" id="pr-inicio">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="pr-fim">Fim</label>
                    <input class="adm-input" type="date" id="pr-fim">
                </div>
            </div>
            <button class="adm-btn adm-btn-primary" type="button" onclick="savePreco()">Adicionar Preço</button>
        </div>
    </div>
</div>

<!-- ── Variantes ──────────────────────────────────────────── -->
<div class="adm-tab-panel" id="tab-variantes">
    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Variantes</h2></div>
        <?php if ($variantes): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>SKU</th><th>Nome</th><th>Estado</th></tr>
                </thead>
                <tbody>
                <?php foreach ($variantes as $v): ?>
                <tr>
                    <td class="adm-fw-600"><?php echo htmlspecialchars((string) $v['sku']) ?></td>
                    <td><?php echo $app->view->field($v, 'nome', '—') ?></td>
                    <td><span class="adm-badge <?php echo $v['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $v['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-card-body">
            <p class="adm-text-muted adm-text-sm" style="margin:0">Sem variantes registadas.</p>
        </div>
        <?php endif; ?>
    </div>

    <div class="adm-card adm-mb-6">
        <div class="adm-card-header"><h2 class="adm-card-title">Adicionar Variante</h2></div>
        <div class="adm-card-body">
            <div class="adm-form-row">
                <div class="adm-form-group">
                    <label class="adm-label" for="vr-sku">SKU <span style="color:var(--adm-red)">*</span></label>
                    <input class="adm-input" type="text" id="vr-sku" maxlength="50" placeholder="ex: CIM-50KG-AZ">
                </div>
                <div class="adm-form-group">
                    <label class="adm-label" for="vr-nome">Nome</label>
                    <input class="adm-input" type="text" id="vr-nome" maxlength="150" placeholder="ex: Cimento 50kg - Azul">
                </div>
            </div>
            <button class="adm-btn adm-btn-primary" type="button" onclick="saveVariante()">Adicionar Variante</button>
        </div>
    </div>
</div>

</div> <!-- /main col -->

<aside>
    <div class="adm-card">
        <div class="adm-card-header"><h2 class="adm-card-title">Informação do Produto</h2></div>
        <div class="adm-card-body">
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Código</span>
                <span class="adm-detail-pair-value"><?php echo htmlspecialchars($produto['codigo']) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Tipo</span>
                <span class="adm-detail-pair-value"><?php echo $tipoLabels[$produto['tipo']] ?? htmlspecialchars((string) $produto['tipo']) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Unidade</span>
                <span class="adm-detail-pair-value"><?php echo isset($produto['product_unit_id']) && isset($unidadeNomes[$produto['product_unit_id']]) ? htmlspecialchars($unidadeNomes[$produto['product_unit_id']]) : '—' ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Stock Mínimo</span>
                <span class="adm-detail-pair-value"><?php echo number_format((float) ($produto['stock_minimo'] ?? 0), 2, ',', '.') ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Criado em</span>
                <span class="adm-detail-pair-value"><?php echo ! empty($produto['created_at']) ? date('d/m/Y H:i', strtotime($produto['created_at'])) : '—' ?></span>
            </div>
            <?php if (! empty($produto['updated_at'])): ?>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Atualizado em</span>
                <span class="adm-detail-pair-value"><?php echo date('d/m/Y H:i', strtotime($produto['updated_at'])) ?></span>
            </div>
            <?php endif; ?>
        </div>
    </div>
</aside>
</div> <!-- /adm-detail-grid -->
<?php endif; ?>

<script>
const PRODUTO_ID = <?php echo $isEdit ? $id : 'null' ?>;
const CSRF       = '<?php echo $csrf ?>';

<?php if ($isEdit): ?>
// ── Tabs ─────────────────────────────────────────────────────
function switchTab(name, btn) {
    document.querySelectorAll('.adm-tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.adm-tab').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
}

document.addEventListener('DOMContentLoaded', () => {
    const tabs = ['info', 'precos', 'variantes'];
    const hash = location.hash.replace('#', '');
    const idx  = tabs.indexOf(hash);
    if (idx > 0) {
        const btn = document.querySelectorAll('#mainTabs .adm-tab')[idx];
        if (btn) switchTab(hash, btn);
    }
});
<?php endif; ?>

// ── Guardar produto ──────────────────────────────────────────
document.getElementById('produtoForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    const btn = document.getElementById('btnSave');
    btn.disabled = true;
    btn.innerHTML = '<svg class="spin" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg> A guardar…';

    const msgEl = document.getElementById('formMsg');
    msgEl.innerHTML = '';

    const fd = new FormData(this);

    try {
        const res  = await fetch('/nexora/api/produto_save', { method: 'POST', body: fd });
        const data = await res.json();

        if (data.ok) {
            if (PRODUTO_ID) {
                msgEl.innerHTML = `<div class="adm-alert adm-alert--success">${data.msg || 'Produto actualizado com sucesso.'}</div>`;
                btn.disabled = false;
                btn.innerHTML = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg> Guardar alterações`;
            } else {
                window.location.href = '/nexora/produtos/form?id=' + nexoraEncodeId(data.id) + '&msg=' + encodeURIComponent(data.msg || 'Produto criado com sucesso.');
            }
        } else {
            msgEl.innerHTML = `<div class="adm-alert adm-alert--error">${data.erro || 'Erro ao guardar.'}</div>`;
            btn.disabled = false;
            btn.innerHTML = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg> <?php echo $isEdit ? 'Guardar alterações' : 'Criar Produto' ?>`;
        }
    } catch {
        msgEl.innerHTML = '<div class="adm-alert adm-alert--error">Erro de ligação.</div>';
        btn.disabled = false;
    }
});

<?php if ($isEdit): ?>
// ── Preços ───────────────────────────────────────────────────
async function savePreco() {
    const valor = document.getElementById('pr-valor').value;
    if (valor === '' || Number(valor) < 0) { showToast('O valor deve ser positivo.', 'error'); return; }

    const payload = {
        product_id: PRODUTO_ID,
        tipo_preco: document.getElementById('pr-tipo').value,
        moeda: document.getElementById('pr-moeda').value,
        valor: Number(valor),
        inicia_em: document.getElementById('pr-inicio').value || null,
        fim_em: document.getElementById('pr-fim').value || null,
        csrf: CSRF
    };

    try {
        const res  = await fetch('/nexora/api/produto_preco_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Preço guardado com sucesso.');
            location.hash = 'precos';
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

// ── Variantes ────────────────────────────────────────────────
async function saveVariante() {
    const sku = document.getElementById('vr-sku').value.trim();
    if (!sku) { showToast('O SKU da variante é obrigatório.', 'error'); return; }

    const payload = {
        product_id: PRODUTO_ID,
        sku,
        nome: document.getElementById('vr-nome').value.trim() || null,
        csrf: CSRF
    };

    try {
        const res  = await fetch('/nexora/api/produto_variante_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Variante criada com sucesso.');
            location.hash = 'variantes';
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}
<?php endif; ?>

// Spin animation
const style = document.createElement('style');
style.textContent = '.spin{animation:spin .7s linear infinite}@keyframes spin{to{transform:rotate(360deg)}}';
document.head.appendChild(style);
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>


