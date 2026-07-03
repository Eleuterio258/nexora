<?php

    $resp          = $app->nexora->call('GET', '/api/crm/oportunidades', null, ['limit' => 100]);
    $oportunidades = $resp['body']['data'] ?? [];

    $estagioBadges = [
    'novo'        => ['adm-badge--gray',   'Novo'],
    'qualificado' => ['adm-badge--blue',   'Qualificado'],
    'proposta'    => ['adm-badge--indigo', 'Proposta'],
    'negociacao'  => ['adm-badge--yellow', 'Negociação'],
    'ganho'       => ['adm-badge--green',  'Ganho'],
    'perdido'     => ['adm-badge--red',    'Perdido'],
    ];

    $canGerirOportunidades = $app->session->can('crm', 'gerir_oportunidades');
    $pageTitle  = 'Oportunidades';
    $activePage = 'crm_oportunidades';
    $breadcrumb = [['Admin', '/nexora/'], ['CRM', ''], ['Oportunidades', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Oportunidades</h1>
    <div class="adm-page-header-actions">
        <a href="/nexora/crm/pipeline" class="adm-btn adm-btn-outline">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="3" width="4" height="18" rx="1"/>
                <rect x="10" y="3" width="4" height="14" rx="1"/>
                <rect x="17" y="3" width="4" height="10" rx="1"/>
            </svg>
            Pipeline
        </a>
        <?php if ($canGerirOportunidades): ?>
        <a href="/nexora/crm/oportunidades/form" class="adm-btn adm-btn-primary">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Nova Oportunidade
        </a>
        <?php endif; ?>
    </div>
</div>

<?php if ($app->request->queryString('msg') !== ''): ?>
<div class="adm-alert adm-alert--success">
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
    <?php echo htmlspecialchars($app->request->queryString('msg')) ?>
</div>
<?php endif; ?>

<div class="adm-card">
    <div class="adm-filter-bar">
        <div class="adm-search-wrap">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <input class="adm-input" type="search" id="opSearch" placeholder="Pesquisar oportunidades…" oninput="filterTable()">
        </div>
        <select class="adm-select" id="opEstagio" onchange="filterTable()" style="width:160px">
            <option value="">Todos os estágios</option>
            <?php foreach ($estagioBadges as $key => [$cls, $label]): ?>
            <option value="<?php echo $key ?>"><?php echo $label ?></option>
            <?php endforeach; ?>
        </select>
        <span class="adm-filter-count" id="opCount"><?php echo count($oportunidades) ?> oportunidades</span>
    </div>

    <?php if ($oportunidades): ?>
    <div class="adm-table-wrap">
        <table class="adm-table" id="opTable">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Título</th>
                    <th>Lead / Cliente</th>
                    <th>Estágio</th>
                    <th>Valor Estimado</th>
                    <th>Prob.</th>
                    <th>Fecho Previsto</th>
                    <th>Responsável</th>
                    <?php if ($canGerirOportunidades): ?><th>Ações</th><?php endif; ?>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($oportunidades as $o):
                    $estagioBadge = $estagioBadges[$o['estagio']] ?? ['adm-badge--gray', $o['estagio']];
            ?>
            <tr data-estagio="<?php echo $o['estagio'] ?>">
                <td class="adm-text-muted"><?php echo $o['id'] ?></td>
                <td class="adm-fw-600"><?php echo htmlspecialchars($o['titulo']) ?></td>
                <td>
                    <?php if ($o['lead_id']): ?>
                    <a href="/nexora/crm/leads/form?id=<?php echo $o['lead_id'] ?>" class="adm-badge adm-badge--gray" style="text-decoration:none">Lead #<?php echo $o['lead_id'] ?></a>
                    <?php endif; ?>
                    <?php if ($o['cliente_id']): ?>
                    <span class="adm-badge adm-badge--blue">Cliente #<?php echo $o['cliente_id'] ?></span>
                    <?php endif; ?>
                    <?php if (! $o['lead_id'] && ! $o['cliente_id']): ?><span class="adm-text-muted">—</span><?php endif; ?>
                </td>
                <td><span class="adm-badge <?php echo $estagioBadge[0] ?>"><?php echo $estagioBadge[1] ?></span></td>
                <td><?php echo number_format((float) $o['valor_estimado'], 2, ',', '.') ?> <?php echo htmlspecialchars($o['moeda']) ?></td>
                <td><?php echo (int) $o['probabilidade'] ?>%</td>
                <td><?php echo $o['data_fecho_prevista'] ? date('d/m/Y', strtotime($o['data_fecho_prevista'])) : '<span class="adm-text-muted">—</span>' ?></td>
                <td><?php echo htmlspecialchars($o['responsavel'] ?? '—') ?></td>
                <?php if ($canGerirOportunidades): ?>
                <td>
                    <div class="adm-actions">
                        <a href="/nexora/crm/oportunidades/form?id=<?php echo $o['id'] ?>" class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Ver / Editar">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                            </svg>
                        </a>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Eliminar"
                                onclick="deleteOportunidade(<?php echo $o['id'] ?>, '<?php echo htmlspecialchars(addslashes($o['titulo'])) ?>')"
                                style="color:var(--adm-red)">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="3 6 5 6 21 6"/>
                                <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>
                                <path d="M10 11v6"/><path d="M14 11v6"/>
                                <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/>
                            </svg>
                        </button>
                    </div>
                </td>
                <?php else: ?>
                <td>—</td>
                <?php endif; ?>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>
        </svg>
        <p class="adm-empty-title">Nenhuma oportunidade criada</p>
        <p class="adm-empty-sub">Começa por criar a primeira oportunidade.</p>
        <?php if ($canGerirOportunidades): ?>
        <a href="/nexora/crm/oportunidades/form" class="adm-btn adm-btn-primary">Criar Oportunidade</a>
        <?php endif; ?>
    </div>
    <?php endif; ?>
</div>

<script>
function filterTable() {
    const q       = document.getElementById('opSearch').value.toLowerCase();
    const estagio = document.getElementById('opEstagio').value;
    const rows    = document.querySelectorAll('#opTable tbody tr');
    let vis = 0;
    rows.forEach(row => {
        const txt  = row.textContent.toLowerCase();
        const est  = row.dataset.estagio;
        const show = (!q || txt.includes(q)) && (!estagio || est === estagio);
        row.style.display = show ? '' : 'none';
        if (show) vis++;
    });
    document.getElementById('opCount').textContent = vis + ' oportunidade' + (vis !== 1 ? 's' : '');
}

function deleteOportunidade(id, titulo) {
    openConfirm(
        'Eliminar oportunidade',
        'Eliminar "' + titulo + '"? Esta acção não pode ser revertida e eliminará também as atividades associadas.',
        async () => {
            try {
                const res  = await fetch('/nexora/api/oportunidade_delete', {
                    method: 'POST',
                    headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id, csrf: '<?php echo $app->security->csrfToken() ?>'})
                });
                const data = await res.json();
                if (data.ok) {
                    showToast('Oportunidade eliminada');
                    setTimeout(() => location.reload(), 800);
                } else {
                    showToast(data.erro || 'Erro', 'error');
                }
            } catch {
                showToast('Erro de ligação', 'error');
            }
        }
    );
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
