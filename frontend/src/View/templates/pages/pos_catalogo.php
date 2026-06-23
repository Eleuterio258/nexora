<?php

    $catResp = $app->nexora->call('GET', '/api/pos/catalogo');
    $catalogo = $catResp['body'] ?? [];

    $prodResp = $app->nexora->call('GET', '/api/produtos', null, ['limit' => 200, 'ativo' => 'true']);
    $produtos = $prodResp['body']['data'] ?? [];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Catálogo POS';
    $activePage = 'pos_catalogo';
    $breadcrumb = [['Admin', '/nexora/'], ['POS', ''], ['Catálogo', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Catálogo POS</h1>
</div>

<?php if ($app->request->queryString('msg') !== ''): ?>
<div class="adm-alert adm-alert--success">
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
    <?php echo htmlspecialchars($app->request->queryString('msg')) ?>
</div>
<?php endif; ?>

<div class="adm-card adm-mb-6">
    <?php if ($catalogo): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Código</th>
                    <th>Nome</th>
                    <th>Preço de Venda</th>
                    <th>Código de Barras</th>
                    <th>Estado</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($catalogo as $c): ?>
            <tr>
                <td class="adm-fw-600"><?php echo htmlspecialchars($c['codigo']) ?></td>
                <td><?php echo htmlspecialchars($c['nome']) ?></td>
                <td><?php echo number_format((float) $c['preco_venda'], 2, ',', '.') ?> <?php echo htmlspecialchars($c['moeda']) ?></td>
                <td><?php echo $c['codigo_barra'] ? htmlspecialchars($c['codigo_barra']) : '—' ?></td>
                <td><span class="adm-badge <?php echo $c['activo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $c['activo'] ? 'Activo' : 'Inactivo' ?></span></td>
                <td>
                    <?php if ($c['activo']): ?>
                    <div class="adm-actions">
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-red)"
                                onclick="removerItem(<?php echo (int) $c['id'] ?>, '<?php echo htmlspecialchars(addslashes($c['nome'])) ?>')">
                            Remover
                        </button>
                    </div>
                    <?php endif; ?>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><line x1="7" y1="7" x2="7" y2="7"/>
        </svg>
        <p class="adm-empty-title">Catálogo vazio</p>
        <p class="adm-empty-sub">Adiciona o primeiro produto ao catálogo POS abaixo.</p>
    </div>
    <?php endif; ?>
</div>

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Adicionar ao Catálogo</h2></div>
    <div class="adm-card-body">
        <div class="adm-form-row-3">
            <div class="adm-form-group">
                <label class="adm-label" for="c-produto">Produto <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="c-produto" onchange="preencherProduto()">
                    <option value="">— Seleccionar —</option>
                    <?php foreach ($produtos as $p): ?>
                    <option value="<?php echo (int) $p['id'] ?>" data-preco="<?php echo (float) $p['preco_venda'] ?>" data-codigo="<?php echo htmlspecialchars($p['codigo']) ?>">
                        <?php echo htmlspecialchars($p['codigo'] . ' - ' . $p['nome']) ?>
                    </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="c-preco">Preço de Venda <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="number" id="c-preco" min="0" step="0.01" value="0">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="c-codigo-barra">Código de Barras</label>
                <input class="adm-input" type="text" id="c-codigo-barra" maxlength="50" placeholder="opcional">
            </div>
        </div>
        <div class="adm-form-row-3">
            <div class="adm-form-group">
                <label class="adm-label" for="c-moeda">Moeda</label>
                <select class="adm-select" id="c-moeda">
                    <option value="MZN" selected>MZN</option>
                    <option value="USD">USD</option>
                    <option value="EUR">EUR</option>
                </select>
            </div>
        </div>
        <button class="adm-btn adm-btn-primary" onclick="addCatalogo()">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Adicionar
        </button>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

function preencherProduto() {
    const sel = document.getElementById('c-produto');
    const opt = sel.options[sel.selectedIndex];
    document.getElementById('c-preco').value = opt.dataset.preco || 0;
}

function removerItem(id, nome) {
    openConfirm(
        'Remover do catálogo',
        'Pretende remover "' + nome + '" do catálogo POS?',
        async () => {
            try {
                const res  = await fetch('/nexora/api/pos_catalogo_remove', {
                    method: 'POST',
                    headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id, csrf: CSRF})
                });
                const data = await res.json();
                if (data.ok) {
                    showToast('Item removido do catálogo');
                    setTimeout(() => location.reload(), 700);
                } else {
                    showToast(data.erro || 'Erro', 'error');
                }
            } catch { showToast('Erro de ligação', 'error'); }
        }
    );
}

async function addCatalogo() {
    const produtoId = document.getElementById('c-produto').value;
    if (!produtoId) { showToast('Seleccione um produto.', 'error'); return; }

    const payload = {
        product_id: Number(produtoId),
        preco_venda: Number(document.getElementById('c-preco').value),
        moeda: document.getElementById('c-moeda').value,
        csrf: CSRF
    };
    const codigoBarra = document.getElementById('c-codigo-barra').value.trim();
    if (codigoBarra) payload.codigo_barra = codigoBarra;

    try {
        const res  = await fetch('/nexora/api/pos_catalogo_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            window.location.href = '/nexora/pos/catalogo?msg=' + encodeURIComponent(data.msg || 'Produto adicionado ao catálogo.');
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
