<?php

$resp   = $app->nexora->call('GET', '/api/faturacao/series');
$series = $resp['body'] ?? [];

$tipoLabels = [
    'ORC' => 'Orçamentos',
    'ENC' => 'Encomendas',
    'FT'  => 'Faturas',
    'FR'  => 'Fatura-recibo',
    'VD'  => 'Venda a Dinheiro',
    'NC'  => 'Notas de Crédito',
    'RB'  => 'Recibos',
];

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Séries de Faturação';
$activePage = 'faturacao_series';
$breadcrumb = [['Admin', '/nexora/'], ['Faturação', ''], ['Séries', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Séries de Faturação</h1>
</div>

<div id="formMsg"></div>

<div class="adm-card adm-mb-6">
    <div class="adm-card-header"><h2 class="adm-card-title">Séries configuradas</h2></div>
    <div class="adm-card-body" style="padding:0">
        <?php if (!empty($series)): ?>
        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead>
                    <tr><th>Tipo</th><th>Prefixo</th><th>Ano</th><th>Sequência actual</th><th>Estado</th><th></th></tr>
                </thead>
                <tbody>
                <?php foreach ($series as $s): ?>
                    <tr>
                        <td class="adm-fw-600"><?= htmlspecialchars($tipoLabels[$s['tipo']] ?? $s['tipo']) ?></td>
                        <td><?= htmlspecialchars($s['prefixo']) ?></td>
                        <td><?= (int) $s['ano'] ?></td>
                        <td class="adm-text-muted"><?= (int) $s['sequencia'] ?></td>
                        <td>
                            <span class="adm-badge <?= $s['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>">
                                <?= $s['ativo'] ? 'Activa' : 'Inactiva' ?>
                            </span>
                        </td>
                        <td>
                            <button class="adm-btn adm-btn-outline adm-btn-sm" onclick="toggleSerie(<?= (int) $s['id'] ?>, <?= $s['ativo'] ? 'false' : 'true' ?>)">
                                <?= $s['ativo'] ? 'Desactivar' : 'Activar' ?>
                            </button>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php else: ?>
        <div class="adm-empty" style="padding:var(--adm-sp-12)">
            <i class="fa-solid fa-list-ol" style="font-size:2rem;opacity:.2"></i>
            <p class="adm-empty-title">Sem séries configuradas</p>
            <p class="adm-empty-sub">Crie uma série para cada tipo de documento antes de emitir orçamentos ou faturas.</p>
        </div>
        <?php endif; ?>
    </div>
</div>

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Nova Série</h2></div>
    <div class="adm-card-body">
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label" for="f-tipo">Tipo <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="f-tipo">
                    <?php foreach ($tipoLabels as $key => $label): ?>
                    <option value="<?= $key ?>"><?= htmlspecialchars($label) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="f-prefixo">Prefixo <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="text" id="f-prefixo" maxlength="10" placeholder="ex: FT">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="f-ano">Ano</label>
                <input class="adm-input" type="number" id="f-ano" min="2000" max="2100" placeholder="<?= date('Y') ?>">
            </div>
        </div>
        <button class="adm-btn adm-btn-primary" type="button" id="btnSave" onclick="saveSerie()">Criar Série</button>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

async function saveSerie() {
    const prefixo = document.getElementById('f-prefixo').value.trim();
    if (!prefixo) { showToast('O prefixo é obrigatório.', 'error'); return; }

    const payload = {
        tipo: document.getElementById('f-tipo').value,
        prefixo,
        ano: document.getElementById('f-ano').value || null,
        csrf: CSRF
    };

    try {
        const res  = await fetch('/nexora/api/serie_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Série criada com sucesso.');
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

function toggleSerie(id, ativo) {
    openConfirm(
        ativo ? 'Activar série' : 'Desactivar série',
        ativo ? 'Pretende activar esta série?' : 'Pretende desactivar esta série?',
        async () => {
            try {
                const res  = await fetch('/nexora/api/serie_estado', {
                    method: 'POST', headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id, ativo, csrf: CSRF})
                });
                const data = await res.json();
                if (data.ok) { showToast('Estado actualizado'); setTimeout(() => location.reload(), 700); }
                else showToast(data.erro || 'Erro', 'error');
            } catch { showToast('Erro de ligação', 'error'); }
        }
    );
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
