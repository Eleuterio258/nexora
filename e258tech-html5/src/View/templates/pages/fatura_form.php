<?php

    $id     = $app->request->queryInt('id', 0);
    $isEdit = $id > 0;

    $fatura      = null;
    $itens       = [];
    $clienteNome = '';
    $clientes    = [];
    $produtos    = [];

    $estadoBadges = [
        'rascunho'          => ['adm-badge--gray',   'Rascunho'],
        'emitida'           => ['adm-badge--blue',   'Emitida'],
        'parcialmente_paga' => ['adm-badge--yellow', 'Parcialmente Paga'],
        'paga'              => ['adm-badge--green',  'Paga'],
        'cancelada'         => ['adm-badge--red',    'Cancelada'],
        'vencida'           => ['adm-badge--indigo', 'Vencida'],
    ];

    if ($isEdit) {
        $resp = $app->nexora->call('GET', "/api/faturacao/invoices/$id");
        if ($resp['status'] !== 200) {
            header('Location: /nexora/faturacao/faturas');
            exit;
        }
        $fatura = $resp['body']['fatura'] ?? [];
        $itens  = $resp['body']['itens'] ?? [];

        $clienteResp = $app->nexora->call('GET', '/api/clientes/' . $fatura['customer_id']);
        $clienteNome = $clienteResp['body']['nome'] ?? ('#' . $fatura['customer_id']);

        if (($fatura['status'] ?? '') === 'rascunho') {
            $produtosResp = $app->nexora->call('GET', '/api/produtos', null, ['limit' => 200, 'ativo' => 'true']);
            $produtos     = $produtosResp['body']['data'] ?? [];
        }
    } else {
        $clientesResp = $app->nexora->call('GET', '/api/clientes', null, ['limit' => 200]);
        $clientes     = $clientesResp['body']['data'] ?? [];
    }

    $estadoBadge = $estadoBadges[$fatura['status'] ?? 'rascunho'] ?? ['adm-badge--gray', $fatura['status'] ?? ''];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = $isEdit ? 'Fatura ' . $fatura['numero'] : 'Nova Fatura';
    $activePage = 'faturas';
    $breadcrumb = [['Admin', '/nexora/'], ['Faturação', ''], ['Faturas', '/nexora/faturacao/faturas'], [$isEdit ? $fatura['numero'] : 'Nova', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header" style="align-items:flex-start">
    <div style="display:flex;align-items:center;gap:var(--adm-sp-3)">
        <h1 class="adm-page-title" style="margin:0"><?php echo $isEdit ? htmlspecialchars($fatura['numero']) : 'Nova Fatura' ?></h1>
        <?php if ($isEdit): ?>
        <span class="adm-badge <?php echo $estadoBadge[0] ?>"><?php echo $estadoBadge[1] ?></span>
        <?php if (($fatura['tipo'] ?? 'normal') === 'proforma'): ?>
        <span class="adm-badge adm-badge--indigo">Pró-forma</span>
        <?php endif; ?>
        <?php endif; ?>
    </div>
    <div class="adm-page-header-actions">
        <?php if ($isEdit): ?>
        <a href="/nexora/faturacao/faturas/proforma?id=<?php echo $id ?>" target="_blank" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg>
            Pró-forma
        </a>
        <?php endif; ?>
        <a href="/nexora/faturacao/faturas" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
            Voltar
        </a>
    </div>
</div>

<div id="formMsg"></div>

<?php if (! $isEdit): ?>
<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Nova Fatura</h2></div>
    <div class="adm-card-body">
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="f-customer_id">Cliente <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="f-customer_id">
                    <option value="">Seleciona um cliente</option>
                    <?php foreach ($clientes as $c): ?>
                    <option value="<?php echo $c['id'] ?>"><?php echo htmlspecialchars($c['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="f-tipo">Tipo</label>
                <select class="adm-select" id="f-tipo">
                    <option value="normal">Fatura</option>
                    <option value="proforma">Fatura Pró-forma</option>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="f-moeda">Moeda</label>
                <select class="adm-select" id="f-moeda">
                    <?php foreach (['MZN', 'USD', 'EUR', 'ZAR'] as $m): ?>
                    <option value="<?php echo $m ?>" <?php echo $m === 'MZN' ? 'selected' : '' ?>><?php echo $m ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
        </div>
        <p class="adm-text-muted adm-text-sm">O número será atribuído automaticamente pela série activa (Faturação → Séries Documentais).</p>
        <div class="adm-form-group">
            <label class="adm-label" for="f-due_date">Vencimento</label>
            <input class="adm-input" type="date" id="f-due_date">
        </div>
        <div class="adm-form-group">
            <label class="adm-label" for="f-observacoes">Observações</label>
            <textarea class="adm-textarea" id="f-observacoes" rows="3"></textarea>
        </div>
        <button class="adm-btn adm-btn-primary" id="btnSave" onclick="saveFatura()">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>
                <polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/>
            </svg>
            Criar Fatura
        </button>
    </div>
</div>

<?php else: ?>

<div class="adm-stats-grid" style="grid-template-columns:repeat(2,1fr)">
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--green">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo number_format((float) $fatura['total'], 2, ',', '.') ?> <?php echo htmlspecialchars($fatura['moeda']) ?></div>
            <div class="adm-stat-label">Total</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
        </div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?php echo number_format((float) $fatura['imposto_total'], 2, ',', '.') ?></div>
            <div class="adm-stat-label">Imposto Total</div>
        </div>
    </div>
</div>

<div class="adm-detail-grid">
<div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Informação</h2></div>
    <div class="adm-card-body">
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--adm-sp-5)">
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Cliente</span>
                <span class="adm-detail-pair-value"><?php echo htmlspecialchars($clienteNome) ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Data emissão</span>
                <span class="adm-detail-pair-value"><?php echo $fatura['invoice_date'] ? date('d/m/Y', strtotime($fatura['invoice_date'])) : '—' ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Vencimento</span>
                <span class="adm-detail-pair-value"><?php echo $fatura['due_date'] ? date('d/m/Y', strtotime($fatura['due_date'])) : '—' ?></span>
            </div>
            <div class="adm-detail-pair">
                <span class="adm-detail-pair-label">Moeda</span>
                <span class="adm-detail-pair-value"><?php echo htmlspecialchars($fatura['moeda']) ?></span>
            </div>
        </div>
        <?php if (! empty($fatura['observacoes'])): ?>
        <div class="adm-detail-pair" style="margin-top:var(--adm-sp-4)">
            <span class="adm-detail-pair-label">Observações</span>
            <span class="adm-detail-pair-value"><?php echo nl2br(htmlspecialchars($fatura['observacoes'])) ?></span>
        </div>
        <?php endif; ?>
    </div>
</div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Itens</h2></div>
    <?php if ($itens): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Descrição</th>
                    <th>Quantidade</th>
                    <th>Preço Unit.</th>
                    <th>Desconto %</th>
                    <th>Imposto %</th>
                    <th>Valor Imposto</th>
                    <th>Total</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($itens as $item): ?>
            <tr>
                <td><?php echo htmlspecialchars((string) ($item['descricao'] ?? '—')) ?></td>
                <td><?php echo number_format((float) $item['quantidade'], 2, ',', '.') ?></td>
                <td><?php echo number_format((float) $item['preco_unitario'], 2, ',', '.') ?></td>
                <td><?php echo number_format((float) $item['desconto_percent'], 2, ',', '.') ?>%</td>
                <td><?php echo number_format((float) $item['imposto_percent'], 2, ',', '.') ?>%</td>
                <td><?php echo number_format((float) $item['imposto_valor'], 2, ',', '.') ?></td>
                <td class="adm-fw-600"><?php echo number_format((float) $item['total'], 2, ',', '.') ?></td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-card-body">
        <p class="adm-text-muted adm-text-sm" style="margin:0">Sem itens registados.</p>
    </div>
    <?php endif; ?>
</div>

<?php if (($fatura['status'] ?? '') === 'rascunho'): ?>
<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Adicionar Item</h2></div>
    <div class="adm-card-body">
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="it-produto">Produto <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="it-produto" onchange="preencherItem()">
                    <option value="">Seleciona um produto</option>
                    <?php foreach ($produtos as $p): ?>
                    <option value="<?php echo $p['id'] ?>" data-nome="<?php echo htmlspecialchars($p['nome']) ?>" data-iva="<?php echo (float) ($p['iva_percentual'] ?? 0) ?>" data-preco="<?php echo (float) ($p['preco_venda'] ?? 0) ?>"><?php echo htmlspecialchars($p['nome']) ?> (<?php echo htmlspecialchars($p['codigo']) ?>)</option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="it-descricao">Descrição</label>
                <input class="adm-input" type="text" id="it-descricao" maxlength="255" readonly>
            </div>
        </div>
        <div class="adm-form-row-3">
            <div class="adm-form-group">
                <label class="adm-label" for="it-quantidade">Quantidade <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="number" id="it-quantidade" min="0.01" step="0.01" placeholder="1">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="it-preco">Preço Unitário <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="number" id="it-preco" min="0.01" step="0.01" placeholder="0.00" readonly>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="it-desconto">Desconto %</label>
                <input class="adm-input" type="number" id="it-desconto" min="0" max="100" step="0.01" placeholder="0" readonly>
            </div>
        </div>
        <div class="adm-form-group">
            <label class="adm-label" for="it-imposto">Imposto %</label>
            <input class="adm-input" type="number" id="it-imposto" min="0" max="100" step="0.01" placeholder="0" readonly style="max-width:200px">
        </div>
        <button class="adm-btn adm-btn-primary" onclick="addItem()">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Adicionar Item
        </button>
    </div>
</div>
<?php endif; ?>

</div> <!-- /main col -->

<aside>
    <div class="adm-card">
        <div class="adm-card-header"><h2 class="adm-card-title">Estado da Fatura</h2></div>
        <div class="adm-card-body">
            <div style="margin-bottom:var(--adm-sp-3)">
                <span class="adm-badge <?php echo $estadoBadge[0] ?>" style="font-size:var(--adm-text-sm)"><?php echo $estadoBadge[1] ?></span>
            </div>
            <div style="display:flex;flex-direction:column;gap:var(--adm-sp-2)">
                <?php if (($fatura['status'] ?? '') === 'rascunho'): ?>
                <button class="adm-btn adm-btn-outline adm-btn-sm" onclick="changeEstado('emitir')" style="justify-content:flex-start;color:var(--adm-green-dark)">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
                    Emitir Fatura
                </button>
                <button class="adm-btn adm-btn-outline adm-btn-sm" onclick="changeEstado('cancelar')" style="justify-content:flex-start;color:var(--adm-red)">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                    Cancelar Fatura
                </button>
                <?php elseif (in_array($fatura['status'], ['emitida', 'parcialmente_paga', 'vencida'], true)): ?>
                <button class="adm-btn adm-btn-outline adm-btn-sm" onclick="changeEstado('cancelar')" style="justify-content:flex-start;color:var(--adm-red)">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                    Cancelar Fatura
                </button>
                <?php else: ?>
                <p class="adm-text-muted adm-text-sm" style="margin:0">Sem ações disponíveis para este estado.</p>
                <?php endif; ?>
            </div>
        </div>
    </div>
</aside>
</div> <!-- /adm-detail-grid -->
<?php endif; ?>

<script>
const FATURA_ID = <?php echo $isEdit ? $id : 'null' ?>;
const CSRF      = '<?php echo $csrf ?>';

<?php if (! $isEdit): ?>
async function saveFatura() {
    const customerId = document.getElementById('f-customer_id').value;
    if (!customerId) { showToast('O cliente é obrigatório.', 'error'); return; }

    const payload = {
        customer_id: Number(customerId),
        tipo: document.getElementById('f-tipo').value,
        moeda: document.getElementById('f-moeda').value,
        due_date: document.getElementById('f-due_date').value || null,
        observacoes: document.getElementById('f-observacoes').value.trim() || null,
        csrf: CSRF
    };

    const btn = document.getElementById('btnSave');
    btn.disabled = true;

    try {
        const res  = await fetch('/nexora/api/fatura_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            window.location.href = '/nexora/faturacao/faturas/form?id=' + data.id;
        } else {
            document.getElementById('formMsg').innerHTML = `<div class="adm-alert adm-alert--error">${data.erro || 'Erro ao guardar.'}</div>`;
            btn.disabled = false;
        }
    } catch {
        document.getElementById('formMsg').innerHTML = '<div class="adm-alert adm-alert--error">Erro de ligação.</div>';
        btn.disabled = false;
    }
}
<?php else: ?>
// ── Itens ────────────────────────────────────────────────────
function preencherItem() {
    const sel = document.getElementById('it-produto');
    const opt = sel.options[sel.selectedIndex];
    if (!opt.value) return;
    if (!document.getElementById('it-descricao').value) {
        document.getElementById('it-descricao').value = opt.dataset.nome || '';
    }
    document.getElementById('it-imposto').value = opt.dataset.iva || 0;
    if (Number(opt.dataset.preco) > 0) {
        document.getElementById('it-preco').value = opt.dataset.preco;
    }
}

async function addItem() {
    const produtoId   = document.getElementById('it-produto').value;
    const quantidade  = document.getElementById('it-quantidade').value;
    const preco       = document.getElementById('it-preco').value;
    if (!produtoId) { showToast('O produto é obrigatório.', 'error'); return; }
    if (!quantidade || Number(quantidade) <= 0) { showToast('A quantidade deve ser superior a zero.', 'error'); return; }
    if (!preco || Number(preco) <= 0) { showToast('O preço unitário deve ser superior a zero.', 'error'); return; }

    const payload = {
        invoice_id: FATURA_ID,
        product_id: Number(produtoId),
        descricao: document.getElementById('it-descricao').value.trim() || null,
        quantidade: Number(quantidade),
        preco_unitario: Number(preco),
        desconto_percent: Number(document.getElementById('it-desconto').value || 0),
        imposto_percent: Number(document.getElementById('it-imposto').value || 0),
        csrf: CSRF
    };

    try {
        const res  = await fetch('/nexora/api/fatura_item_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast('Item adicionado com sucesso.');
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

// ── Estado ───────────────────────────────────────────────────
const ESTADO_VERBOS = { emitir: 'emitir', cancelar: 'cancelar' };

function changeEstado(action) {
    openConfirm(
        'Alterar estado',
        'Pretende ' + ESTADO_VERBOS[action] + ' esta fatura?',
        async () => {
            try {
                const res  = await fetch('/nexora/api/fatura_estado', {
                    method: 'POST', headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id: FATURA_ID, action, csrf: CSRF})
                });
                const data = await res.json();
                if (data.ok) { showToast('Estado actualizado'); setTimeout(() => location.reload(), 700); }
                else showToast(data.erro || 'Erro', 'error');
            } catch { showToast('Erro de ligação', 'error'); }
        }
    );
}
<?php endif; ?>
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
