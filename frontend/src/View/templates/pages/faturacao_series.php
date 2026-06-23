<?php

    $resp   = $app->nexora->call('GET', '/api/faturacao/series');
    $series = $resp['body'] ?? [];

    $tipoLabels = [
        'ORC' => 'Orçamento',
        'ENC' => 'Encomenda',
        'GR'  => 'Guia de Remessa',
        'FT'  => 'Fatura',
        'NC'  => 'Nota de Crédito',
        'RB'  => 'Recibo',
        'VD'  => 'Venda POS',
    ];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Séries Documentais';
    $activePage = 'faturacao_series';
    $breadcrumb = [['Admin', '/nexora/'], ['Faturação', ''], ['Séries', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Séries Documentais</h1>
</div>

<?php if ($app->request->queryString('msg') !== ''): ?>
<div class="adm-alert adm-alert--success">
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
    <?php echo htmlspecialchars($app->request->queryString('msg')) ?>
</div>
<?php endif; ?>

<div class="adm-card adm-mb-6">
    <?php if ($series): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Tipo</th>
                    <th>Prefixo</th>
                    <th>Ano</th>
                    <th>Sequência</th>
                    <th>Estado</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($series as $s): ?>
            <tr>
                <td class="adm-fw-600"><?php echo $tipoLabels[$s['tipo']] ?? htmlspecialchars($s['tipo']) ?></td>
                <td><?php echo htmlspecialchars($s['prefixo']) ?></td>
                <td><?php echo (int) $s['ano'] ?></td>
                <td><?php echo (int) $s['sequencia'] ?></td>
                <td><span class="adm-badge <?php echo $s['ativo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $s['ativo'] ? 'Ativo' : 'Inativo' ?></span></td>
                <td>
                    <div class="adm-actions">
                        <?php if ($s['ativo']): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-red)"
                                onclick="changeAtivo(<?php echo (int) $s['id'] ?>, false, '<?php echo htmlspecialchars(addslashes($s['prefixo'])) ?>')">
                            Desactivar
                        </button>
                        <?php else: ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-green-dark)"
                                onclick="changeAtivo(<?php echo (int) $s['id'] ?>, true, '<?php echo htmlspecialchars(addslashes($s['prefixo'])) ?>')">
                            Activar
                        </button>
                        <?php endif; ?>
                    </div>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/>
        </svg>
        <p class="adm-empty-title">Nenhuma série criada</p>
        <p class="adm-empty-sub">Cria a primeira série documental abaixo.</p>
    </div>
    <?php endif; ?>
</div>

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Nova Série</h2></div>
    <div class="adm-card-body">
        <div class="adm-form-row-3">
            <div class="adm-form-group">
                <label class="adm-label" for="s-tipo">Tipo <span style="color:var(--adm-red)">*</span></label>
                <select class="adm-select" id="s-tipo">
                    <?php foreach ($tipoLabels as $key => $label): ?>
                    <option value="<?php echo $key ?>"><?php echo $label ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="s-prefixo">Prefixo <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="text" id="s-prefixo" maxlength="20" placeholder="ex: FT">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="s-ano">Ano</label>
                <input class="adm-input" type="number" id="s-ano" min="2000" max="2100" value="<?php echo date('Y') ?>">
            </div>
        </div>
        <button class="adm-btn adm-btn-primary" onclick="saveSerie()">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Criar Série
        </button>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

function changeAtivo(id, ativo, prefixo) {
    openConfirm(
        'Alterar estado',
        'Pretende ' + (ativo ? 'activar' : 'desactivar') + ' a série "' + prefixo + '"?',
        async () => {
            try {
                const res  = await fetch('/nexora/api/serie_estado', {
                    method: 'POST',
                    headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id, ativo, csrf: CSRF})
                });
                const data = await res.json();
                if (data.ok) {
                    showToast('Estado actualizado');
                    setTimeout(() => location.reload(), 700);
                } else {
                    showToast(data.erro || 'Erro', 'error');
                }
            } catch { showToast('Erro de ligação', 'error'); }
        }
    );
}

async function saveSerie() {
    const prefixo = document.getElementById('s-prefixo').value.trim();
    if (!prefixo) { showToast('O prefixo é obrigatório.', 'error'); return; }

    const payload = {
        tipo: document.getElementById('s-tipo').value,
        prefixo,
        ano: Number(document.getElementById('s-ano').value),
        csrf: CSRF
    };

    try {
        const res  = await fetch('/nexora/api/serie_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            window.location.href = '/nexora/faturacao/series?msg=' + encodeURIComponent(data.msg || 'Série criada com sucesso.');
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
