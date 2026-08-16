<?php

$id     = $app->request->queryInt('id');
$isEdit = $id !== null && $id > 0;

$fatura   = null;
$itens    = [];
$clientes = [];
$produtos = [];

$statusBadges = [
    'rascunho'          => ['adm-badge--gray',   'Rascunho'],
    'emitida'           => ['adm-badge--blue',   'Emitida'],
    'parcialmente_paga' => ['adm-badge--yellow', 'Parcialmente Paga'],
    'paga'              => ['adm-badge--green',  'Paga'],
    'cancelada'         => ['adm-badge--red',    'Cancelada'],
    'vencida'           => ['adm-badge--indigo', 'Vencida'],
];
$tipoLabels = ['normal' => 'Fatura', 'FR' => 'Fatura-recibo', 'VD' => 'Venda a Dinheiro', 'proforma' => 'Pró-forma'];

if ($isEdit) {
    $resp = $app->nexora->call('GET', "/api/faturacao/invoices/$id");
    if ($resp['status'] !== 200) {
        header('Location: ' . $app->routes->path('faturas'));
        exit;
    }
    $fatura = $resp['body']['fatura'] ?? [];
    $itens  = $resp['body']['itens'] ?? [];

    if (($fatura['status'] ?? '') !== 'rascunho') {
        header('Location: ' . $app->routes->path('fatura_detalhe', ['id' => $id]));
        exit;
    }

    $clienteResp = $app->nexora->call('GET', '/api/clientes/' . $fatura['customer_id']);
    $clienteNome = $clienteResp['body']['nome'] ?? ('#' . $fatura['customer_id']);

    $produtosResp = $app->nexora->call('GET', '/api/produtos', null, ['limit' => 200, 'ativo' => 'true']);
    $produtos     = $produtosResp['body']['data'] ?? [];
} else {
    $clientesResp = $app->nexora->call('GET', '/api/clientes', null, ['limit' => 200]);
    $clientes     = $clientesResp['body']['data'] ?? [];
}

$statusBadge = $statusBadges[$fatura['status'] ?? 'rascunho'] ?? ['adm-badge--gray', $fatura['status'] ?? ''];

