<?php
declare(strict_types=1);

$pageTitle  = 'Boletim';
$activePage = 'boletim';

$boletim   = $portalData['boletim']['body'] ?? [];
$alunoInfo = $portalData['me']['body'] ?? [];

// ── Dados do backend (já processados) ────────────────────────────────────────
$termos       = $boletim['termos'] ?? [];
$anos         = $boletim['anos']   ?? [];
$disciplinas  = $boletim['disciplinas'] ?? [];
$mediaGeral   = $boletim['media']  ?? null;
$cfg          = $boletim['config'] ?? [];
$stats        = $boletim['stats']  ?? [];
$notaMinima   = (float)($cfg['nota_minima'] ?? 10);
$escalaMax    = (int)($cfg['escala_maxima'] ?? 20);
$nomePeriodo  = $cfg['nomenclatura_periodo'] ?? 'Período';
$activeTermId = isset($boletim['active_term_id']) ? (int)$boletim['active_term_id'] : null;

$aprovadas  = (int)($stats['aprovadas']  ?? 0);
$reprovadas = (int)($stats['reprovadas'] ?? 0);
$totalFaltas = (int)($stats['faltas']    ?? 0);

// Agrupar termos por ano lectivo
$termosPorAno = [];
foreach ($termos as $t) {
    $aid = (int)($t['ano_id'] ?? 0);
    if (!isset($termosPorAno[$aid])) {
        $termosPorAno[$aid] = [
            'id'     => $aid,
            'nome'   => $t['ano_nome'] ?? "Ano $aid",
            'status' => $t['ano_status'] ?? '',
            'termos' => [],
        ];
    }
    $termosPorAno[$aid]['termos'][] = $t;
}

$fmtNota = function(mixed $val): string {
    if ($val === null || $val === '' || $val === false) return '—';
    return number_format((float)$val, 1);
};

include dirname(__FILE__) . '/layout_top.php';
?>

