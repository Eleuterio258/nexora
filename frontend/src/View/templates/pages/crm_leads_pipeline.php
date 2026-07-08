<?php

    $stages = [
    'novo'           => ['label' => 'Novo',           'col' => 'kanban-col--novo',           'badge' => 'gray'],
    'contactado'     => ['label' => 'Contactado',     'col' => 'kanban-col--contactado',     'badge' => 'blue'],
    'qualificado'    => ['label' => 'Qualificado',    'col' => 'kanban-col--qualificado',    'badge' => 'indigo'],
    'desqualificado' => ['label' => 'Desqualificado', 'col' => 'kanban-col--desqualificado', 'badge' => 'red'],
    'convertido'     => ['label' => 'Convertido',     'col' => 'kanban-col--convertido',     'badge' => 'green'],
    ];

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

    $resp = $app->nexora->call('GET', '/api/crm/leads', null, ['limit' => 100]);
    $all  = $resp['body']['data'] ?? [];

    $grouped = array_fill_keys(array_keys($stages), []);
    foreach ($all as $l) {
    $st = $l['estado'] ?? 'novo';
    if (isset($grouped[$st])) {
        $grouped[$st][] = $l;
    }
    }

    $csrf = $app->security->csrfToken();
$pageTitle  = 'Pipeline de Leads';
    $activePage = 'crm_leads_pipeline';
    $breadcrumb = [['Admin', '/nexora/'], ['CRM', ''], ['Pipeline de Leads', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Pipeline de Leads</h1>
    <div class="adm-page-header-actions">
        <a href="/nexora/crm/leads" class="adm-btn adm-btn-outline">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/>
                <line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/>
            </svg>
            Vista em Lista
        </a>
    </div>
</div>

<!-- Summary chips -->
<div style="display:flex;gap:var(--adm-sp-3);margin-bottom:var(--adm-sp-6);flex-wrap:wrap">
    <?php foreach ($stages as $key => $s): $n = count($grouped[$key]); ?>
    <div style="display:flex;align-items:center;gap:var(--adm-sp-2);background:var(--adm-white);border:1px solid var(--adm-gray-200);border-radius:99px;padding:.3rem var(--adm-sp-4);font-size:var(--adm-text-xs);font-weight:600">
        <span class="adm-badge adm-badge--<?php echo $s['badge'] ?>" style="padding:.15rem .5rem"><?php echo $n ?></span>
        <?php echo $s['label'] ?>
    </div>
    <?php endforeach; ?>
    <div style="margin-left:auto;display:flex;align-items:center;font-size:var(--adm-text-xs);color:var(--adm-gray-400)">
        Total: <?php echo count($all) ?> lead<?php echo count($all) !== 1 ? 's' : '' ?>
    </div>
</div>

<div class="kanban-wrap">
    <div class="kanban-board" id="kanbanBoard">
        <?php foreach ($stages as $key => $s): ?>
        <div class="kanban-col <?php echo $s['col'] ?>" data-stage="<?php echo $key ?>">
            <div class="kanban-col-header">
                <span class="kanban-col-title"><?php echo $s['label'] ?></span>
                <span class="kanban-col-count"><?php echo count($grouped[$key]) ?></span>
            </div>
            <div class="kanban-cards" id="col-<?php echo $key ?>">
                <?php if (empty($grouped[$key])): ?>
                <div class="kanban-empty-col">Sem leads</div>
                <?php endif; ?>
                <?php foreach ($grouped[$key] as $l): $locked = in_array($l['estado'], ['convertido', 'desqualificado'], true); ?>
                <div class="kanban-card<?php echo $locked ? ' kanban-card--locked' : '' ?>"
                     draggable="<?php echo $locked ? 'false' : 'true' ?>"
                     data-id="<?php echo $l['id'] ?>"
                     data-stage="<?php echo htmlspecialchars($l['estado']) ?>"
                     onclick="goToCard(event, <?php echo $l['id'] ?>)">
                    <div class="kanban-card-name"><?php echo htmlspecialchars($l['nome']) ?></div>
                    <div class="kanban-card-vaga"><?php echo htmlspecialchars($l['empresa'] ?? '—') ?></div>
                    <div class="kanban-card-footer">
                        <span class="adm-badge adm-badge--gray" style="font-size:.6rem;padding:.1rem .4rem"><?php echo $origemLabels[$l['origem']] ?? $l['origem'] ?></span>
                        <span class="kanban-card-date"><?php echo $app->view->timeAgo($l['created_at']) ?></span>
                    </div>
                </div>
                <?php endforeach; ?>
            </div>
        </div>
        <?php endforeach; ?>
    </div>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';
const STAGE_LABELS = <?php echo json_encode(array_combine(array_keys($stages), array_column($stages, 'label')), JSON_UNESCAPED_UNICODE) ?>;
let dragging = null;

document.querySelectorAll('.kanban-card').forEach(card => {
    card.addEventListener('dragstart', e => {
        dragging = card;
        card.classList.add('dragging');
        e.dataTransfer.effectAllowed = 'move';
    });
    card.addEventListener('dragend', () => {
        card.classList.remove('dragging');
        dragging = null;
    });
});

document.querySelectorAll('.kanban-col').forEach(col => {
    col.addEventListener('dragover', e => {
        e.preventDefault();
        e.dataTransfer.dropEffect = 'move';
        col.classList.add('dragover');
    });
    col.addEventListener('dragleave', e => {
        if (!col.contains(e.relatedTarget)) col.classList.remove('dragover');
    });
    col.addEventListener('drop', async e => {
        e.preventDefault();
        col.classList.remove('dragover');
        if (!dragging) return;

        const newStage = col.dataset.stage;
        const oldStage = dragging.dataset.stage;
        if (newStage === oldStage) return;

        if (newStage === 'convertido') {
            showToast('Utiliza "Converter Lead" no detalhe do lead.', 'error');
            return;
        }

        const id = dragging.dataset.id;

        // Optimistic UI — move the card
        const cards = col.querySelector('.kanban-cards');
        const emptyMsg = cards.querySelector('.kanban-empty-col');
        if (emptyMsg) emptyMsg.remove();
        cards.appendChild(dragging);
        dragging.dataset.stage = newStage;

        // Update column counters
        document.querySelectorAll('.kanban-col').forEach(c => {
            const cnt = c.querySelectorAll('.kanban-card').length;
            c.querySelector('.kanban-col-count').textContent = cnt;
            if (cnt === 0 && !c.querySelector('.kanban-empty-col')) {
                c.querySelector('.kanban-cards').innerHTML = '<div class="kanban-empty-col">Sem leads</div>';
            }
        });

        try {
            const res  = await fetch('/nexora/api/lead_mover', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({id, estado: newStage, csrf: CSRF})
            });
            const data = await res.json();
            if (data.ok) {
                showToast('Movido para ' + STAGE_LABELS[newStage]);
            } else {
                showToast(data.erro || 'Erro', 'error');
            }
        } catch {
            showToast('Erro de ligação', 'error');
        }
    });
});

function goToCard(e, id) {
    if (e.defaultPrevented) return;
    window.location.href = '/nexora/crm/leads/form?id=' + nexoraEncodeId(id);
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
