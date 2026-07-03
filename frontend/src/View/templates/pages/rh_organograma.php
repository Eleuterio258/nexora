<?php

    $unidades = $app->nexora->call('GET', '/api/rh/unidades')['body'] ?? [];

    $tipoConfig = [
        'direccao'    => ['cor' => '#1e40af', 'bg' => '#dbeafe', 'label' => 'Direção'],
        'departamento'=> ['cor' => '#065f46', 'bg' => '#d1fae5', 'label' => 'Departamento'],
        'equipa'      => ['cor' => '#92400e', 'bg' => '#fef3c7', 'label' => 'Equipa'],
        'divisao'     => ['cor' => '#6b21a8', 'bg' => '#f3e8ff', 'label' => 'Divisão'],
        'seccao'      => ['cor' => '#9f1239', 'bg' => '#ffe4e6', 'label' => 'Secção'],
        'gabinete'    => ['cor' => '#0f766e', 'bg' => '#ccfbf1', 'label' => 'Gabinete'],
        'projeto'     => ['cor' => '#9a3412', 'bg' => '#ffedd5', 'label' => 'Projeto'],
        'outro'       => ['cor' => '#374151', 'bg' => '#f3f4f6', 'label' => 'Outro'],
    ];

    $byParent = [];
    $byId     = [];
    foreach ($unidades as $u) {
        $byParent[$u['parent_id'] ?? 0][] = $u;
        $byId[$u['id']] = $u;
    }

    function renderNode(array $u, array $byParent, array $tipoConfig): void
    {
        $children  = $byParent[$u['id']] ?? [];
        $cfg       = $tipoConfig[$u['tipo']] ?? $tipoConfig['outro'];
        $cor       = $cfg['cor'];
        $bg        = $cfg['bg'];
        $label     = $cfg['label'];
        $resp      = $u['responsavel_nome'] ?? null;
        $numFunc   = (int) ($u['num_funcionarios'] ?? 0);
        $hasChild  = count($children) > 0;
        ?>
        <div class="org-node-wrap <?php echo $hasChild ? 'has-children' : '' ?>">
            <div class="org-card" style="border-top:3px solid <?php echo $cor ?>; background: <?php echo $bg ?>1a">
                <div class="org-card-type" style="color:<?php echo $cor ?>;background:<?php echo $bg ?>"><?php echo $label ?></div>
                <div class="org-card-title"><?php echo htmlspecialchars($u['nome']) ?></div>
                <?php if ($resp): ?>
                <div class="org-card-resp">
                    <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                    <?php echo htmlspecialchars($resp) ?>
                </div>
                <?php endif; ?>
                <div class="org-card-stats">
                    <span class="org-stat" style="color:<?php echo $cor ?>">
                        <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
                        <?php echo $numFunc ?> func.
                    </span>
                    <?php if ($hasChild): ?>
                    <span class="org-stat" style="color:var(--adm-gray-400)">
                        <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>
                        <?php echo count($children) ?> sub-unit.
                    </span>
                    <?php endif; ?>
                </div>
            </div>
            <?php if ($hasChild): ?>
            <div class="org-connector-down"></div>
            <div class="org-children">
                <div class="org-connector-line"></div>
                <?php foreach ($children as $child): ?>
                <div class="org-child-wrap">
                    <div class="org-connector-up"></div>
                    <?php renderNode($child, $byParent, $tipoConfig); ?>
                </div>
                <?php endforeach; ?>
            </div>
            <?php endif; ?>
        </div>
        <?php
    }

    $pageTitle  = 'Organograma';
    $activePage = 'rh_organograma';
    $breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Organograma', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<style>
/* ── Organograma ─────────────────────────────────────────────────────────── */
.org-wrap {
    overflow-x: auto;
    overflow-y: auto;
    padding: var(--adm-sp-8);
    min-height: 400px;
    cursor: grab;
    user-select: none;
}
.org-wrap:active { cursor: grabbing; }

