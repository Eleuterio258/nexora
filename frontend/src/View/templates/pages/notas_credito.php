<?php

$id     = $app->request->queryInt('id');
$isEdit = $id !== null && $id > 0;

$statusBadges = [
    'rascunho'  => ['adm-badge--gray',  'Rascunho'],
    'emitida'   => ['adm-badge--blue',  'Emitida'],
    'paga'      => ['adm-badge--green', 'Paga'],
    'cancelada' => ['adm-badge--red',   'Cancelada'],
];

$csrf = $app->security->csrfToken();

if ($isEdit) {
    $resp = $app->nexora->call('GET', "/api/faturacao/credit-notes/$id");
    if ($resp['status'] !== 200) {
        header('Location: ' . $app->routes->path('notas_credito'));
        exit;
    }
    $nota  = $resp['body']['nota_credito'] ?? [];
    $itens = $resp['body']['itens'] ?? [];

    $clienteResp = $app->nexora->call('GET', '/api/clientes/' . $nota['customer_id']);
    $clienteNome = $clienteResp['body']['nome'] ?? ('#' . $nota['customer_id']);

    $produtos = [];
    if (($nota['status'] ?? '') === 'rascunho') {
        $produtosResp = $app->nexora->call('GET', '/api/produtos', null, ['limit' => 200, 'ativo' => 'true']);
        $produtos     = $produtosResp['body']['data'] ?? [];
    }

    $statusBadge = $statusBadges[$nota['status']] ?? ['adm-badge--gray', $nota['status']];

    $pageTitle  = 'Nota de Crédito ' . $nota['numero'];
    $breadcrumb = [['Admin', '/nexora/'], ['Faturação', ''], ['Notas de Crédito', $app->routes->path('notas_credito')], [$nota['numero'], '']];
} else {
    $resp  = $app->nexora->call('GET', '/api/faturacao/credit-notes', null, ['limit' => 100]);
    $notas = $resp['body'] ?? [];

    $clientesResp = $app->nexora->call('GET', '/api/clientes', null, ['limit' => 200]);
    $clientes     = $clientesResp['body']['data'] ?? [];
    $clientesPorId = [];
    foreach ($clientes as $c) {
        $clientesPorId[(int) $c['id']] = $c['nome'] ?? ('#' . $c['id']);
    }

    $invoiceIdPre  = $app->request->queryInt('invoice_id') ?? '';
    $customerIdPre = $app->request->queryInt('customer_id') ?? '';

    $pageTitle  = 'Notas de Crédito';
    $breadcrumb = [['Admin', '/nexora/'], ['Faturação', ''], ['Notas de Crédito', '']];
}

$activePage = 'notas_credito';

include dirname(__DIR__) . '/layouts/top.php';
?>

<?php if ($isEdit): ?>

<div class="adm-page-header" style="align-items:flex-start">
    <div style="display:flex;align-items:center;gap:var(--adm-sp-3)">
        <h1 class="adm-page-title" style="margin:0"><?= htmlspecialchars($nota['numero']) ?></h1>
        <span class="adm-badge <?= $statusBadge[0] ?>"><?= $statusBadge[1] ?></span>
    </div>
    <div class="adm-page-header-actions">
        <a href="<?= htmlspecialchars($app->routes->path('notas_credito')) ?>" class="adm-btn adm-btn-outline adm-btn-sm">Voltar</a>
    </div>
</div>

<div id="formMsg"></div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Cliente</h2></div>
    <div class="adm-card-body">
        <p class="adm-fw-600"><?= htmlspecialchars($clienteNome) ?></p>
        <p class="adm-text-muted adm-text-sm">Motivo: <?= htmlspecialchars($nota['motivo']) ?></p>
        <?php if (!empty($nota['invoice_id'])): ?>
        <p class="adm-text-muted adm-text-sm">Fatura associada: #<?= (int) $nota['invoice_id'] ?></p>
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
                    <tr><th>Descrição</th><th>Qtd.</th><th>Preço Unit.</th><th>IVA %</th><th style="text-align:right">Total</th></tr>
                </thead>
                <tbody>
                <?php foreach ($itens as $it): ?>
                    <tr>
                        <td><?= htmlspecialchars($it['descricao'] ?? '') ?></td>
                        <td><?= number_format((float) $it['quantidade'], 2, ',', '.') ?></td>
                        <td><?= number_format((float) $it['preco_unitario'], 2, ',', '.') ?></td>
                        <td><?= number_format((float) $it['imposto_percent'], 1, ',', '.') ?></td>
                        <td style="text-align:right" class="adm-fw-600"><?= number_format((float) $it['total'], 2, ',', '.') ?></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
                <tfoot>
                    <tr><td colspan="4" style="text-align:right" class="adm-fw-600">Total</td><td style="text-align:right" class="adm-fw-600"><?= number_format((float) $nota['total'], 2, ',', '.') ?> <?= htmlspecialchars($nota['moeda']) ?></td></tr>
                </tfoot>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-card-body"><p class="adm-text-muted adm-text-sm" style="margin:0">Sem linhas adicionadas.</p></div>
        <?php endif; ?>
    </div>
</div>

<?php if (($nota['status'] ?? '') === 'rascunho'): ?>
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
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="li-quantidade">Quantidade</label>
                <input class="adm-input" type="number" id="li-quantidade" min="0.01" step="0.01" value="1">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="li-preco">Preço Unitário</label>
                <input class="adm-input" type="number" id="li-preco" min="0" step="0.01" value="0">
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
        <button class="adm-btn adm-btn-outline" type="button" style="color:var(--adm-red)" onclick="setEstado('cancelar')">Cancelar</button>
        <button class="adm-btn adm-btn-primary" type="button" onclick="setEstado('emitir')">Emitir Nota de Crédito</button>
    </div>
