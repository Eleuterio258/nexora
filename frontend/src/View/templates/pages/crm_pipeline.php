<?php

    $stages = [
    'novo'        => ['label' => 'Novo',        'col' => 'kanban-col--novo',        'badge' => 'gray'],
    'qualificado' => ['label' => 'Qualificado', 'col' => 'kanban-col--qualificado', 'badge' => 'blue'],
    'proposta'    => ['label' => 'Proposta',    'col' => 'kanban-col--proposta',    'badge' => 'indigo'],
    'negociacao'  => ['label' => 'Negociação',  'col' => 'kanban-col--negociacao',  'badge' => 'yellow'],
    'ganho'       => ['label' => 'Ganho',       'col' => 'kanban-col--ganho',       'badge' => 'green'],
    'perdido'     => ['label' => 'Perdido',     'col' => 'kanban-col--perdido',     'badge' => 'red'],
    ];

    $resp = $app->nexora->call('GET', '/api/crm/oportunidades', null, ['limit' => 100]);
    $all  = $resp['body']['data'] ?? [];

    $grouped = array_fill_keys(array_keys($stages), []);
    $totais  = array_fill_keys(array_keys($stages), 0.0);
    foreach ($all as $o) {
    $st = $o['estagio'] ?? 'novo';
    if (isset($grouped[$st])) {
        $grouped[$st][] = $o;
        $totais[$st]   += (float) $o['valor_estimado'];
    }
    }

    $csrf = $app->security->csrfToken();
$pageTitle  = 'Pipeline de Vendas';
    $activePage = 'crm_pipeline';
    $breadcrumb = [['Admin', '/nexora/'], ['CRM', ''], ['Pipeline de Vendas', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Pipeline de Vendas</h1>
    <div class="adm-page-header-actions">
        <a href="/nexora/crm/oportunidades" class="adm-btn adm-btn-outline">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/>
                <line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/>
            </svg>
            Vista em Lista
        </a>
        <a href="/nexora/crm/oportunidades/form" class="adm-btn adm-btn-primary">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Nova Oportunidade
        </a>
    </div>
</div>

<!-- Summary chips -->
<div style="display:flex;gap:var(--adm-sp-3);margin-bottom:var(--adm-sp-6);flex-wrap:wrap">
    <?php foreach ($stages as $key => $s): $n = count($grouped[$key]); ?>
    <div style="display:flex;align-items:center;gap:var(--adm-sp-2);background:var(--adm-white);border:1px solid var(--adm-gray-200);border-radius:99px;padding:.3rem var(--adm-sp-4);font-size:var(--adm-text-xs);font-weight:600">
        <span class="adm-badge adm-badge--<?php echo $s['badge'] ?>" style="padding:.15rem .5rem"><?php echo $n ?></span>
        <?php echo $s['label'] ?>
        <?php if ($totais[$key] > 0): ?>
        <span class="adm-text-muted" style="font-weight:400">— <?php echo number_format($totais[$key], 0, ',', '.') ?></span>
        <?php endif; ?>
    </div>
    <?php endforeach; ?>
    <div style="margin-left:auto;display:flex;align-items:center;font-size:var(--adm-text-xs);color:var(--adm-gray-400)">
        Total: <?php echo count($all) ?> oportunidade<?php echo count($all) !== 1 ? 's' : '' ?>
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
                <div class="kanban-empty-col">Sem oportunidades</div>
                <?php endif; ?>
                <?php foreach ($grouped[$key] as $o):
                        $locked = in_array($o['estagio'], ['ganho', 'perdido'], true);
                        $dias   = $app->view->daysUntil($o['data_fecho_prevista'] ?? null);
                ?>
                <div class="kanban-card<?php echo $locked ? ' kanban-card--locked' : '' ?>"
                     draggable="<?php echo $locked ? 'false' : 'true' ?>"
                     data-id="<?php echo $o['id'] ?>"
                     data-stage="<?php echo htmlspecialchars($o['estagio']) ?>"
                     onclick="goToCard(event, <?php echo $o['id'] ?>)">
                    <div class="kanban-card-name"><?php echo htmlspecialchars($o['titulo']) ?></div>
                    <div class="kanban-card-vaga">
                        <?php echo number_format((float) $o['valor_estimado'], 0, ',', '.') ?> <?php echo htmlspecialchars($o['moeda']) ?>
                        <?php if ($o['responsavel']): ?> · <?php echo htmlspecialchars($o['responsavel']) ?><?php endif; ?>
                    </div>
                    <div class="kanban-card-footer">
                        <?php if ($dias !== null && $dias >= 0 && $dias <= 7 && ! $locked): ?>
                        <span class="adm-badge adm-badge--yellow" style="font-size:.6rem;padding:.1rem .4rem">Fecha em <?php echo $dias ?>d</span>
                        <?php else: ?>
                        <span></span>
                        <?php endif; ?>
                        <span class="kanban-card-date"><?php echo $app->view->timeAgo($o['created_at']) ?></span>
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

        if (oldStage === 'ganho' || oldStage === 'perdido') {
            showToast('Esta oportunidade já está fechada e não pode mudar de estágio.', 'error');
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
                c.querySelector('.kanban-cards').innerHTML = '<div class="kanban-empty-col">Sem oportunidades</div>';
            }
        });

        try {
            const res  = await fetch('/nexora/api/oportunidade_mover', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({id, estagio: newStage, csrf: CSRF})
            });
            const data = await res.json();
            if (data.ok) {
                showToast('Movido para ' + STAGE_LABELS[newStage]);
                if (newStage === 'ganho' || newStage === 'perdido') {
                    setTimeout(() => location.reload(), 700);
                }
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
    window.location.href = '/nexora/crm/oportunidades/form?id=' + nexoraEncodeId(id);
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