.org-root {
    display: flex;
    flex-direction: column;
    align-items: center;
    min-width: max-content;
}

/* ── Nó ──────────────────────────────────────────────────────────────────── */
.org-node-wrap {
    display: flex;
    flex-direction: column;
    align-items: center;
    position: relative;
}

.org-card {
    width: 200px;
    border-radius: var(--adm-radius-lg);
    border: 1px solid rgba(0,0,0,.08);
    box-shadow: 0 2px 8px rgba(0,0,0,.08), 0 1px 2px rgba(0,0,0,.06);
    padding: var(--adm-sp-4);
    text-align: center;
    transition: box-shadow .15s, transform .15s;
    background: #fff;
    position: relative;
    z-index: 1;
}
.org-card:hover {
    box-shadow: 0 8px 24px rgba(0,0,0,.14);
    transform: translateY(-2px);
}

.org-card-type {
    display: inline-block;
    font-size: .65rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: .06em;
    padding: .15rem .55rem;
    border-radius: 999px;
    margin-bottom: var(--adm-sp-2);
}
.org-card-title {
    font-weight: 700;
    font-size: .85rem;
    color: var(--adm-gray-900);
    line-height: 1.3;
    margin-bottom: var(--adm-sp-2);
}
.org-card-resp {
    font-size: .72rem;
    color: var(--adm-gray-500);
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 3px;
    margin-bottom: var(--adm-sp-2);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}
.org-card-stats {
    display: flex;
    justify-content: center;
    gap: var(--adm-sp-3);
    flex-wrap: wrap;
}
.org-stat {
    display: flex;
    align-items: center;
    gap: 3px;
    font-size: .7rem;
    font-weight: 600;
}

/* ── Conectores ──────────────────────────────────────────────────────────── */
.org-connector-down {
    width: 2px;
    height: 28px;
    background: var(--adm-gray-300);
    margin: 0 auto;
}
.org-children {
    display: flex;
    flex-direction: row;
    gap: 0;
    position: relative;
    align-items: flex-start;
}
.org-connector-line {
    position: absolute;
    top: 0;
    left: 50%;
    height: 2px;
    background: var(--adm-gray-300);
    /* largura definida por JS */
}
.org-child-wrap {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 0 var(--adm-sp-4);
    position: relative;
}
.org-connector-up {
    width: 2px;
    height: 28px;
    background: var(--adm-gray-300);
    margin: 0 auto;
}

/* Linha horizontal nos filhos */
.org-children::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 2px;
    background: var(--adm-gray-300);
}
/* Remove a linha antes/depois dos filhos únicos */
.org-node-wrap:not(.has-children) .org-children::before { display: none; }

/* ── Legenda ─────────────────────────────────────────────────────────────── */
.org-legend {
    display: flex;
    gap: var(--adm-sp-4);
    flex-wrap: wrap;
    align-items: center;
    padding: var(--adm-sp-4) var(--adm-sp-6);
    border-bottom: 1px solid var(--adm-gray-100);
}
.org-legend-item {
    display: flex;
    align-items: center;
    gap: var(--adm-sp-2);
    font-size: var(--adm-text-xs);
    color: var(--adm-gray-600);
}
.org-legend-dot {
    width: 10px;
    height: 10px;
    border-radius: 50%;
}

/* ── Zoom controls ───────────────────────────────────────────────────────── */
.org-controls {
    display: flex;
    gap: var(--adm-sp-2);
    padding: var(--adm-sp-3) var(--adm-sp-4);
    border-top: 1px solid var(--adm-gray-100);
    justify-content: center;
}
.org-scale-label {
    font-size: var(--adm-text-xs);
    color: var(--adm-gray-400);
    display: flex;
    align-items: center;
    min-width: 40px;
    justify-content: center;
}
</style>

<div class="adm-page-header">
    <h1 class="adm-page-title">Organograma</h1>
    <div class="adm-page-header-actions">
        <a href="/nexora/rh/unidades" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
            Gerir Unidades
        </a>
    </div>