<style>
.bol-year-tabs  { display:flex; gap:.5rem; flex-wrap:wrap; margin-bottom:.75rem; }
.bol-btn {
    cursor:pointer; font-family:inherit; border:1.5px solid #CBD5E1;
    background:#fff; color:#334155; font-weight:600;
    border-radius:20px; padding:.4rem 1rem; font-size:.82rem;
    transition:all .15s; display:inline-flex; align-items:center; gap:.35rem;
}
.bol-btn:hover            { border-color:#0369A1; color:#0369A1; }
.bol-btn.active           { background:#0369A1; color:#fff; border-color:#0369A1; }
.bol-year-status { font-size:.7rem; padding:.1rem .45rem; border-radius:10px;
    background:#F0F9FF; color:#0369A1; font-weight:600; }
.bol-btn.active .bol-year-status { background:rgba(255,255,255,.25); color:#fff; }

.bol-terms-group { margin-bottom:.75rem; }
.bol-terms-label { font-size:.73rem; font-weight:700; color:#94A3B8;
    text-transform:uppercase; letter-spacing:.05em; margin-bottom:.35rem; }
.bol-term-chips  { display:flex; gap:.35rem; flex-wrap:wrap; }
.bol-chip {
    cursor:pointer; font-family:inherit; border:1.5px solid #CBD5E1;
    background:#fff; color:#334155; font-weight:600;
    border-radius:16px; padding:.28rem .75rem; font-size:.8rem;
    transition:all .15s;
}
.bol-chip:hover  { border-color:#0369A1; color:#0369A1; }
.bol-chip.active { background:#0369A1; color:#fff; border-color:#0369A1; }

.bol-col-hidden { display:none !important; }
.bol-tcol                  { background:#F0F7FF; border-left:1px solid #DBEAFE; }
.bol-tcol-first            { border-left:3px solid #93C5FD !important; }
thead tr .bol-tcol         { background:rgba(0,0,0,.1); border-left-color:rgba(255,255,255,.1); }
thead tr .bol-tcol-first   { border-left:3px solid rgba(255,255,255,.4) !important; }
.bol-resumo                { background:#F8FAFF; }
</style>

<!-- ── Cabeçalho ──────────────────────────────────────────────────────────── -->
<div style="display:flex;align-items:center;justify-content:space-between;gap:.75rem;margin-bottom:1rem">
    <div>
        <h2 style="margin:0;font-size:1.15rem;color:#0C4A6E;font-weight:700">Boletim de Notas</h2>
        <div id="bol-ctx" style="font-size:.82rem;color:#64748B;margin-top:.15rem;display:none">
            A ver: <strong id="bol-ctx-label" style="color:#0369A1"></strong>
            &nbsp;·&nbsp;<button onclick="bolReset()"
                style="background:none;border:none;padding:0;font-size:.78rem;color:#94A3B8;
                       cursor:pointer;text-decoration:underline">Ver tudo</button>
        </div>
    </div>
    <a id="bol-print" href="/portal/aluno/boletim/imprimir" target="_blank"
       style="display:inline-flex;align-items:center;gap:.4rem;padding:.4rem .85rem;border-radius:8px;
              background:#0369A1;color:#fff;text-decoration:none;font-size:.82rem;font-weight:600;white-space:nowrap">
        <i class="fa-solid fa-print"></i> Imprimir / PDF
    </a>
</div>

<!-- ── Tabs de ano (só se > 1 ano) ──────────────────────────────────────── -->
<?php if (count($termosPorAno) > 1): ?>
<div class="bol-year-tabs">
    <button class="bol-btn active" data-year="all" onclick="bolSelectYear(this,'all')">
        <i class="fa-solid fa-layer-group"></i> Todos os anos
    </button>
    <?php foreach ($termosPorAno as $aid => $grupo):
        $st = $grupo['status'];
    ?>
    <button class="bol-btn" data-year="<?= $aid ?>" onclick="bolSelectYear(this,<?= $aid ?>)">
        <i class="fa-solid fa-calendar-days"></i>
        <?= htmlspecialchars($grupo['nome']) ?>
        <?php if ($st === 'activo'): ?>
        <span class="bol-year-status">actual</span>
        <?php elseif ($st === 'encerrado'): ?>
        <span class="bol-year-status" style="background:#F1F5F9;color:#64748B">encerrado</span>
        <?php endif; ?>
    </button>
    <?php endforeach; ?>
</div>
<?php endif; ?>

<!-- ── Chips de período ──────────────────────────────────────────────────── -->
<?php foreach ($termosPorAno as $aid => $grupo): ?>
<div class="bol-terms-group" id="bol-group-<?= $aid ?>">
    <?php if (count($termosPorAno) > 1): ?>
    <div class="bol-terms-label"><?= htmlspecialchars($grupo['nome']) ?> — <?= htmlspecialchars($nomePeriodo) ?>s</div>
    <?php else: ?>
    <div class="bol-terms-label">Filtrar por <?= htmlspecialchars(strtolower($nomePeriodo)) ?></div>
    <?php endif; ?>
    <div class="bol-term-chips">
        <button class="bol-chip active" data-chip-year="<?= $aid ?>" data-chip-term="all"
                onclick="bolSelectChip(this,<?= $aid ?>,'all')">
            Todos
        </button>
        <?php foreach ($grupo['termos'] as $t): ?>
        <button class="bol-chip" data-chip-year="<?= $aid ?>" data-chip-term="<?= (int)$t['id'] ?>"
                onclick="bolSelectChip(this,<?= $aid ?>,<?= (int)$t['id'] ?>)">
            <?= htmlspecialchars($t['nome'] ?? '') ?>
        </button>
        <?php endforeach; ?>
    </div>
</div>
<?php endforeach; ?>

<!-- ── Estatísticas (vindas do backend) ──────────────────────────────────── -->
<?php if ($mediaGeral !== null || !empty($disciplinas)): ?>
<div class="portal-stats" style="grid-template-columns:repeat(auto-fit,minmax(120px,1fr));margin-bottom:1rem">
    <?php if ($mediaGeral !== null): ?>
    <div class="portal-stat">
        <span class="portal-stat-label">Média geral</span>
        <span class="portal-stat-value" style="color:<?= (float)$mediaGeral >= $notaMinima ? '#15803D' : '#B91C1C' ?>">
            <?= number_format((float)$mediaGeral, 1) ?>
        </span>
        <span class="portal-stat-sub"><?= (float)$mediaGeral >= $notaMinima ? 'Aprovado' : 'Em risco' ?></span>
    </div>
    <?php endif; ?>
    <?php if ($totalFaltas > 0): ?>
    <div class="portal-stat">
        <span class="portal-stat-label">Total de faltas</span>
        <span class="portal-stat-value"><?= $totalFaltas ?></span>
    </div>
    <?php endif; ?>
    <div class="portal-stat">
        <span class="portal-stat-label">Disciplinas</span>
        <span class="portal-stat-value"><?= count($disciplinas) ?></span>
    </div>
    <?php if ($aprovadas > 0): ?>
    <div class="portal-stat">
        <span class="portal-stat-label">Aprovadas</span>
        <span class="portal-stat-value" style="color:#15803D"><?= $aprovadas ?></span>
    </div>
    <?php endif; ?>
    <?php if ($reprovadas > 0): ?>
    <div class="portal-stat">
        <span class="portal-stat-label">Reprovadas</span>
        <span class="portal-stat-value" style="color:#B91C1C"><?= $reprovadas ?></span>
    </div>
    <?php endif; ?>
</div>
<?php endif; ?>

<!-- ── Tabela de notas ───────────────────────────────────────────────────── -->
<?php if (empty($disciplinas)): ?>
<div class="portal-card">
    <div class="portal-empty">
        <i class="fa-solid fa-chart-bar"></i>
        <p>Ainda não há notas lançadas para este aluno.</p>
    </div>
</div>
<?php else: ?>
<div class="portal-card" style="padding:0;overflow:hidden">
    <div style="padding:.75rem 1rem;border-bottom:1px solid #F1F5F9;display:flex;align-items:center;gap:.5rem">
        <h3 class="portal-card-title" style="margin:0;flex:1">Notas por disciplina</h3>
        <span id="bol-period-badge" style="display:none;align-items:center;gap:.3rem;font-size:.78rem;
              background:#EFF6FF;color:#1D4ED8;font-weight:600;padding:.2rem .65rem;
              border-radius:20px;white-space:nowrap">
            <i class="fa-solid fa-calendar-check"></i>
            <span id="bol-period-badge-label"></span>
        </span>
    </div>
    <div style="overflow-x:auto">
    <table class="portal-table" id="bol-table"
           style="min-width:<?= 200 + count($termos) * 80 + 220 ?>px">
        <thead>
            <tr style="background:#1E3A5F">
                <th style="min-width:180px;text-align:left;font-size:.7rem;font-weight:600;
                           letter-spacing:.05em;text-transform:uppercase;color:rgba(255,255,255,.5);
                           padding-bottom:.25rem"></th>
                <?php if (!empty($termos)): ?>
                <th colspan="<?= count($termos) ?>"
                    class="bol-tcol bol-tcol-first"
                    style="text-align:center;font-size:.7rem;font-weight:700;
                           letter-spacing:.06em;text-transform:uppercase;
                           color:rgba(255,255,255,.65);padding-bottom:.25rem;border-bottom:1px solid rgba(255,255,255,.15)">
                    Notas por <?= htmlspecialchars(strtolower($nomePeriodo)) ?>
                </th>
                <?php endif; ?>
                <th colspan="3"
                    style="text-align:center;font-size:.7rem;font-weight:700;
                           letter-spacing:.06em;text-transform:uppercase;
                           color:rgba(255,255,255,.65);padding-bottom:.25rem;
                           border-left:3px solid rgba(255,255,255,.25);
                           border-bottom:1px solid rgba(255,255,255,.15)">
                    Resumo
                </th>
            </tr>
            <tr>
                <th style="min-width:180px;text-align:left">Disciplina</th>
                <?php foreach ($termos as $i => $t): ?>
                <th class="bol-tcol<?= $i === 0 ? ' bol-tcol-first' : '' ?>"
                    data-col-term="<?= (int)$t['id'] ?>"
                    data-col-year="<?= (int)($t['ano_id'] ?? 0) ?>"
                    style="text-align:center;min-width:80px">
                    <?= htmlspecialchars($t['nome'] ?? '') ?>
                    <?php if (count($termosPorAno) > 1 && !empty($t['ano_nome'])): ?>
                    <div style="font-size:.67rem;font-weight:400;color:rgba(255,255,255,.7);margin-top:1px">
                        <?= htmlspecialchars($t['ano_nome']) ?>
                    </div>
                    <?php endif; ?>
                </th>
                <?php endforeach; ?>
                <th class="bol-resumo" style="text-align:center;min-width:65px;border-left:3px solid rgba(255,255,255,.25)">Média</th>
                <th class="bol-resumo" style="text-align:center;min-width:95px">Resultado</th>
                <th class="bol-resumo" style="text-align:center;min-width:55px">Faltas</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($disciplinas as $d):
            // Backend já calculou media, aprovado, faltas
            $media_d  = $d['media']   ?? null;
            $aprovado = $d['aprovado'] ?? null; // true | false | null
            $faltas_d = (int)($d['faltas'] ?? 0);

            // Indexar períodos por term_id (backend devolve array, não objecto)
            $periodoMap = [];
            foreach ((array)($d['periodos'] ?? []) as $p) {
                $periodoMap[(int)$p['term_id']] = $p;
            }
        ?>
        <tr>
            <td style="font-weight:600;color:#0C4A6E">
                <?= htmlspecialchars($d['nome'] ?? '') ?>
            </td>
            <?php foreach ($termos as $i => $t):
                $tid = (int)$t['id'];
                $p   = $periodoMap[$tid] ?? null;

                // Período não existe nesta disciplina → não é leccionada
                if ($p === null) {
                    $cor = '#E2E8F0'; $fw = '400';
                } elseif ($p['tem_avaliacao']) {
                    $nota_p = $p['nota'] ?? null;
                    $cor = $nota_p !== null
                        ? ((float)$nota_p >= $notaMinima ? '#15803D' : '#B91C1C')
                        : '#94A3B8';
                    $fw = '600';
                } else {
                    $cor = '#94A3B8'; $fw = '400';
                }
            ?>
            <td class="bol-tcol<?= $i === 0 ? ' bol-tcol-first' : '' ?>"
                data-col-term="<?= $tid ?>"
                data-col-year="<?= (int)($t['ano_id'] ?? 0) ?>"
                style="text-align:center;font-weight:<?= $fw ?>;color:<?= $cor ?>">
                <?php if ($p === null): ?>
                    <span title="Não leccionada neste período" style="font-size:.8em;opacity:.35">×</span>
                <?php elseif ($p['tem_avaliacao']): ?>
                    <?= $fmtNota($p['nota'] ?? null) ?>
                    <?php if ($p['tem_exame'] ?? false): ?>
                    <span title="Inclui exame" style="font-size:.65em;margin-left:2px;opacity:.6">E</span>
                    <?php endif; ?>
                <?php else: ?>
                    <span title="Sem notas lançadas" style="font-size:.85em">–</span>
                    <?php if ($p['tem_exame'] ?? false): ?>
                    <span title="Previsto exame" style="font-size:.65em;margin-left:2px;opacity:.45">E</span>
                    <?php endif; ?>
                <?php endif; ?>
            </td>
            <?php endforeach; ?>
            <td class="bol-resumo" style="text-align:center;font-weight:700;border-left:3px solid #BFDBFE;
                       color:<?= $aprovado === true ? '#15803D' : ($aprovado === false ? '#B91C1C' : '#94A3B8') ?>;background:#F8FAFF">
                <?= $media_d !== null ? number_format((float)$media_d, 1) : '—' ?>
            </td>
            <td class="bol-resumo" style="text-align:center;background:#F8FAFF">
                <?php if ($aprovado === true): ?>
                <span class="portal-badge badge-green">Aprovado</span>
                <?php elseif ($aprovado === false): ?>
                <span class="portal-badge badge-red">Reprovado</span>
                <?php else: ?>
                <span style="color:#94A3B8">—</span>
                <?php endif; ?>
            </td>
            <td class="bol-resumo" style="text-align:center;color:#64748B;background:#F8FAFF">
                <?= $faltas_d > 0 ? $faltas_d : '—' ?>
            </td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    </div>
</div>
<?php endif; ?>

<script>
(function () {
    const activeTermId = <?= $activeTermId !== null ? $activeTermId : 'null' ?>;

    // Mapa: term_id → {nome, ano_id, ano_nome}
    const terms = <?= json_encode(
        array_column(
            array_map(fn($t) => [
                'id'       => (int)$t['id'],
                'nome'     => $t['nome'] ?? '',
                'ano_id'   => (int)($t['ano_id'] ?? 0),
                'ano_nome' => $t['ano_nome'] ?? '',
            ], $termos),
            null, 'id'
        )
    , JSON_UNESCAPED_UNICODE) ?>;

    function tcols()  { return document.querySelectorAll('.bol-tcol'); }
    function chips()  { return document.querySelectorAll('[data-chip-term]'); }
    function yrBtns() { return document.querySelectorAll('[data-year]'); }
    function groups() { return document.querySelectorAll('[id^="bol-group-"]'); }

    function setCtx(label) {
        const ctx = document.getElementById('bol-ctx');
        const lbl = document.getElementById('bol-ctx-label');
        if (label) { lbl.textContent = label; ctx.style.display = ''; }
        else        { ctx.style.display = 'none'; }
    }

    function setBadge(label) {
        const b = document.getElementById('bol-period-badge');
        const l = document.getElementById('bol-period-badge-label');
        if (!b) return;
        if (label) { l.textContent = label; b.style.display = 'inline-flex'; }
        else        { b.style.display = 'none'; }
    }

    function showCols(predicate) {
        tcols().forEach(el => {
            const tid = +el.dataset.colTerm;
            const yid = +el.dataset.colYear;
            el.classList.toggle('bol-col-hidden', !predicate(tid, yid));
        });
    }

    function activateChip(el) {
        chips().forEach(c => c.classList.remove('active'));
        el.classList.add('active');
    }

    function activateYear(el) {
        yrBtns().forEach(b => b.classList.remove('active'));
        el.classList.add('active');
    }

    window.bolReset = function () {
        showCols(() => true);
        setCtx('');
        setBadge('');
        document.querySelectorAll('[data-year="all"]').forEach(b => b.classList.add('active'));
        yrBtns().forEach(b => { if (b.dataset.year !== 'all') b.classList.remove('active'); });
        groups().forEach(g => g.style.display = '');
        chips().forEach(c => { c.classList.toggle('active', c.dataset.chipTerm === 'all'); });
    };

    window.bolSelectYear = function (btn, yearId) {
        activateYear(btn);
        if (yearId === 'all') {
            groups().forEach(g => g.style.display = '');
            showCols(() => true);
            chips().forEach(c => { c.classList.toggle('active', c.dataset.chipTerm === 'all'); });
            setCtx('');
            setBadge('');
        } else {
            groups().forEach(g => {
                g.style.display = g.id === 'bol-group-' + yearId ? '' : 'none';
            });
            showCols((tid, yid) => yid === +yearId);
            chips().forEach(c => {
                c.classList.toggle('active',
                    c.dataset.chipYear == yearId && c.dataset.chipTerm === 'all');
            });
            const t = Object.values(terms).find(t => t.ano_id === +yearId);
            setCtx(t ? t.ano_nome : '');
            setBadge('');
        }
    };

    window.bolSelectChip = function (btn, yearId, termId) {
        activateChip(btn);
        const yBtn = document.querySelector('[data-year="' + yearId + '"]');
        if (yBtn) activateYear(yBtn);

        if (termId === 'all') {
            showCols((tid, yid) => yid === +yearId);
            const t = Object.values(terms).find(t => t.ano_id === +yearId);
            setCtx(t ? t.ano_nome : '');
            setBadge('');
        } else {
            showCols((tid) => tid === +termId);
            const t = terms[+termId];
            const label    = t ? t.nome : '';
            const anoLabel = t ? t.ano_nome : '';
            setCtx(anoLabel ? anoLabel + ' · ' + label : label);
            setBadge(label);
        }
    };

    // Activar por defeito o período activo (ou o primeiro disponível)
    (function init() {
        let target = null;
        if (activeTermId) {
            target = document.querySelector('[data-chip-term="' + activeTermId + '"]');
        }
        if (!target) {
            target = document.querySelector('[data-chip-term]:not([data-chip-term="all"])');
        }
        if (target) {
            bolSelectChip(target, +target.dataset.chipYear, +target.dataset.chipTerm);
        }
    })();
})();
</script>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>
