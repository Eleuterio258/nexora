<?php

    $filtroEstado = $app->request->queryString('estado', 'pendente');
    if (!in_array($filtroEstado, ['pendente', 'aprovado', 'rejeitado', 'todos'], true)) {
        $filtroEstado = 'pendente';
    }
    $query = $filtroEstado === 'todos' ? [] : ['estado' => $filtroEstado];

    $ausencias = $app->nexora->call('GET', '/api/rh/ausencias', null, $query)['body'] ?? [];

    $ausenciaTipoLabels = [
        'ferias'              => 'Férias',
        'doenca'              => 'Doença',
        'licenca_maternidade' => 'Licença de Maternidade',
        'licenca_paternidade' => 'Licença de Paternidade',
        'luto'                => 'Luto',
        'injustificada'       => 'Injustificada',
        'outro'               => 'Outro',
    ];

    $ausenciaEstadoBadges = [
        'pendente'  => ['adm-badge--yellow', 'Pendente'],
        'aprovado'  => ['adm-badge--green',  'Aprovado'],
        'rejeitado' => ['adm-badge--red',    'Rejeitado'],
    ];

    $estadoOptions = [
        'pendente'  => 'Pendentes',
        'aprovado'  => 'Aprovados',
        'rejeitado' => 'Rejeitados',
        'todos'     => 'Todos',
    ];

    $csrf       = $app->security->csrfToken();
    $pageTitle  = 'Gestão de Ausências';
    $activePage = 'rh_ausencias';
    $breadcrumb = [['Admin', '/nexora/'], ['Recursos Humanos', ''], ['Ausências', '']];

    include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Gestão de Ausências</h1>
</div>

<div class="adm-card">
    <div class="adm-filter-bar">
        <select class="adm-select" id="estadoFiltro" onchange="location.href='?estado=' + this.value" style="width:180px">
            <?php foreach ($estadoOptions as $key => $label): ?>
            <option value="<?php echo $key ?>" <?php echo $filtroEstado === $key ? 'selected' : '' ?>><?php echo $label ?></option>
            <?php endforeach; ?>
        </select>
        <span class="adm-filter-count"><?php echo count($ausencias) ?> pedido<?php echo count($ausencias) !== 1 ? 's' : '' ?></span>
    </div>

    <?php if ($ausencias): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Funcionário</th>
                    <th>Tipo</th>
                    <th>Início</th>
                    <th>Fim</th>
                    <th>Dias</th>
                    <th>Motivo</th>
                    <th>Estado</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($ausencias as $a):
                $badge = $ausenciaEstadoBadges[$a['estado']] ?? ['adm-badge--gray', $a['estado']];
            ?>
            <tr>
                <td>
                    <a href="<?php echo htmlspecialchars($app->routes->path('rh_funcionario', ['id' => $a['funcionario_id']])) ?>" class="adm-fw-600">
                        <?php echo $a['funcionario_nome'] ? htmlspecialchars($a['funcionario_nome']) : ('#' . $a['funcionario_id']) ?>
                    </a>
                </td>
                <td><?php
                    $tipoKey  = $a['tipo']      ?? null;
                    $tipoNome = $a['tipo_nome'] ?? null;
                    echo htmlspecialchars($ausenciaTipoLabels[$tipoKey] ?? $tipoNome ?? $tipoKey ?? '—');
                ?></td>
                <td class="adm-text-muted"><?php echo !empty($a['data_inicio']) ? date('d/m/Y', strtotime($a['data_inicio'])) : '—' ?></td>
                <td class="adm-text-muted"><?php echo !empty($a['data_fim'])    ? date('d/m/Y', strtotime($a['data_fim']))    : '—' ?></td>
                <td><?php echo $a['dias'] !== null ? (int) $a['dias'] : '—' ?></td>
                <td class="adm-text-sm"><?php echo !empty($a['motivo']) ? htmlspecialchars((string)$a['motivo']) : '—' ?></td>
                <td><span class="adm-badge <?php echo $badge[0] ?>"><?php echo $badge[1] ?></span></td>
                <td>
                    <?php if ($a['estado'] === 'pendente'): ?>
                    <div class="adm-actions">
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-green)" onclick="aprovarAusencia(<?php echo (int) $a['id'] ?>)">Aprovar</button>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm" style="color:var(--adm-red)" onclick="rejeitarAusencia(<?php echo (int) $a['id'] ?>)">Rejeitar</button>
                    </div>
                    <?php else: ?>
                    —
                    <?php endif; ?>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <p class="adm-empty-title">Nenhum pedido de ausência encontrado</p>
        <p class="adm-empty-sub">Os pedidos de ausência submetidos pelos funcionários aparecem aqui.</p>
    </div>
    <?php endif; ?>
</div>

<script>
const CSRF = '<?php echo $csrf ?>';

async function postJSON(url, payload) {
    try {
        const res  = await fetch(url, {
            method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) {
            showToast(data.msg || 'Guardado com sucesso.');
            setTimeout(() => location.reload(), 700);
        } else {
            showToast(data.erro || 'Erro', 'error');
        }
    } catch { showToast('Erro de ligação', 'error'); }
}

function aprovarAusencia(id) {
    openConfirm('Aprovar ausência', 'Pretende aprovar este pedido de ausência?', async () => {
        await postJSON('/nexora/api/rh_ausencia_aprovar', { id, csrf: CSRF });
    });
}

function rejeitarAusencia(id) {
    openConfirm('Rejeitar ausência', 'Pretende rejeitar este pedido de ausência?', async () => {
        await postJSON('/nexora/api/rh_ausencia_rejeitar', { id, csrf: CSRF });
    });
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
