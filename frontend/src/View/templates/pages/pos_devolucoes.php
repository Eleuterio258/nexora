<?php

// ── Devoluções existentes ─────────────────────────────────────────────────
$devResp    = $app->nexora->call('GET', '/api/pos/sales', null, ['estado' => 'cancelada']);
$devolucoes = ($devResp['status'] === 200 && is_array($devResp['body']) && array_is_list($devResp['body']))
    ? $devResp['body'] : [];

// Vendas disponíveis para processar devolução
$vendasResp = $app->nexora->call('GET', '/api/pos/sales', null, ['estado' => 'concluida']);
$vendas     = ($vendasResp['status'] === 200 && is_array($vendasResp['body']) && array_is_list($vendasResp['body']))
    ? $vendasResp['body'] : [];

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Devoluções e Reembolsos';
$activePage = 'pos_devolucoes';
$breadcrumb = [['Admin', '/nexora/'], ['POS', '/nexora/pos'], ['Devoluções', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Devoluções e Reembolsos</h1>
    <div class="adm-page-header-actions">
        <button class="adm-btn adm-btn-primary" onclick="abrirFormDevolucao()">
            <i class="fa-solid fa-plus"></i> Nova Devolução
        </button>
    </div>
</div>

<!-- Devoluções registadas -->
<div class="adm-card adm-mb-6">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Devoluções</h2>
        <div class="adm-card-actions adm-text-sm adm-text-muted">
            <?= count($devolucoes) ?> registo<?= count($devolucoes) !== 1 ? 's' : '' ?>
        </div>
    </div>
    <?php if (empty($devolucoes)): ?>
    <div class="adm-empty">
        <i class="fa-solid fa-rotate-left" style="font-size:2rem;opacity:.3"></i>
        <p class="adm-empty-title">Sem devoluções registadas</p>
        <p class="adm-text-sm adm-text-muted">As vendas canceladas aparecem aqui.</p>
    </div>
    <?php else: ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>ID Venda</th>
                    <th>Ref. Original</th>
                    <th>Data</th>
                    <th>Método Pagamento</th>
                    <th>Valor Reembolso</th>
                    <th>Estado</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach (array_reverse($devolucoes) as $d):
                $estado = $d['estado'] ?? 'cancelada';
                $badge  = match($estado) {
                    'cancelada'  => ['adm-badge--red',    'Cancelada'],
                    'reembolsada'=> ['adm-badge--green',  'Reembolsada'],
                    'pendente'   => ['adm-badge--yellow', 'Pendente'],
                    default      => ['adm-badge--gray',   ucfirst($estado)],
                };
            ?>
            <tr>
                <td class="adm-fw-600"><?= (int)$d['id'] ?></td>
                <td class="adm-text-xs adm-fw-600 adm-text-muted"><?= htmlspecialchars($d['referencia'] ?? '—') ?></td>
                <td class="adm-text-muted" style="white-space:nowrap">
                    <?= !empty($d['criada_em']) ? date('d/m/Y H:i', strtotime($d['criada_em'])) : '—' ?>
                </td>
                <td><?= htmlspecialchars($d['metodo_pagamento'] ?? '—') ?></td>
                <td class="adm-fw-600" style="color:var(--adm-red)">
                    -<?= number_format((float)($d['total'] ?? 0), 2, ',', '.') ?> MT
                </td>
                <td><span class="adm-badge <?= $badge[0] ?>"><?= $badge[1] ?></span></td>
                <td>
                    <div class="adm-actions">
                        <a href="<?= htmlspecialchars($app->routes->path('pos_venda_ver', ['id' => $d['id']])) ?>"
                           class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Ver detalhes">
                            <i class="fa-solid fa-eye"></i>
                        </a>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Imprimir"
                                onclick="window.print()">
                            <i class="fa-solid fa-print"></i>
                        </button>
                    </div>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php endif; ?>
</div>

<!-- Processar nova devolução -->
<div class="adm-card" id="formDevolucao" style="display:none">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Processar Nova Devolução</h2>
    </div>
    <div class="adm-card-body">
        <div id="devErro" class="adm-alert adm-alert--error" style="display:none"></div>

        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label">Venda Original <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="devVendaId" onchange="preencherVenda(this.value)">
                    <option value="">Seleccionar venda...</option>
                    <?php foreach (array_reverse($vendas) as $v): ?>
                    <option value="<?= (int)$v['id'] ?>"
                            data-total="<?= (float)($v['total'] ?? 0) ?>"
                            data-ref="<?= htmlspecialchars($v['referencia'] ?? '') ?>"
                            data-metodo="<?= htmlspecialchars($v['metodo_pagamento'] ?? '') ?>">
                        #<?= (int)$v['id'] ?> — <?= htmlspecialchars($v['referencia'] ?? '') ?>
                        — <?= number_format((float)($v['total'] ?? 0), 2, ',', '.') ?> MT
                        (<?= !empty($v['criada_em']) ? date('d/m/Y', strtotime($v['criada_em'])) : '' ?>)
                    </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label">Motivo da Devolução <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="devMotivo">
                    <option value="">Seleccionar motivo...</option>
                    <option value="Defeituoso">Produto Defeituoso</option>
                    <option value="Sem_lacre">Sem lacre / Violado</option>
                    <option value="Mudanca_de_ideia">Mudança de ideia</option>
                    <option value="Outro">Outro</option>
                </select>
            </div>
        </div>

        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label">Valor de Reembolso (MT)</label>
                <div style="position:relative">
                    <span style="position:absolute;left:.75rem;top:50%;transform:translateY(-50%);color:var(--adm-gray-500)">MT</span>
                    <input type="number" class="adm-input" id="devValor" min="0" step="0.01"
                           placeholder="0,00" style="padding-left:2.5rem">
                </div>
                <p class="adm-input-hint" id="devValorHint"></p>
            </div>
            <div class="adm-form-group">
                <label class="adm-label">Supervisor (opcional)</label>
                <input type="text" class="adm-input" id="devSupervisor" placeholder="Nome do supervisor">
            </div>
        </div>

        <div class="adm-form-group">
            <label class="adm-label">Notas adicionais</label>
            <textarea class="adm-textarea" id="devNotas" rows="2" placeholder="Informações adicionais..."></textarea>
        </div>

        <div style="display:flex;gap:var(--adm-sp-3);margin-top:var(--adm-sp-4)">
            <button class="adm-btn adm-btn-outline" onclick="fecharFormDevolucao()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" id="btnProcessar" onclick="processarDevolucao()">
                <i class="fa-solid fa-rotate-left"></i> Processar Devolução
            </button>
        </div>
    </div>
</div>

<script>
const CSRF = <?= json_encode($csrf) ?>;

function abrirFormDevolucao() {
    document.getElementById('formDevolucao').style.display = '';
    document.getElementById('formDevolucao').scrollIntoView({ behavior: 'smooth' });
}
function fecharFormDevolucao() {
    document.getElementById('formDevolucao').style.display = 'none';
    document.getElementById('devErro').style.display = 'none';
}

function preencherVenda(id) {
    const opt = document.querySelector(`#devVendaId option[value="${id}"]`);
    const hint = document.getElementById('devValorHint');
    if (opt && opt.dataset.total) {
        document.getElementById('devValor').value = parseFloat(opt.dataset.total).toFixed(2);
        hint.textContent = `Máximo: ${parseFloat(opt.dataset.total).toFixed(2)} MT — Método: ${opt.dataset.metodo}`;
    } else {
        hint.textContent = '';
    }
}

async function processarDevolucao() {
    const vendaId  = document.getElementById('devVendaId').value;
    const motivo   = document.getElementById('devMotivo').value;
    const valor    = document.getElementById('devValor').value;
    const erro     = document.getElementById('devErro');

    if (!vendaId || !motivo) {
        erro.textContent = 'Seleccione a venda e o motivo.';
        erro.style.display = 'flex'; return;
    }

    const btn = document.getElementById('btnProcessar');
    btn.disabled = true;

    const resp = await fetch('/nexora/api/pos_venda_cancelar', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: parseInt(vendaId), csrf_token: CSRF })
    });
    const data = await resp.json();
    btn.disabled = false;

    if (data.ok) {
        showToast('Devolução processada com sucesso');
        setTimeout(() => location.reload(), 1000);
    } else {
        erro.textContent = data.error || data.erro || 'Erro ao processar devolução.';
        erro.style.display = 'flex';
    }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