</div>

<div class="adm-card">
    <?php if ($unidades): ?>

    <!-- Legenda -->
    <div class="org-legend">
        <span style="font-size:var(--adm-text-xs);font-weight:600;color:var(--adm-gray-500);margin-right:var(--adm-sp-2)">Tipo:</span>
        <?php
        $tiposPresentes = array_unique(array_column($unidades, 'tipo'));
        foreach ($tiposPresentes as $tipo):
            $cfg = $tipoConfig[$tipo] ?? $tipoConfig['outro'];
        ?>
        <div class="org-legend-item">
            <div class="org-legend-dot" style="background:<?php echo $cfg['cor'] ?>"></div>
            <?php echo $cfg['label'] ?>
        </div>
        <?php endforeach; ?>
        <span style="margin-left:auto;font-size:var(--adm-text-xs);color:var(--adm-gray-400)">
            <?php echo count($unidades) ?> unidades · <?php echo array_sum(array_column($unidades, 'num_funcionarios')) ?> funcionários
        </span>
    </div>

    <!-- Árvore -->
    <div class="org-wrap" id="orgWrap">
        <div class="org-root" id="orgRoot">
            <?php foreach ($byParent[0] ?? [] as $raiz) renderNode($raiz, $byParent, $tipoConfig); ?>
        </div>
    </div>

    <!-- Controles de zoom -->
    <div class="org-controls">
        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="zoom(-0.1)">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/><line x1="8" y1="11" x2="14" y2="11"/></svg>
        </button>
        <span class="org-scale-label" id="scaleLabel">100%</span>
        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="zoom(0.1)">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/><line x1="11" y1="8" x2="11" y2="14"/><line x1="8" y1="11" x2="14" y2="11"/></svg>
        </button>
        <button class="adm-btn adm-btn-ghost adm-btn-sm" type="button" onclick="resetZoom()">Repor</button>
    </div>

    <?php else: ?>
    <div class="adm-empty" style="padding:var(--adm-sp-12)">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="color:var(--adm-gray-300);margin:0 auto var(--adm-sp-4)"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>
        <p class="adm-empty-title">Nenhuma unidade organizacional</p>
        <p class="adm-empty-sub">Adicione unidades em <a href="/nexora/rh/unidades" class="adm-link">Unidades Organizacionais</a>.</p>
    </div>
    <?php endif; ?>
</div>

<script>
let scale = 1;
const root = document.getElementById('orgRoot');

function zoom(delta) {
    scale = Math.min(2, Math.max(0.3, scale + delta));
    applyScale();
}
function resetZoom() { scale = 1; applyScale(); }
function applyScale() {
    root.style.transform = `scale(${scale})`;
    root.style.transformOrigin = 'top center';
    document.getElementById('scaleLabel').textContent = Math.round(scale * 100) + '%';
}

// Drag to pan
const wrap = document.getElementById('orgWrap');
let dragging = false, startX, startY, scrollLeft, scrollTop;
wrap.addEventListener('mousedown', e => {
    dragging = true;
    startX = e.pageX - wrap.offsetLeft;
    startY = e.pageY - wrap.offsetTop;
    scrollLeft = wrap.scrollLeft;
    scrollTop  = wrap.scrollTop;
});
document.addEventListener('mouseup', () => dragging = false);
document.addEventListener('mousemove', e => {
    if (!dragging) return;
    e.preventDefault();
    wrap.scrollLeft = scrollLeft - (e.pageX - wrap.offsetLeft - startX);
    wrap.scrollTop  = scrollTop  - (e.pageY - wrap.offsetTop  - startY);
});

// Zoom com scroll do rato
wrap.addEventListener('wheel', e => {
    if (e.ctrlKey || e.metaKey) {
        e.preventDefault();
        zoom(e.deltaY < 0 ? 0.1 : -0.1);
    }
}, { passive: false });
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