$csrf       = $app->security->csrfToken();
$pageTitle  = $isEdit ? 'Fatura ' . $fatura['numero'] : 'Nova Fatura';
$activePage = 'fatura_form';
$breadcrumb = [['Admin', '/nexora/'], ['Faturação', ''], ['Faturas', $app->routes->path('faturas')], [$pageTitle, '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header" style="align-items:flex-start">
    <div style="display:flex;align-items:center;gap:var(--adm-sp-3)">
        <h1 class="adm-page-title" style="margin:0"><?= $isEdit ? htmlspecialchars($fatura['numero']) : 'Nova Fatura' ?></h1>
        <?php if ($isEdit): ?>
        <span class="adm-badge <?= $statusBadge[0] ?>"><?= $statusBadge[1] ?></span>
        <?php endif; ?>
    </div>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('faturas')) ?>" class="adm-btn adm-btn-outline adm-btn-sm">Voltar</a>
    </div>
</div>

<div id="formMsg"></div>

<?php if (!$isEdit): ?>
<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Dados da Fatura</h2></div>
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
                <label class="adm-label" for="f-tipo">Tipo</label>
                <select class="adm-select" id="f-tipo">
                    <?php foreach ($tipoLabels as $key => $label): ?>
                    <option value="<?= $key ?>"><?= htmlspecialchars($label) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
        </div>
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="f-moeda">Moeda</label>
                <input class="adm-input" type="text" id="f-moeda" value="MZN" maxlength="3">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="f-due-date">Vencimento</label>
                <input class="adm-input" type="date" id="f-due-date">
            </div>
        </div>
        <div class="adm-form-group">
            <label class="adm-label" for="f-observacoes">Observações</label>
            <textarea class="adm-textarea" id="f-observacoes" rows="3"></textarea>
        </div>
        <button class="adm-btn adm-btn-primary" type="button" id="btnSave" onclick="saveFatura()">Criar Fatura</button>
    </div>
</div>
<?php else: ?>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Cliente</h2></div>
    <div class="adm-card-body">
        <p class="adm-fw-600"><?= htmlspecialchars($clienteNome) ?></p>
        <p class="adm-text-muted adm-text-sm">Tipo: <?= htmlspecialchars($tipoLabels[$fatura['tipo']] ?? $fatura['tipo']) ?></p>
        <?php if (!empty($fatura['observacoes'])): ?>
        <p class="adm-text-muted adm-text-sm"><?= nl2br(htmlspecialchars($fatura['observacoes'])) ?></p>
        <?php endif; ?>
    </div>
</div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Linhas</h2></div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($itens)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Descrição</th><th>Qtd.</th><th>Preço Unit.</th><th>Desc. %</th><th>IVA %</th><th style="text-align:right">Total</th></tr>
                </thead>
                <tbody>
                <?php foreach ($itens as $it): ?>
                    <tr>
                        <td><?= htmlspecialchars($it['descricao'] ?? '') ?></td>
                        <td><?= number_format((float) $it['quantidade'], 2, ',', '.') ?></td>
                        <td><?= number_format((float) $it['preco_unitario'], 2, ',', '.') ?></td>
                        <td><?= number_format((float) $it['desconto_percent'], 1, ',', '.') ?></td>
                        <td><?= number_format((float) $it['imposto_percent'], 1, ',', '.') ?></td>
                        <td style="text-align:right" class="adm-fw-600"><?= number_format((float) $it['total'], 2, ',', '.') ?></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
                <tfoot>
                    <tr><td colspan="5" style="text-align:right" class="adm-fw-600">Total</td><td style="text-align:right" class="adm-fw-600"><?= number_format((float) $fatura['total'], 2, ',', '.') ?> <?= htmlspecialchars($fatura['moeda']) ?></td></tr>
                </tfoot>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-card-body"><p class="adm-text-muted adm-text-sm" style="margin:0">Sem linhas adicionadas.</p></div>
        <?php endif; ?>
    </div>
</div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Adicionar Linha</h2></div>
    <div class="adm-card-body">
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="li-produto">Artigo</label>
                <select class="adm-select" id="li-produto">
                    <option value="">Linha livre…</option>
                    <?php foreach ($produtos as $p): ?>
                    <option value="<?= (int) $p['id'] ?>" data-preco="<?= (float) ($p['preco'] ?? 0) ?>" data-nome="<?= htmlspecialchars($p['nome'] ?? '') ?>"><?= htmlspecialchars(($p['codigo'] ?? '') . ' — ' . $p['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="li-descricao">Descrição</label>
                <input class="adm-input" type="text" id="li-descricao" maxlength="255">
            </div>
        </div>
        <div class="adm-form-row-3">
            <div class="adm-form-group">
                <label class="adm-label" for="li-quantidade">Quantidade</label>
                <input class="adm-input" type="number" id="li-quantidade" min="0.01" step="0.01" value="1">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="li-preco">Preço Unitário</label>
                <input class="adm-input" type="number" id="li-preco" min="0" step="0.01" value="0">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="li-desconto">Desconto %</label>
                <input class="adm-input" type="number" id="li-desconto" min="0" max="100" step="0.1" value="0">
            </div>
        </div>
        <div class="adm-form-group">
            <label class="adm-label" for="li-imposto">IVA %</label>
            <select class="adm-select" id="li-imposto">
                <option value="16">16%</option>
                <option value="5">5%</option>
                <option value="0">0%</option>
            </select>
        </div>
        <button class="adm-btn adm-btn-primary" type="button" onclick="addLinha()">Adicionar Linha</button>
    </div>
</div>

<div class="adm-card">
    <div class="adm-card-body" style="display:flex;gap:var(--adm-sp-3)">
        <button class="adm-btn adm-btn-outline" type="button" style="color:var(--adm-red)" onclick="setEstado('cancelar')">Cancelar Fatura</button>
        <button class="adm-btn adm-btn-primary" type="button" onclick="setEstado('emitir')">Emitir Fatura</button>
    </div>
</div>

<?php endif; ?>

<script>
const CSRF = '<?php echo $csrf ?>';
<?php if ($isEdit): ?>
const FATURA_ID = <?= (int) $id ?>;

document.getElementById('li-produto')?.addEventListener('change', function () {
    const opt = this.selectedOptions[0];
    if (opt && opt.value) {
        document.getElementById('li-preco').value = opt.dataset.preco || 0;
        document.getElementById('li-descricao').value = opt.dataset.nome || '';
    }
});

async function addLinha() {
    const payload = {
        invoice_id: FATURA_ID,
        product_id: document.getElementById('li-produto').value || null,
        descricao: document.getElementById('li-descricao').value.trim() || null,
        quantidade: Number(document.getElementById('li-quantidade').value) || 0,
        preco_unitario: Number(document.getElementById('li-preco').value) || 0,
        desconto_percent: Number(document.getElementById('li-desconto').value) || 0,
        imposto_percent: Number(document.getElementById('li-imposto').value) || 0,
        csrf: CSRF
    };
    try {
        const res  = await fetch('/nexora/api/fatura_item_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) { showToast('Linha adicionada'); setTimeout(() => location.reload(), 500); }
        else showToast(data.erro || 'Erro', 'error');
    } catch { showToast('Erro de ligação', 'error'); }
}

function setEstado(action) {
    openConfirm(
        action === 'emitir' ? 'Emitir fatura' : 'Cancelar fatura',
        action === 'emitir' ? 'Depois de emitida a fatura não pode ser editada. Pretende continuar?' : 'Pretende cancelar esta fatura?',
        async () => {
            try {
                const res  = await fetch('/nexora/api/fatura_estado', {
                    method: 'POST', headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id: FATURA_ID, action, csrf: CSRF})
                });
                const data = await res.json();
                if (data.ok) {
                    showToast('Fatura actualizada');
                    setTimeout(() => window.location.href = '<?= $app->routes->path('fatura_detalhe') ?>?id=' + FATURA_ID, 700);
                } else {
                    showToast(data.erro || 'Erro', 'error');
                }
            } catch { showToast('Erro de ligação', 'error'); }
        }
    );
}
<?php else: ?>
async function saveFatura() {
    const clienteId = document.getElementById('f-cliente').value;
    if (!clienteId) { showToast('O cliente é obrigatório.', 'error'); return; }

    const payload = {
        customer_id: Number(clienteId),
        tipo: document.getElementById('f-tipo').value,
        moeda: document.getElementById('f-moeda').value.trim() || null,
        due_date: document.getElementById('f-due-date').value || null,
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
            window.location.href = '<?= $app->routes->path('fatura_form') ?>?id=' + data.id;
        } else {
            showToast(data.erro || 'Erro ao guardar.', 'error');
            btn.disabled = false;
        }
    } catch { showToast('Erro de ligação', 'error'); btn.disabled = false; }
}
<?php endif; ?>
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
