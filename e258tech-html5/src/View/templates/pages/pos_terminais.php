<?php

    $resp      = $app->nexora->call('GET', '/api/pos/terminais');
    $terminais = $resp['body'] ?? [];

    $whResp     = $app->nexora->call('GET', '/api/stock/warehouses');
    $warehouses = $whResp['body'] ?? [];
    $whMap      = [];
    foreach ($warehouses as $w) {
        $whMap[(int) $w['id']] = $w['nome'];
    }
    $warehousesAtivos = array_filter($warehouses, static fn ($w) => (bool) $w['ativo']);

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Terminais POS';
    $activePage = 'pos_terminais';
    $breadcrumb = [['Admin', '/nexora/'], ['POS', ''], ['Terminais', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Terminais POS</h1>
</div>

<?php if ($app->request->queryString('msg') !== ''): ?>
<div class="adm-alert adm-alert--success">
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
    <?php echo htmlspecialchars($app->request->queryString('msg')) ?>
</div>
<?php endif; ?>

<div class="adm-card adm-mb-6">
    <?php if ($terminais): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Código</th>
                    <th>Nome</th>
                    <th>Armazém</th>
                    <th>Estado</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($terminais as $t): ?>
            <tr>
                <td class="adm-fw-600"><?php echo htmlspecialchars($t['codigo']) ?></td>
                <td><?php echo htmlspecialchars($t['nome']) ?></td>
                <td><?php echo $t['warehouse_id'] ? htmlspecialchars($whMap[(int) $t['warehouse_id']] ?? ('#' . $t['warehouse_id'])) : '—' ?></td>
                <td><span class="adm-badge <?php echo $t['activo'] ? 'adm-badge--green' : 'adm-badge--gray' ?>"><?php echo $t['activo'] ? 'Activo' : 'Inactivo' ?></span></td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <rect x="2" y="4" width="20" height="16" rx="2"/><line x1="2" y1="10" x2="22" y2="10"/>
        </svg>
        <p class="adm-empty-title">Nenhum terminal criado</p>
        <p class="adm-empty-sub">Cria o primeiro terminal POS abaixo.</p>
    </div>
    <?php endif; ?>
</div>

<div class="adm-card">
    <div class="adm-card-header"><h2 class="adm-card-title">Novo Terminal</h2></div>
    <div class="adm-card-body">
        <div class="adm-form-row-3">
            <div class="adm-form-group">
                <label class="adm-label" for="t-codigo">Código <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="text" id="t-codigo" maxlength="20" placeholder="ex: T1">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="t-nome">Nome <span style="color:var(--adm-red)">*</span></label>
                <input class="adm-input" type="text" id="t-nome" maxlength="100" placeholder="ex: Caixa 1">
            </div>
            <div class="adm-form-group">
                <label class="adm-label" for="t-armazem">Armazém</label>
                <select class="adm-select" id="t-armazem">
                    <option value="">— Seleccionar —</option>
                    <?php foreach ($warehousesAtivos as $w): ?>
                    <option value="<?php echo (int) $w['id'] ?>"><?php echo htmlspecialchars($w['codigo'] . ' - ' . $w['nome']) ?></option>
                    <?php endforeach; ?>
                </select>
                <p class="adm-help">Sem armazém configurado, as vendas neste terminal falham.</p>
            </div>
        </div>
        <button class="adm-btn adm-btn-primary" onclick="saveTerminal()">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Criar Terminal
        </button>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

async function saveTerminal() {
    const codigo = document.getElementById('t-codigo').value.trim();
    const nome   = document.getElementById('t-nome').value.trim();
    if (!codigo) { showToast('O código é obrigatório.', 'error'); return; }
    if (!nome)   { showToast('O nome é obrigatório.', 'error'); return; }

    const armazemId = document.getElementById('t-armazem').value;
    const payload = { codigo, nome, csrf: CSRF };
    if (armazemId) payload.warehouse_id = Number(armazemId);

    try {
        const res  = await fetch('/nexora/api/pos_terminal_save', {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            window.location.href = '/nexora/pos/terminais?msg=' + encodeURIComponent(data.msg || 'Terminal criado com sucesso.');
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
