<?php

    $vagaHash   = $app->request->queryString('vaga_id');
    $filtroVaga = $vagaHash ? $app->id->decode($vagaHash) : 0;

    $stages = [
    'recebida'   => ['label' => 'Recebida', 'col' => 'kanban-col--recebida'],
    'em_analise' => ['label' => 'Em Análise', 'col' => 'kanban-col--em_analise'],
    'entrevista' => ['label' => 'Entrevista', 'col' => 'kanban-col--entrevista'],
    'aprovada'   => ['label' => 'Aprovada', 'col' => 'kanban-col--aprovada'],
    'rejeitada'  => ['label' => 'Rejeitada', 'col' => 'kanban-col--rejeitada'],
    ];

    // Fetch all candidatures
    $query = ['limit' => 100];
    if ($filtroVaga) {
    $query['vaga_id'] = $filtroVaga;
    }

    $resp = $app->nexora->call('GET', '/api/recrutamento/candidaturas', null, $query);
    $all  = $resp['body']['data'] ?? [];

    // Group by stage
    $grouped = array_fill_keys(array_keys($stages), []);
    foreach ($all as $c) {
    $st = $c['estado'] ?? 'recebida';
    if (isset($grouped[$st])) {
        $grouped[$st][] = $c;
    }

    }

    // Vagas list for filter
    $vagasResp = $app->nexora->call('GET', '/api/recrutamento/vagas', null, ['limit' => 100]);
    $vagas     = $vagasResp['body']['data'] ?? [];
    usort($vagas, fn($a, $b) => strcasecmp($a['titulo'], $b['titulo']));

    $csrf = $app->security->csrfToken();
$pageTitle  = 'Pipeline';
    $activePage = 'pipeline';
    $breadcrumb = [['Admin', '/nexora/'], ['Pipeline', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Pipeline de Recrutamento</h1>
    <div class="adm-page-header-actions">
        <select class="adm-select" onchange="location.href='/nexora/recrutamento/pipeline'+(this.value?'?vaga_id='+this.value:'')" style="min-width:200px">
            <option value="">Todas as vagas</option>
            <?php foreach ($vagas as $v): ?>
            <option value="<?php echo $app->id->encode((int)$v['id']) ?>" <?php echo $filtroVaga == (int)$v['id'] ? 'selected' : '' ?>>
                <?php echo htmlspecialchars($v['titulo']) ?>
            </option>
            <?php endforeach; ?>
        </select>
        <a href="/nexora/recrutamento/candidaturas" class="adm-btn adm-btn-outline">
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
        <span class="adm-badge adm-badge--<?php echo match ($key) {
                                                  'recebida' => 'yellow', 'em_analise' => 'blue', 'entrevista' => 'indigo', 'aprovada' => 'green',     default => 'red'
                                              } ?>" style="padding:.15rem .5rem"><?php echo $n ?></span>
        <?php echo $s['label'] ?>
    </div>
    <?php endforeach; ?>
    <div style="margin-left:auto;display:flex;align-items:center;font-size:var(--adm-text-xs);color:var(--adm-gray-400)">
        Total: <?php echo count($all) ?> candidato<?php echo count($all) !== 1 ? 's' : '' ?>
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
                <div class="kanban-empty-col">Sem candidatos</div>
                <?php endif; ?>
                <?php foreach ($grouped[$key] as $c): $locked = in_array($c['estado'], ['aprovada', 'rejeitada'], true); ?>
                <div class="kanban-card<?php echo $locked ? ' kanban-card--locked' : '' ?>"
                     draggable="<?php echo $locked ? 'false' : 'true' ?>"
                     data-id="<?php echo $c['id'] ?>"
                     data-stage="<?php echo htmlspecialchars($c['estado']) ?>"
                     onclick="goToCard(event, <?php echo $c['id'] ?>)">
                    <div class="kanban-card-name"><?php echo htmlspecialchars($c['nome']) ?></div>
                    <div class="kanban-card-vaga"><?php echo htmlspecialchars($c['vaga_titulo'] ?? '—') ?></div>
                    <div class="kanban-card-footer">
                        <span class="kanban-card-date"><?php echo $app->view->timeAgo($c['created_at']) ?></span>
                        <div class="kanban-card-stars">
                            <?php for ($i = 1; $i <= 5; $i++): ?>
                            <span class="s <?php echo $i <= (int) ($c['score'] ?? 0) ? 'on' : '' ?>">★</span>
                            <?php endfor; ?>
                        </div>
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
                c.querySelector('.kanban-cards').innerHTML = '<div class="kanban-empty-col">Sem candidatos</div>';
            }
        });

        try {
            const res  = await fetch('/nexora/api/candidatura_mover', {
                method: 'POST',
                headers: {'Content-Type':'application/json'},
                body: JSON.stringify({id, estado: newStage, csrf: CSRF})
            });
            const data = await res.json();
            if (data.ok) {
                showToast('Movido para ' + '<?php echo json_encode(array_combine(array_keys($stages), array_column($stages, 'label'))) ?>'.replace(/"/g,'').split(',').find(x=>x.startsWith(newStage))?.split(':')[1] || newStage);
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
    window.location.href = '/nexora/recrutamento/candidaturas/ver?id=' + nexoraEncodeId(id);
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
