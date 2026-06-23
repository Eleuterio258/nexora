<?php

$mesAtual = (int) date('m');
$anoAtual = (int) date('Y');
$mes  = $app->request->queryInt('mes',  $mesAtual);
$ano  = $app->request->queryInt('ano',  $anoAtual);
if ($mes < 1 || $mes > 12) $mes = $mesAtual;
if ($ano < 2020 || $ano > $anoAtual + 1) $ano = $anoAtual;

$mesesLabels = [1=>'Janeiro',2=>'Fevereiro',3=>'Março',4=>'Abril',5=>'Maio',6=>'Junho',
                7=>'Julho',8=>'Agosto',9=>'Setembro',10=>'Outubro',11=>'Novembro',12=>'Dezembro'];

$resumoResp = $app->nexora->call('GET', '/api/self-service/assiduidade/resumo', null, ['mes'=>sprintf('%02d',$mes),'ano'=>$ano]);
$resumo = ($resumoResp['status'] === 200 && is_array($resumoResp['body'])) ? $resumoResp['body'] : [];

$registosResp = $app->nexora->call('GET', '/api/self-service/assiduidade', null, ['mes'=>sprintf('%02d',$mes),'ano'=>$ano]);
$registos = ($registosResp['status'] === 200 && is_array($registosResp['body']) && array_is_list($registosResp['body'])) ? $registosResp['body'] : [];

$justifResp = $app->nexora->call('GET', '/api/self-service/assiduidade/justificacoes');
$justificacoes = ($justifResp['status'] === 200 && is_array($justifResp['body']) && array_is_list($justifResp['body'])) ? $justifResp['body'] : [];

$csrf       = $app->security->csrfToken();
$pageTitle  = 'Assiduidade';
$activePage = 'minha_assiduidade';
$breadcrumb = [['Admin', '/nexora/'], ['Assiduidade', '']];

$estadoBadges = [
    'presente'         => ['adm-badge--green',  'Presente'],
    'atraso'           => ['adm-badge--yellow', 'Atraso'],
    'falta'            => ['adm-badge--red',    'Falta'],
    'saida_antecipada' => ['adm-badge--blue',   'Saída Antecipada'],
];
$justifBadges = [
    'pendente'  => ['adm-badge--yellow', 'Pendente'],
    'aprovado'  => ['adm-badge--green',  'Aprovado'],
    'rejeitado' => ['adm-badge--red',    'Rejeitado'],
];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title"><i class="fa-solid fa-clock" style="color:var(--adm-green)"></i> Assiduidade</h1>
    <div class="adm-page-header-actions">
        <button class="adm-btn adm-btn-outline" onclick="abrirJustificacao()">
            <i class="fa-solid fa-pen"></i> Justificar Falta/Atraso
        </button>
    </div>
</div>

<!-- Filtro de mês -->
<form method="GET" style="display:flex;gap:var(--adm-sp-3);align-items:center;margin-bottom:var(--adm-sp-6)">
    <select class="adm-select" name="mes" style="width:150px">
        <?php foreach ($mesesLabels as $n => $l): ?>
        <option value="<?= $n ?>" <?= $mes === $n ? 'selected' : '' ?>><?= $l ?></option>
        <?php endforeach; ?>
    </select>
    <select class="adm-select" name="ano" style="width:100px">
        <?php for ($y = $anoAtual; $y >= $anoAtual - 3; $y--): ?>
        <option value="<?= $y ?>" <?= $ano === $y ? 'selected' : '' ?>><?= $y ?></option>
        <?php endfor; ?>
    </select>
    <button type="submit" class="adm-btn adm-btn-outline">
        <i class="fa-solid fa-filter"></i> Filtrar
    </button>
</form>

<!-- Resumo do mês -->
<div class="adm-stats-grid" style="margin-bottom:var(--adm-sp-6)">
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--green"><i class="fa-solid fa-calendar-check" style="font-size:1.1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= (int)($resumo['dias_trabalhados'] ?? 0) ?></div>
            <div class="adm-stat-label">Dias Trabalhados</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--blue"><i class="fa-solid fa-clock" style="font-size:1.1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= number_format((float)($resumo['horas_totais'] ?? 0), 1) ?>h</div>
            <div class="adm-stat-label">Horas Totais</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--yellow"><i class="fa-solid fa-triangle-exclamation" style="font-size:1.1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= (int)($resumo['atrasos'] ?? 0) ?></div>
            <div class="adm-stat-label">Atrasos</div>
        </div>
    </div>
    <div class="adm-stat-card">
        <div class="adm-stat-icon adm-stat-icon--red"><i class="fa-solid fa-circle-xmark" style="font-size:1.1rem"></i></div>
        <div class="adm-stat-info">
            <div class="adm-stat-num"><?= (int)($resumo['faltas'] ?? 0) ?></div>
            <div class="adm-stat-label">Faltas</div>
        </div>
    </div>
</div>