</div>
<?php endif; ?>

<script>
const CSRF = '<?php echo $csrf ?>';
const NOTA_ID = <?= (int) $id ?>;

document.getElementById('li-produto')?.addEventListener('change', function () {
    const opt = this.selectedOptions[0];
    if (opt && opt.value) {
        document.getElementById('li-preco').value = opt.dataset.preco || 0;
        document.getElementById('li-descricao').value = opt.dataset.nome || '';
    }
});

async function addLinha() {
    const payload = {
        credit_note_id: NOTA_ID,
        product_id: document.getElementById('li-produto').value || null,
        descricao: document.getElementById('li-descricao').value.trim() || null,
        quantidade: Number(document.getElementById('li-quantidade').value) || 0,
        preco_unitario: Number(document.getElementById('li-preco').value) || 0,
        imposto_percent: Number(document.getElementById('li-imposto').value) || 0,
        csrf: CSRF
    };
    try {
        const res  = await fetch('/nexora/api/nota_credito_item_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) { showToast('Linha adicionada'); setTimeout(() => location.reload(), 500); }
        else showToast(data.erro || 'Erro', 'error');
    } catch { showToast('Erro de ligação', 'error'); }
}

function setEstado(action) {
    openConfirm(
        action === 'emitir' ? 'Emitir nota de crédito' : 'Cancelar nota de crédito',
        action === 'emitir' ? 'Pretende emitir esta nota de crédito?' : 'Pretende cancelar esta nota de crédito?',
        async () => {
            try {
                const res  = await fetch('/nexora/api/nota_credito_estado', {
                    method: 'POST', headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id: NOTA_ID, action, csrf: CSRF})
                });
                const data = await res.json();
                if (data.ok) { showToast('Nota de crédito actualizada'); setTimeout(() => location.reload(), 700); }
                else showToast(data.erro || 'Erro', 'error');
            } catch { showToast('Erro de ligação', 'error'); }
        }
    );
}
</script>

<?php else: ?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Notas de Crédito</h1>
</div>

<div id="formMsg"></div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Lista de notas de crédito</h2></div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($notas)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Número</th><th>Cliente</th><th>Estado</th><th style="text-align:right">Total</th><th></th></tr>
                </thead>
                <tbody>
                <?php foreach ($notas as $n):
                    $badge = $statusBadges[$n['status']] ?? ['adm-badge--gray', $n['status']];
                ?>
                    <tr>
                        <td class="adm-fw-600"><?= htmlspecialchars($n['numero']) ?></td>
                        <td><?= htmlspecialchars($clientesPorId[(int) $n['customer_id']] ?? ('#' . $n['customer_id'])) ?></td>
                        <td><span class="adm-badge <?= $badge[0] ?>"><?= $badge[1] ?></span></td>
                        <td style="text-align:right" class="adm-fw-600"><?= number_format((float) $n['total'], 2, ',', '.') ?> <?= htmlspecialchars($n['moeda']) ?></td>
                        <td>
                            <a href="<?= htmlspecialchars($app->routes->path('notas_credito', ['id' => $n['id']])) ?>" class="adm-btn adm-btn-ghost adm-btn-icon adm-btn-sm" title="Ver">
                                <i class="fa-solid fa-eye"></i>
                            </a>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-12)">
            <i class="fa-solid fa-file-circle-minus" style="font-size:2rem;opacity:.2"></i>
            <p class="adm-empty-title">Sem notas de crédito</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Nova Nota de Crédito</h2></div>
    <div class="adm-card-body">
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="f-cliente">Cliente <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="f-cliente">
                    <option value="">Seleccionar cliente…</option>
                    <?php foreach ($clientes as $c): ?>
                    <option value="<?= (int) $c['id'] ?>" <?= (string) $customerIdPre === (string) $c['id'] ? 'selected' : '' ?>><?= htmlspecialchars(($c['codigo'] ?? '') . ' — ' . $c['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="f-fatura-id">Fatura Associada</label>
                <input class="adm-input" type="number" id="f-fatura-id" min="1" placeholder="ID da fatura (opcional)" value="<?= htmlspecialchars((string) $invoiceIdPre) ?>">
            </div>
        </div>
        <div class="adm-form-group">
            <label class="adm-label" for="f-motivo">Motivo <span style="color:var(--adm-red)">*</span></label>
            <input class="adm-input" type="text" id="f-motivo" maxlength="255" placeholder="ex: Devolução de mercadoria">
        </div>
        <div class="adm-form-group">
            <label class="adm-label" for="f-observacoes">Observações</label>
            <textarea class="adm-textarea" id="f-observacoes" rows="3"></textarea>
        </div>
        <button class="adm-btn adm-btn-primary" type="button" onclick="saveNota()">Criar Nota de Crédito</button>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

async function saveNota() {
    const clienteId = document.getElementById('f-cliente').value;
    const motivo = document.getElementById('f-motivo').value.trim();
    if (!clienteId) { showToast('O cliente é obrigatório.', 'error'); return; }
    if (!motivo) { showToast('O motivo é obrigatório.', 'error'); return; }

    const payload = {
        customer_id: Number(clienteId),
        invoice_id: document.getElementById('f-fatura-id').value || null,
        motivo,
        observacoes: document.getElementById('f-observacoes').value.trim() || null,
        csrf: CSRF
    };

    try {
        const res  = await fetch('/nexora/api/nota_credito_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            window.location.href = '<?= $app->routes->path('notas_credito') ?>?id=' + data.id;
        } else {
            showToast(data.erro || 'Erro ao guardar.', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}
</script>

<?php endif; ?>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
