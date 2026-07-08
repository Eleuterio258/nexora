<?php

// Filters
$vagaHash     = $app->request->queryString('vaga_id');
$filtroVaga   = $vagaHash ? $app->id->decode($vagaHash) : 0;
$filtroEstado = $app->request->queryEnum(
    'estado',
    ['recebida', 'em_analise', 'entrevista', 'aprovada', 'rejeitada']
);

$query = ['limit' => 100];
if ($filtroVaga)   $query['vaga_id'] = $filtroVaga;
if ($filtroEstado) $query['estado']  = $filtroEstado;

$resp = $app->nexora->call('GET', '/api/recrutamento/candidaturas', null, $query);
$candidaturas = $resp['body']['data'] ?? [];

// Vagas list for filter
$vagasResp = $app->nexora->call('GET', '/api/recrutamento/vagas', null, ['limit' => 100]);
$vagas = $vagasResp['body']['data'] ?? [];
usort($vagas, fn($a, $b) => strcasecmp($a['titulo'], $b['titulo']));

$csrf = $app->security->csrfToken();
$pageTitle = 'Candidaturas';
$activePage = 'candidaturas';
$breadcrumb = [['Admin','/nexora/'],['Candidaturas','']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Candidaturas</h1>
</div>

<div class="adm-card">
    <div class="adm-filter-bar">
        <div class="adm-search-wrap">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <input class="adm-input" type="search" id="cSearch" placeholder="Pesquisar candidato, email…" oninput="filterRows()">
        </div>

        <select class="adm-select" id="cVaga" onchange="filterRows()" style="min-width:180px">
            <option value="">Todas as vagas</option>
            <?php foreach ($vagas as $v): ?>
            <option value="<?= $v['id'] ?>" <?= $filtroVaga == $v['id'] ? 'selected' : '' ?>>
                <?= htmlspecialchars($v['titulo']) ?>
            </option>
            <?php endforeach; ?>
        </select>

        <select class="adm-select" id="cEstado" onchange="filterRows()" style="width:140px">
            <option value="" <?= !$filtroEstado ? 'selected':'' ?>>Todos os estados</option>
            <option value="recebida"   <?= $filtroEstado==='recebida'   ?'selected':'' ?>>Recebidas</option>
            <option value="em_analise" <?= $filtroEstado==='em_analise' ?'selected':'' ?>>Em Análise</option>
            <option value="entrevista" <?= $filtroEstado==='entrevista' ?'selected':'' ?>>Entrevista</option>
            <option value="aprovada"   <?= $filtroEstado==='aprovada'   ?'selected':'' ?>>Aprovadas</option>
            <option value="rejeitada"  <?= $filtroEstado==='rejeitada'  ?'selected':'' ?>>Rejeitadas</option>
        </select>

        <span class="adm-filter-count" id="cCount"><?= count($candidaturas) ?> candidatura<?= count($candidaturas) !== 1 ? 's':'' ?></span>
    </div>

    <?php if ($candidaturas): ?>
    <div class="adm-table-wrap">
        <table class="adm-table" id="cTable">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Candidato</th>
                    <th>Vaga</th>
                    <th>CV / Carta</th>
                    <th>Estado</th>
                    <th>Data</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($candidaturas as $c):
                $estadoBadge = match($c['estado']) {
                    'em_analise'  => ['adm-badge--blue',   'Em Análise'],
                    'entrevista'  => ['adm-badge--indigo', 'Entrevista'],
                    'aprovada'    => ['adm-badge--green',  'Aprovada'],
                    'rejeitada'   => ['adm-badge--red',    'Rejeitada'],
                    default       => ['adm-badge--yellow', 'Recebida'],
                };
            ?>
            <tr data-estado="<?= htmlspecialchars($c['estado']) ?>">
                <td class="adm-text-muted"><?= $c['id'] ?></td>
                <td>
                    <div class="adm-fw-600"><?= htmlspecialchars($c['nome']) ?></div>
                    <div class="adm-text-xs adm-text-muted"><?= htmlspecialchars($c['email']) ?></div>
                    <?php if ($c['telefone']): ?>
                    <div class="adm-text-xs adm-text-muted"><?= htmlspecialchars($c['telefone']) ?></div>
                    <?php endif; ?>
                </td>
                <td class="adm-truncate" style="max-width:160px"><?= htmlspecialchars($c['vaga_titulo'] ?? '—') ?></td>
                <td>
                    <div style="display:flex;gap:var(--adm-sp-2);align-items:center">
                        <?php if ($c['cv_ficheiro']): ?>
                        <a href="/nexora/download?type=cv&id=<?= $c['id'] ?>" target="_blank"
                           class="adm-btn adm-btn-outline adm-btn-sm" title="CV">
                            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                                <polyline points="14 2 14 8 20 8"/>
                            </svg>
                            CV
                        </a>
                        <?php else: ?>
                        <span class="adm-text-xs adm-text-muted">Sem CV</span>
                        <?php endif; ?>

                        <?php if ($c['carta_ficheiro']): ?>
                        <a href="/nexora/download?type=carta&id=<?= $c['id'] ?>" target="_blank"
                           class="adm-btn adm-btn-outline adm-btn-sm" title="Carta">
                            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                                <polyline points="22,6 12,13 2,6"/>
                            </svg>
                            Carta
                        </a>
                        <?php endif; ?>
                    </div>
                </td>
                <td>
                    <select class="adm-select adm-text-xs" style="width:auto;padding:.25rem .5rem"
                            onchange="updateEstado(<?= $c['id'] ?>, this.value, this)"
                            data-original="<?= htmlspecialchars($c['estado']) ?>">
                        <option value="recebida"   <?= $c['estado']==='recebida'   ?'selected':'' ?>>Recebida</option>
                        <option value="em_analise" <?= $c['estado']==='em_analise' ?'selected':'' ?>>Em Análise</option>
                        <option value="entrevista" <?= $c['estado']==='entrevista' ?'selected':'' ?>>Entrevista</option>
                        <option value="aprovada"   <?= $c['estado']==='aprovada'   ?'selected':'' ?>>Aprovada</option>
                        <option value="rejeitada"  <?= $c['estado']==='rejeitada'  ?'selected':'' ?>>Rejeitada</option>
                    </select>
                </td>
                <td class="adm-text-muted" style="white-space:nowrap">
                    <?= $c['created_at'] ? date('d/m/Y', strtotime($c['created_at'])) : '—' ?>
                    <div class="adm-text-xs"><?= $c['created_at'] ? date('H:i', strtotime($c['created_at'])) : '' ?></div>
                </td>
                <td>
                    <div class="adm-actions">
                        <a href="/nexora/recrutamento/candidaturas/ver?id=<?= $app->id->encode((int)$c['id']) ?>"
                           class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Ver detalhes">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                            </svg>
                        </a>
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
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
            <circle cx="9" cy="7" r="4"/>
        </svg>
        <p class="adm-empty-title">Nenhuma candidatura encontrada</p>
        <p class="adm-empty-sub">Ainda não há candidaturas<?= $filtroEstado || $filtroVaga ? ' com este filtro' : '' ?>.</p>
    </div>
    <?php endif; ?>
</div>

<script>
const CSRF = '<?= $csrf ?>';

function filterRows() {
    const q      = document.getElementById('cSearch').value.toLowerCase();
    const vaga   = document.getElementById('cVaga').value;
    const estado = document.getElementById('cEstado').value;
    const rows   = document.querySelectorAll('#cTable tbody tr');
    let vis = 0;
    rows.forEach(row => {
        const txt  = row.textContent.toLowerCase();
        const est  = row.dataset.estado;
        // vaga filter: match cell 3 (index 2 = vaga_titulo)
        const vagaTxt = row.cells[2]?.textContent.toLowerCase() ?? '';
        const vagaMatch = !vaga || vagaTxt.includes(
            document.querySelector('#cVaga option[value="'+vaga+'"]')?.textContent.trim().toLowerCase() ?? ''
        );
        const show = (!q || txt.includes(q)) && vagaMatch && (!estado || est === estado);
        row.style.display = show ? '' : 'none';
        if (show) vis++;
    });
    document.getElementById('cCount').textContent = vis + ' candidatura' + (vis !== 1 ? 's' : '');
}

async function updateEstado(id, estado, sel) {
    const original = sel.dataset.original;
    try {
        const res  = await fetch('/nexora/api/candidatura_mover', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify({id, estado, csrf: CSRF})
        });
        const data = await res.json();
        if (data.ok) {
            sel.dataset.original = estado;
            // Update row data-estado
            sel.closest('tr').dataset.estado = estado;
            showToast('Estado actualizado');
        } else {
            sel.value = original;
            showToast(data.erro || 'Erro', 'error');
        }
    } catch {
        sel.value = original;
        showToast('Erro de ligação', 'error');
    }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
