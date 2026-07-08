<?php

    $resp  = $app->nexora->call('GET', '/api/recrutamento/vagas', null, ['limit' => 100]);
    $vagas = $resp['body']['data'] ?? [];

    $hoje = strtotime('today');
    foreach ($vagas as &$v) {
    $v['total_candid'] = $v['total_candidaturas'] ?? 0;
    $diasPrazo         = null;
    if (! empty($v['prazo'])) {
        $diasPrazo = (int) (((int) strtotime($v['prazo']) - $hoje) / 86400);
    }
    $v['dias_prazo'] = $diasPrazo;
    if (empty($v['ativa'])) {
        $v['estado'] = 'inativa';
    } elseif ($diasPrazo === null || $diasPrazo >= 0) {
        $v['estado'] = 'aberta';
    } else {
        $v['estado'] = 'encerrada';
    }
    }
    unset($v);

    $canGerirVagas = $app->session->can('recrutamento', 'gerir_vagas');
    $pageTitle  = 'Gerir Vagas';
    $activePage = 'vagas';
    $breadcrumb = [['Admin', '/nexora/'], ['Vagas', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Vagas</h1>
    <?php if ($canGerirVagas): ?>
    <div class="adm-page-header-actions">
        <a href="/nexora/recrutamento/vagas/form" class="adm-btn adm-btn-primary">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Nova Vaga
        </a>
    </div>
    <?php endif; ?>
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
            <input class="adm-input" type="search" id="vagaSearch" placeholder="Pesquisar vagas…" oninput="filterTable()">
        </div>
        <select class="adm-select" id="vagaEstado" onchange="filterTable()" style="width:140px">
            <option value="">Todos os estados</option>
            <option value="aberta">Abertas</option>
            <option value="encerrada">Encerradas</option>
            <option value="inativa">Inativas</option>
        </select>
        <span class="adm-filter-count" id="vagaCount"><?php echo count($vagas) ?> vagas</span>
    </div>

    <?php if ($vagas): ?>
    <div class="adm-table-wrap">
        <table class="adm-table" id="vagasTable">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Título / Área</th>
                    <th>Local</th>
                    <th>Vagas</th>
                    <th>Prazo</th>
                    <th>Candidaturas</th>
                    <th>Estado</th>
                    <?php if ($canGerirVagas): ?><th>Ações</th><?php endif; ?>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($vagas as $v):
                    $estadoBadge = match ($v['estado']) {
                        'aberta'    => ['adm-badge--green', 'Aberta'],
                        'encerrada' => ['adm-badge--red', 'Encerrada'],
                        default     => ['adm-badge--gray', 'Inativa'],
                    };
                    $diasPrazo = $v['dias_prazo'];
            ?>
            <tr data-estado="<?php echo $v['estado'] ?>">
                <td class="adm-text-muted"><?php echo $v['id'] ?></td>
                <td>
                    <div class="adm-fw-600"><?php echo htmlspecialchars($v['titulo']) ?></div>
                    <div class="adm-text-xs adm-text-muted"><?php echo htmlspecialchars($v['area']) ?></div>
                </td>
                <td><?php echo htmlspecialchars($v['local']) ?></td>
                <td><?php echo (int)$v['num_vagas'] ?></td>
                <td>
                    <?php if ($v['prazo']): ?>
                        <span class="<?php echo ($diasPrazo !== null && $diasPrazo <= 3) ? 'adm-text-red adm-fw-600' : '' ?>">
                            <?php echo date('d/m/Y', strtotime($v['prazo'])) ?>
                        </span>
                        <?php if ($diasPrazo !== null && $diasPrazo >= 0 && $diasPrazo <= 7): ?>
                        <div class="adm-text-xs adm-text-muted">
                            <?php echo $diasPrazo === 0 ? 'Hoje!' : $diasPrazo . 'd restantes' ?>
                        </div>
                        <?php endif; ?>
                    <?php else: ?>
                        <span class="adm-text-muted">Em aberto</span>
                    <?php endif; ?>
                </td>
                <td>
                    <?php if ($v['total_candid'] > 0): ?>
                    <a href="/nexora/recrutamento/candidaturas?vaga_id=<?php echo $app->id->encode((int)$v['id']) ?>" class="adm-badge adm-badge--blue" style="text-decoration:none">
                        <?php echo $v['total_candid'] ?>
                    </a>
                    <?php else: ?>
                    <span class="adm-text-muted">0</span>
                    <?php endif; ?>
                </td>
                <td><span class="adm-badge <?php echo $estadoBadge[0] ?>"><?php echo $estadoBadge[1] ?></span></td>
                <?php if ($canGerirVagas): ?>
                <td>
                    <div class="adm-actions">
                        <a href="/nexora/recrutamento/vagas/form?id=<?php echo $app->id->encode((int)$v['id']) ?>" class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Editar">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                            </svg>
                        </a>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon"
                                title="<?php echo $v['ativa'] ? 'Desativar' : 'Ativar' ?>"
                                onclick="toggleVaga(<?php echo $v['id'] ?>, <?php echo $v['ativa'] ? 'true' : 'false' ?>, this)"
                                style="color:<?php echo $v['ativa'] ? 'var(--adm-green)' : 'var(--adm-gray-400)' ?>">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M18.36 6.64a9 9 0 1 1-12.73 0"/>
                                <line x1="12" y1="2" x2="12" y2="12"/>
                            </svg>
                        </button>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Eliminar"
                                onclick="deleteVaga(<?php echo $v['id'] ?>, '<?php echo htmlspecialchars(addslashes($v['titulo'])) ?>')"
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
            <path d="M20 7H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2z"/>
            <path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2"/>
        </svg>
        <p class="adm-empty-title">Nenhuma vaga criada</p>
        <p class="adm-empty-sub">Começa por criar a primeira vaga.</p>
        <?php if ($canGerirVagas): ?>
        <a href="/nexora/recrutamento/vagas/form" class="adm-btn adm-btn-primary">Criar Vaga</a>
        <?php endif; ?>
    </div>
    <?php endif; ?>
</div>

<script>
function filterTable() {
    const q      = document.getElementById('vagaSearch').value.toLowerCase();
    const estado = document.getElementById('vagaEstado').value;
    const rows   = document.querySelectorAll('#vagasTable tbody tr');
    let vis = 0;
    rows.forEach(row => {
        const txt  = row.textContent.toLowerCase();
        const est  = row.dataset.estado;
        const show = (!q || txt.includes(q)) && (!estado || est === estado);
        row.style.display = show ? '' : 'none';
        if (show) vis++;
    });
    document.getElementById('vagaCount').textContent = vis + ' vaga' + (vis !== 1 ? 's' : '');
}

async function toggleVaga(id, currentAtiva, btn) {
    try {
        const res  = await fetch('/nexora/api/vaga_toggle', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify({id, csrf: '<?php echo $app->security->csrfToken() ?>'})
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.ativa ? 'Vaga ativada' : 'Vaga desativada');
            setTimeout(() => location.reload(), 800);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch {
        showToast('Erro de ligação', 'error');
    }
}

function deleteVaga(id, titulo) {
    openConfirm(
        'Eliminar vaga',
        'Eliminar "' + titulo + '"? Esta acção não pode ser revertida e eliminará também as candidaturas associadas.',
        async () => {
            try {
                const res  = await fetch('/nexora/api/vaga_delete', {
                    method: 'POST',
                    headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id, csrf: '<?php echo $app->security->csrfToken() ?>'})
                });
                const data = await res.json();
                if (data.ok) {
                    showToast('Vaga eliminada');
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