<!-- Registos do mês -->
<div class="adm-card adm-mb-6">
    <div class="adm-card-header">
        <h2 class="adm-card-title">Registos de <?= htmlspecialchars($mesesLabels[$mes]) ?> <?= $ano ?></h2>
    </div>
    <?php if ($registos): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Data</th>
                    <th>Entrada</th>
                    <th>Saída</th>
                    <th>Horas</th>
                    <th>Estado</th>
                    <th>Observação</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($registos as $r):
                $data = isset($r['data']) ? date('d/m/Y', strtotime($r['data'])) : '—';
                $entrada = isset($r['hora_entrada']) ? substr($r['hora_entrada'], 0, 5) : '—';
                $saida   = isset($r['hora_saida'])   ? substr($r['hora_saida'],   0, 5) : '—';
                $horas   = isset($r['horas_trabalhadas']) && $r['horas_trabalhadas'] !== null
                           ? number_format((float)$r['horas_trabalhadas'], 1) . 'h' : '—';
                $estado  = $r['tipo'] ?? 'presente';
                [$badgeCls, $badgeTxt] = $estadoBadges[$estado] ?? ['adm-badge--gray', $estado];
            ?>
            <tr>
                <td class="adm-fw-600"><?= $data ?></td>
                <td><?= htmlspecialchars($entrada) ?></td>
                <td><?= htmlspecialchars($saida) ?></td>
                <td><?= $horas ?></td>
                <td><span class="adm-badge <?= $badgeCls ?>"><?= $badgeTxt ?></span></td>
                <td class="adm-text-muted"><?= htmlspecialchars($r['observacao'] ?? '') ?></td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty">
        <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="3" y1="9" x2="21" y2="9"/></svg>
        <p class="adm-empty-title">Sem registos este mês</p>
    </div>
    <?php endif; ?>
</div>

<!-- Justificações -->
<div class="adm-card">
    <div class="adm-card-header">
        <h2 class="adm-card-title">As Minhas Justificações</h2>
        <div class="adm-card-actions">
            <button class="adm-btn adm-btn-primary adm-btn-sm" onclick="abrirJustificacao()">
                <i class="fa-solid fa-plus"></i> Nova
            </button>
        </div>
    </div>
    <?php if ($justificacoes): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead><tr><th>Data</th><th>Tipo</th><th>Motivo</th><th>Estado</th></tr></thead>
            <tbody>
            <?php foreach ($justificacoes as $j):
                [$bCls, $bTxt] = $justifBadges[$j['estado'] ?? 'pendente'] ?? ['adm-badge--gray', $j['estado']];
            ?>
            <tr>
                <td><?= htmlspecialchars(isset($j['data']) ? date('d/m/Y', strtotime($j['data'])) : '—') ?></td>
                <td><?= $j['tipo'] === 'atraso' ? 'Atraso' : 'Falta' ?></td>
                <td><?= htmlspecialchars($j['motivo'] ?? '') ?></td>
                <td><span class="adm-badge <?= $bCls ?>"><?= $bTxt ?></span></td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="adm-empty"><p class="adm-empty-title">Sem justificações</p></div>
    <?php endif; ?>
</div>

<!-- Modal justificação -->
<div class="adm-modal-overlay" id="modalJustif">
    <div class="adm-modal">
        <p class="adm-modal-title">Justificar Falta / Atraso</p>
        <div id="justifErro" class="adm-alert adm-alert--error" style="display:none"></div>
        <div class="adm-form-row">
            <div class="adm-form-group">
                <label class="adm-label">Tipo</label>
                <select class="adm-select" id="jTipo">
                    <option value="falta">Falta</option>
                    <option value="atraso">Atraso</option>
                </select>
            </div>
            <div class="adm-form-group">
                <label class="adm-label">Data</label>
                <input type="date" class="adm-input" id="jData" value="<?= date('Y-m-d') ?>">
            </div>
        </div>
        <div class="adm-form-group">
            <label class="adm-label">Motivo</label>
            <textarea class="adm-textarea" id="jMotivo" rows="3" placeholder="Descreva o motivo…"></textarea>
        </div>
        <div class="adm-modal-footer">
            <button class="adm-btn adm-btn-outline" onclick="fecharJustificacao()">Cancelar</button>
            <button class="adm-btn adm-btn-primary" id="btnJustif" onclick="submeterJustificacao()">
                <i class="fa-solid fa-paper-plane"></i> Submeter
            </button>
        </div>
    </div>
</div>

<script>
const CSRF = <?= json_encode($csrf) ?>;
function abrirJustificacao()  { document.getElementById('modalJustif').classList.add('open'); }
function fecharJustificacao() { document.getElementById('modalJustif').classList.remove('open'); }
document.getElementById('modalJustif').addEventListener('click', e => { if (e.target===e.currentTarget) fecharJustificacao(); });

async function submeterJustificacao() {
    const erro = document.getElementById('justifErro');
    const btn  = document.getElementById('btnJustif');
    const tipo  = document.getElementById('jTipo').value;
    const data  = document.getElementById('jData').value;
    const motivo = document.getElementById('jMotivo').value.trim();
    if (!data || !motivo) { erro.textContent = 'Preencha a data e o motivo.'; erro.style.display='flex'; return; }
    btn.disabled = true;
    const resp = await fetch('/nexora/api/self_service_justificacao', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({tipo, data, motivo, csrf_token: CSRF})
    });
    const d = await resp.json();
    btn.disabled = false;
    if (d.ok) { showToast('Justificação submetida'); setTimeout(()=>location.reload(),800); }
    else { erro.textContent = d.error || 'Erro'; erro.style.display='flex'; }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
