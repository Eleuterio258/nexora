<?php

    $resp  = $app->nexora->call('GET', '/api/crm/leads', null, ['limit' => 100]);
    $leads = $resp['body']['data'] ?? [];

    $origemLabels = [
        'site'          => 'Site',
        'referencia'    => 'Referência',
        'redes_sociais' => 'Redes Sociais',
        'evento'        => 'Evento',
        'chamada_fria'  => 'Chamada Fria',
        'email'         => 'Email',
        'anuncio'       => 'Anúncio',
        'outro'         => 'Outro',
    ];

    $estadoBadges = [
        'novo'           => ['adm-badge--gray',   'Novo'],
        'contactado'     => ['adm-badge--blue',   'Contactado'],
        'qualificado'    => ['adm-badge--indigo', 'Qualificado'],
        'desqualificado' => ['adm-badge--red',    'Desqualificado'],
        'convertido'     => ['adm-badge--green',  'Convertido'],
    ];

    $canGerirLeads = $app->session->can('crm', 'gerir_leads');
    $pageTitle  = 'Leads';
    $activePage = 'crm_leads';
    $breadcrumb = [['Admin', '/nexora/'], ['CRM', ''], ['Leads', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Leads</h1>
    <div class="adm-page-header-actions">
        <a href="/nexora/crm/leads/pipeline" class="adm-btn adm-btn-outline">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="3" width="4" height="18" rx="1"/>
                <rect x="10" y="3" width="4" height="14" rx="1"/>
                <rect x="17" y="3" width="4" height="10" rx="1"/>
            </svg>
            Vista Kanban
        </a>
        <?php if ($canGerirLeads): ?>
        <a href="/nexora/crm/leads/form" class="adm-btn adm-btn-primary">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Novo Lead
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
            <input class="adm-input" type="search" id="leadSearch" placeholder="Pesquisar leads…" oninput="filterTable()">
        </div>
        <select class="adm-select" id="leadEstado" onchange="filterTable()" style="width:160px">
            <option value="">Todos os estados</option>
            <?php foreach ($estadoBadges as $key => [$cls, $label]): ?>
            <option value="<?php echo $key ?>"><?php echo $label ?></option>
            <?php endforeach; ?>
        </select>
        <span class="adm-filter-count" id="leadCount"><?php echo count($leads) ?> leads</span>
    </div>

    <?php if ($leads): ?>
    <div class="adm-table-wrap">
        <table class="adm-table" id="leadsTable">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Nome / Empresa</th>
                    <th>Contacto</th>
                    <th>Origem</th>
                    <th>Responsável</th>
                    <th>Estado</th>
                    <?php if ($canGerirLeads): ?><th>Ações</th><?php endif; ?>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($leads as $l):
                    $estadoBadge = $estadoBadges[$l['estado']] ?? ['adm-badge--gray', $l['estado']];
            ?>
            <tr data-estado="<?php echo $l['estado'] ?>">
                <td class="adm-text-muted"><?php echo $l['id'] ?></td>
                <td>
                    <div class="adm-fw-600"><?php echo htmlspecialchars($l['nome']) ?></div>
                    <?php if ($l['empresa']): ?>
                    <div class="adm-text-xs adm-text-muted"><?php echo htmlspecialchars($l['empresa']) ?></div>
                    <?php endif; ?>
                </td>
                <td>
                    <?php if ($l['email']): ?><div class="adm-text-sm"><?php echo htmlspecialchars($l['email']) ?></div><?php endif; ?>
                    <?php if ($l['telefone']): ?><div class="adm-text-xs adm-text-muted"><?php echo htmlspecialchars($l['telefone']) ?></div><?php endif; ?>
                    <?php if (! $l['email'] && ! $l['telefone']): ?><span class="adm-text-muted">—</span><?php endif; ?>
                </td>
                <td><?php echo htmlspecialchars($origemLabels[$l['origem']] ?? $l['origem']) ?></td>
                <td><?php echo htmlspecialchars($l['responsavel'] ?? '—') ?></td>
                <td><span class="adm-badge <?php echo $estadoBadge[0] ?>"><?php echo $estadoBadge[1] ?></span></td>
                <?php if ($canGerirLeads): ?>
                <td>
                    <div class="adm-actions">
                        <a href="/nexora/crm/leads/form?id=<?php echo $app->id->encode((int)$l['id']) ?>" class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Ver / Editar">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                            </svg>
                        </a>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Eliminar"
                                onclick="deleteLead(<?php echo $l['id'] ?>, '<?php echo htmlspecialchars(addslashes($l['nome'])) ?>')"
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
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
            <circle cx="9" cy="7" r="4"/>
            <path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>
        </svg>
        <p class="adm-empty-title">Nenhum lead criado</p>
        <p class="adm-empty-sub">Começa por criar o primeiro lead.</p>
        <?php if ($canGerirLeads): ?>
        <a href="/nexora/crm/leads/form" class="adm-btn adm-btn-primary">Criar Lead</a>
        <?php endif; ?>
    </div>
    <?php endif; ?>
</div>

<script>
function filterTable() {
    const q      = document.getElementById('leadSearch').value.toLowerCase();
    const estado = document.getElementById('leadEstado').value;
    const rows   = document.querySelectorAll('#leadsTable tbody tr');
    let vis = 0;
    rows.forEach(row => {
        const txt  = row.textContent.toLowerCase();
        const est  = row.dataset.estado;
        const show = (!q || txt.includes(q)) && (!estado || est === estado);
        row.style.display = show ? '' : 'none';
        if (show) vis++;
    });
    document.getElementById('leadCount').textContent = vis + ' lead' + (vis !== 1 ? 's' : '');
}

function deleteLead(id, nome) {
    openConfirm(
        'Eliminar lead',
        'Eliminar "' + nome + '"? Esta acção não pode ser revertida e eliminará também as atividades associadas.',
        async () => {
            try {
                const res  = await fetch('/nexora/api/lead_delete', {
                    method: 'POST',
                    headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id, csrf: '<?php echo $app->security->csrfToken() ?>'})
                });
                const data = await res.json();
                if (data.ok) {
                    showToast('Lead eliminado');
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
