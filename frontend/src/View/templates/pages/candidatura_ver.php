<?php

$id = $app->request->queryInt('id', 0);
if (!$id) { header('Location: /nexora/recrutamento/candidaturas'); exit; }

$resp = $app->nexora->call('GET', "/api/recrutamento/candidaturas/$id");
if ($resp['status'] !== 200) { header('Location: /nexora/recrutamento/candidaturas'); exit; }
$c = $resp['body'];

// Auto-transition recebida → em_analise on first view (a Nexora regista a nota de sistema)
if ($c['estado'] === 'recebida') {
    $moveResp = $app->nexora->call('PUT', "/api/recrutamento/candidaturas/$id/estado", ['estado' => 'em_analise']);
    if ($moveResp['status'] === 200) {
        $resp = $app->nexora->call('GET', "/api/recrutamento/candidaturas/$id");
        $c = $resp['body'] ?? $c;
    }
}

// Notes / timeline (já vêm ordenadas por created_at DESC)
$notas        = $c['notas'] ?? [];
$respostasVaga = $c['respostas_vaga'] ?? [];

$csrf = $app->security->csrfToken();
$adminUser = $app->session->user()['nome'] ?? $app->session->user()['email'] ?? 'admin';

$STAGES = [
    'recebida'   => ['Recebida',   'yellow'],
    'em_analise' => ['Em Análise', 'blue'],
    'entrevista' => ['Entrevista', 'indigo'],
    'aprovada'   => ['Aprovada',   'green'],
    'rejeitada'  => ['Rejeitada',  'red'],
];

$estadoBadgeClass = 'adm-badge--' . ($STAGES[$c['estado']][1] ?? 'gray');
$estadoLabel      = $STAGES[$c['estado']][0] ?? $c['estado'];

$pageTitle  = htmlspecialchars($c['nome']);
$activePage = 'candidaturas';
$breadcrumb = [['Admin','/nexora/'],['Candidaturas','/nexora/recrutamento/candidaturas'],[$c['nome'],'']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<!-- Page header -->
<div class="adm-page-header" style="align-items:flex-start">
    <div>
        <div style="display:flex;align-items:center;gap:var(--adm-sp-3);margin-bottom:.4rem">
            <h1 class="adm-page-title" style="margin:0"><?= htmlspecialchars($c['nome']) ?></h1>
            <span class="adm-badge <?= $estadoBadgeClass ?>"><?= $estadoLabel ?></span>
        </div>
        <div style="display:flex;gap:var(--adm-sp-4);align-items:center;font-size:var(--adm-text-sm);color:var(--adm-gray-500)">
            <span><?= htmlspecialchars($c['email']) ?></span>
            <?php if ($c['telefone']): ?>
            <span>·</span><span><?= htmlspecialchars($c['telefone']) ?></span>
            <?php endif; ?>
            <span>·</span>
            <span>Vaga: <strong><?= htmlspecialchars($c['vaga_titulo'] ?? '—') ?></strong></span>
        </div>
    </div>
    <div class="adm-page-header-actions">
        <a href="/nexora/recrutamento/candidaturas" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
            Voltar
        </a>
        <?php if ($c['cv_ficheiro']): ?>
        <a href="/nexora/download?type=cv&id=<?= $c['id'] ?>" target="_blank" class="adm-btn adm-btn-outline adm-btn-sm">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
            Ver CV
        </a>
        <?php endif; ?>
        <?php if ($c['estado'] === 'aprovada'): ?>
        <button class="adm-btn adm-btn-primary adm-btn-sm" onclick="contratarCandidato()" id="btnContratar">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
            Contratar
        </button>
        <?php endif; ?>
    </div>
</div>

<div class="adm-detail-grid" style="gap:var(--adm-sp-6)">

    <!-- ── Main column with tabs ── -->
    <div>
        <div class="adm-tabs" id="mainTabs">
            <button class="adm-tab active" onclick="switchTab('info',this)">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M20 21a8 8 0 1 0-16 0"/></svg>
                Informação
            </button>
            <button class="adm-tab" onclick="switchTab('avaliacao',this)">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                Avaliação
            </button>
            <button class="adm-tab" onclick="switchTab('entrevista',this)">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                Entrevista
            </button>
            <button class="adm-tab" onclick="switchTab('notas',this)">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
                Notas
                <?php if (count($notas)): ?>
                <span class="adm-tab-badge"><?= count($notas) ?></span>
                <?php endif; ?>
            </button>
            <?php if (!empty($respostasVaga)): ?>
            <button class="adm-tab" onclick="switchTab('respostas',this)">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
                Respostas da Vaga
                <span class="adm-tab-badge"><?= count($respostasVaga) ?></span>
            </button>
            <?php endif; ?>
        </div>

        <!-- Tab: Informação -->
        <div class="adm-tab-panel active" id="tab-info">
            <div class="adm-card adm-mb-6">
                <div class="adm-card-header"><h2 class="adm-card-title">Contacto</h2></div>
                <div class="adm-card-body">
                    <div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--adm-sp-5)">
                        <div class="adm-detail-pair">
                            <span class="adm-detail-pair-label">Nome</span>
                            <span class="adm-detail-pair-value"><?= htmlspecialchars($c['nome']) ?></span>
                        </div>
                        <div class="adm-detail-pair">
                            <span class="adm-detail-pair-label">Email</span>
                            <span class="adm-detail-pair-value"><a href="mailto:<?= htmlspecialchars($c['email']) ?>" style="color:var(--adm-green)"><?= htmlspecialchars($c['email']) ?></a></span>
                        </div>
                        <?php if ($c['telefone']): ?>
                        <div class="adm-detail-pair">
                            <span class="adm-detail-pair-label">Telefone</span>
                            <span class="adm-detail-pair-value"><a href="tel:<?= htmlspecialchars($c['telefone']) ?>" style="color:var(--adm-green)"><?= htmlspecialchars($c['telefone']) ?></a></span>
                        </div>
                        <?php endif; ?>
                        <div class="adm-detail-pair">
                            <span class="adm-detail-pair-label">Vaga</span>
                            <span class="adm-detail-pair-value"><?= htmlspecialchars($c['vaga_titulo'] ?? '—') ?></span>
                        </div>
                        <div class="adm-detail-pair">
                            <span class="adm-detail-pair-label">Data da Candidatura</span>
                            <span class="adm-detail-pair-value"><?= $c['created_at'] ? date('d/m/Y H:i', strtotime($c['created_at'])) : '—' ?></span>
                        </div>
                        <div class="adm-detail-pair">
                            <span class="adm-detail-pair-label">Responsável</span>
                            <span class="adm-detail-pair-value"><?= htmlspecialchars($c['responsavel'] ?? '—') ?></span>
                        </div>
                    </div>
                </div>
            </div>

            <div class="adm-card adm-mb-6">
                <div class="adm-card-header"><h2 class="adm-card-title">Documentos</h2></div>
                <div class="adm-card-body">
                    <?php if ($c['cv_ficheiro'] || $c['carta_ficheiro']): ?>
                    <div style="display:flex;gap:var(--adm-sp-4);flex-wrap:wrap">
                        <?php if ($c['cv_ficheiro']): ?>
                        <a href="/nexora/download?type=cv&id=<?= $c['id'] ?>" target="_blank" class="adm-btn adm-btn-outline" style="padding:var(--adm-sp-3) var(--adm-sp-5)">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                            <div><div class="adm-fw-600">Curriculum Vitae</div><div class="adm-text-xs adm-text-muted">Abrir PDF</div></div>
                        </a>
                        <?php endif; ?>
                        <?php if ($c['carta_ficheiro']): ?>
                        <a href="/nexora/download?type=carta&id=<?= $c['id'] ?>" target="_blank" class="adm-btn adm-btn-outline" style="padding:var(--adm-sp-3) var(--adm-sp-5)">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                            <div><div class="adm-fw-600">Carta de Motivação</div><div class="adm-text-xs adm-text-muted">Abrir</div></div>
                        </a>
                        <?php endif; ?>
                    </div>
                    <?php else: ?><p class="adm-text-muted">Nenhum documento enviado.</p><?php endif; ?>
                </div>
            </div>

            <?php if (!empty($c['carta'])): ?>
            <div class="adm-card">
                <div class="adm-card-header"><h2 class="adm-card-title">Carta de Motivação (texto)</h2></div>
                <div class="adm-card-body">
                    <p style="white-space:pre-wrap;line-height:1.7;color:var(--adm-gray-700)"><?= htmlspecialchars($c['carta']) ?></p>
                </div>
            </div>
            <?php endif; ?>
        </div>

        <!-- Tab: Avaliação -->
        <div class="adm-tab-panel" id="tab-avaliacao">
            <div class="adm-card">
                <div class="adm-card-header"><h2 class="adm-card-title">Avaliação do Candidato</h2></div>
                <div class="adm-card-body">
                    <div class="adm-form-group">
                        <label class="adm-label">Pontuação Geral</label>
                        <div style="display:flex;align-items:center;gap:var(--adm-sp-4);margin-bottom:var(--adm-sp-2)">
                            <div class="star-rating" id="starRating" data-score="<?= (int)($c['score'] ?? 0) ?>">
                                <?php for ($i=1; $i<=5; $i++): ?>
                                <span class="star <?= $i <= (int)($c['score'] ?? 0) ? 'filled' : '' ?>"
                                      data-v="<?= $i ?>" onclick="setStar(<?= $i ?>)">★</span>
                                <?php endfor; ?>
                            </div>
                            <span id="scoreLabel" style="font-size:var(--adm-text-sm);color:var(--adm-gray-500)">
                                <?php
                                $scoreLabels = [0=>'Sem avaliação',1=>'Fraco',2=>'Abaixo da média',3=>'Médio',4=>'Bom',5=>'Excelente'];
                                echo $scoreLabels[(int)($c['score'] ?? 0)];
                                ?>
                            </span>
                        </div>
                    </div>

                    <div class="adm-form-group">
                        <label class="adm-label" for="avalNota">Notas da Avaliação</label>
                        <textarea class="adm-textarea" id="avalNota" rows="4"
                                  placeholder="Pontos fortes, fracos, observações sobre o perfil..."></textarea>
                    </div>

                    <button class="adm-btn adm-btn-primary" onclick="saveAvaliacao()">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/></svg>
                        Guardar Avaliação
                    </button>
                </div>
            </div>
        </div>

        <!-- Tab: Entrevista -->
        <div class="adm-tab-panel" id="tab-entrevista">
            <div class="adm-card">
                <div class="adm-card-header"><h2 class="adm-card-title">Agendar / Registar Entrevista</h2></div>
                <div class="adm-card-body">
                    <div class="interview-grid">
                        <div class="adm-form-group">
                            <label class="adm-label" for="eData">Data e Hora</label>
                            <input class="adm-input" type="datetime-local" id="eData"
                                   value="<?= $c['entrevista_data'] ? date('Y-m-d\TH:i', strtotime($c['entrevista_data'])) : '' ?>">
                        </div>
                        <div class="adm-form-group">
                            <label class="adm-label" for="eFormato">Formato</label>
                            <select class="adm-select" id="eFormato">
                                <?php foreach (['Presencial','Online (Teams)','Online (Zoom)','Online (Meet)','Telefone'] as $f): ?>
                                <option value="<?= $f ?>" <?= ($c['entrevista_local'] ?? '') === $f ? 'selected' : '' ?>><?= $f ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="eLink">Link / Localização</label>
                        <input class="adm-input" type="text" id="eLink"
                               placeholder="Link da reunião ou morada..."
                               value="<?= htmlspecialchars($c['entrevista_link'] ?? '') ?>">
                    </div>
                    <div class="adm-form-group">
                        <label class="adm-label" for="eNotas">Notas da Entrevista</label>
                        <textarea class="adm-textarea" id="eNotas" rows="5"
                                  placeholder="Resumo, feedback, próximos passos..."><?= htmlspecialchars($c['entrevista_notas'] ?? '') ?></textarea>
                    </div>
                    <button class="adm-btn adm-btn-primary" onclick="saveEntrevista()">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                        Guardar Entrevista
                    </button>
                </div>
            </div>
        </div>

        <?php if (!empty($respostasVaga)): ?>
        <!-- Tab: Respostas da Vaga -->
        <div class="adm-tab-panel" id="tab-respostas">
            <div class="adm-card">
                <div class="adm-card-header"><h2 class="adm-card-title">Respostas aos Campos da Vaga</h2></div>
                <div class="adm-card-body">
                    <div style="display:grid;gap:var(--adm-sp-4)">
                        <?php foreach ($respostasVaga as $r): ?>
                        <div class="adm-detail-pair">
                            <span class="adm-detail-pair-label"><?= htmlspecialchars($r['label']) ?></span>
                            <?php if ($r['ficheiro']): ?>
                            <span class="adm-detail-pair-value">
                                <a href="/nexora/download?type=vaga_campo&candidatura_id=<?= $c['id'] ?>&campo_id=<?= $r['campo_id'] ?>"
                                   target="_blank" class="adm-btn adm-btn-outline adm-btn-sm">
                                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                                    Abrir ficheiro
                                </a>
                            </span>
                            <?php elseif ($r['valor'] !== null): ?>
                            <span class="adm-detail-pair-value" style="white-space:pre-wrap"><?= htmlspecialchars($r['valor']) ?></span>
                            <?php else: ?>
                            <span class="adm-detail-pair-value adm-text-muted">—</span>
                            <?php endif; ?>
                        </div>
                        <?php endforeach; ?>
                    </div>
                </div>
            </div>
        </div>
        <?php endif; ?>

        <!-- Tab: Notas / Timeline -->
        <div class="adm-tab-panel" id="tab-notas">
            <div class="adm-card adm-mb-6">
                <div class="adm-card-header"><h2 class="adm-card-title">Adicionar Nota</h2></div>
                <div class="adm-card-body">
                    <div class="adm-form-group" style="margin-bottom:var(--adm-sp-3)">
                        <textarea class="adm-textarea" id="notaTexto" rows="3" placeholder="Escreve uma nota sobre este candidato..."></textarea>
                    </div>
                    <button class="adm-btn adm-btn-primary" onclick="saveNota()">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
                        Adicionar Nota
                    </button>
                </div>
            </div>

            <!-- Timeline -->
            <div class="timeline" id="timeline">
                <?php foreach ($notas as $nota):
                    $dotClass = match($nota['tipo']) {
                        'entrevista' => 'timeline-dot--indigo',
                        'avaliacao'  => 'timeline-dot--yellow',
                        'aprovada'   => 'timeline-dot--green',
                        'rejeitada'  => 'timeline-dot--red',
                        'sistema'    => 'timeline-dot--gray',
                        default      => 'timeline-dot--blue',
                    };
                    $dotIcon = match($nota['tipo']) {
                        'entrevista' => '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="3" y1="10" x2="21" y2="10"/></svg>',
                        'avaliacao'  => '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>',
                        'sistema'    => '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="4"/></svg>',
                        default      => '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>',
                    };
                    $ts = strtotime($nota['created_at']);
                ?>
                <div class="timeline-item">
                    <div class="timeline-dot <?= $dotClass ?>"><?= $dotIcon ?></div>
                    <div class="timeline-body">
                        <div class="timeline-header">
                            <span class="timeline-author"><?= htmlspecialchars($nota['autor']) ?></span>
                            <span class="timeline-time"><?= date('d/m/Y H:i', $ts) ?></span>
                        </div>
                        <div class="timeline-content"><p><?= htmlspecialchars($nota['conteudo']) ?></p></div>
                    </div>
                </div>
                <?php endforeach; ?>
                <?php if (empty($notas)): ?>
                <p class="adm-text-muted adm-text-sm" style="padding-left:2.5rem">Sem notas ainda. Adiciona a primeira acima.</p>
                <?php endif; ?>
            </div>
        </div>
    </div>

    <!-- ── Sidebar ── -->
    <aside>

        <!-- Stage progress -->
        <div class="adm-card adm-mb-6">
            <div class="adm-card-header"><h2 class="adm-card-title">Fase do Processo</h2></div>
            <div class="adm-card-body" style="padding:var(--adm-sp-2) var(--adm-sp-3)">
                <div class="stage-progress" id="stageProgress">
                    <?php
                    $stageOrder = ['recebida','em_analise','entrevista','aprovada','rejeitada'];
                    $currentIdx = array_search($c['estado'], $stageOrder);
                    $stageLabels = ['Recebida','Em Análise','Entrevista','Aprovada','Rejeitada'];
                    foreach ($stageOrder as $i => $sk):
                        $cls = $i < $currentIdx ? 'done' : ($i === $currentIdx ? 'current' : '');
                    ?>
                    <div class="stage-step <?= $cls ?>" onclick="moveToStage('<?= $sk ?>')" title="Mover para <?= $stageLabels[$i] ?>">
                        <div class="stage-dot">
                            <?php if ($i < $currentIdx): ?>
                            <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
                            <?php elseif ($i === $currentIdx): ?>
                            <svg width="8" height="8" viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="12" r="6"/></svg>
                            <?php else: ?>
                            <span style="font-size:.6rem;color:var(--adm-gray-400)"><?= $i+1 ?></span>
                            <?php endif; ?>
                        </div>
                        <?= $stageLabels[$i] ?>
                    </div>
                    <?php endforeach; ?>
                </div>
            </div>
        </div>

        <!-- Score summary -->
        <div class="adm-card adm-mb-6">
            <div class="adm-card-header"><h2 class="adm-card-title">Pontuação</h2></div>
            <div class="adm-card-body">
                <div style="display:flex;align-items:center;gap:var(--adm-sp-3)">
                    <div class="star-rating readonly" id="sidebarStars">
                        <?php for ($i=1; $i<=5; $i++): ?>
                        <span class="star <?= $i <= (int)($c['score'] ?? 0) ? 'filled' : '' ?>">★</span>
                        <?php endfor; ?>
                    </div>
                    <span id="sidebarScoreNum" style="font-weight:700;font-size:1.1rem;color:<?= ($c['score'] ?? 0) > 0 ? '#92400e' : 'var(--adm-gray-300)' ?>">
                        <?= ($c['score'] ?? 0) > 0 ? (int)$c['score'] . '/5' : '—' ?>
                    </span>
                </div>
            </div>
        </div>

        <!-- Contact -->
        <div class="adm-card adm-mb-6">
            <div class="adm-card-header"><h2 class="adm-card-title">Contactar</h2></div>
            <div class="adm-card-body" style="display:flex;flex-direction:column;gap:var(--adm-sp-2)">
                <a href="mailto:<?= htmlspecialchars($c['email']) ?>?subject=Candidatura%20<?= urlencode($c['vaga_titulo'] ?? '') ?>" class="adm-btn adm-btn-outline" style="justify-content:center">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                    Enviar Email
                </a>
                <?php if ($c['telefone']): ?>
                <a href="https://wa.me/<?= preg_replace('/\D/','',$c['telefone']) ?>?text=<?= urlencode('Olá '.$c['nome'].', entrámos em contacto relativamente à sua candidatura para a vaga de '.($c['vaga_titulo'] ?? '').'.') ?>"
                   target="_blank" class="adm-btn adm-btn-outline" style="justify-content:center;background:#25d366;color:#fff;border-color:#25d366">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
                    WhatsApp
                </a>
                <?php endif; ?>
            </div>
        </div>

        <?php if ($c['estado'] === 'aprovada'): ?>
        <!-- Contratar -->
        <div class="adm-card adm-mb-6" id="cardContratar">
            <div class="adm-card-header"><h2 class="adm-card-title">Contratação</h2></div>
            <div class="adm-card-body">
                <p class="adm-text-sm" style="color:var(--adm-gray-600);margin-bottom:var(--adm-sp-4)">
                    Candidato aprovado. Ao contratar, será criado automaticamente um registo no módulo RH.
                </p>
                <button class="adm-btn adm-btn-primary" style="width:100%;justify-content:center" onclick="contratarCandidato()" id="btnContratarSidebar">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
                    Confirmar Contratação
                </button>
                <div id="contrataResultado" style="display:none;margin-top:var(--adm-sp-3);padding:var(--adm-sp-3);background:#f0fdf4;border-radius:var(--adm-radius);border:1px solid #bbf7d0"></div>
            </div>
        </div>
        <?php endif; ?>

        <!-- Quick nav -->
        <div class="adm-card">
            <div class="adm-card-header"><h2 class="adm-card-title">Navegação</h2></div>
            <div class="adm-card-body" style="display:flex;flex-direction:column;gap:var(--adm-sp-2)">
                <a href="/nexora/recrutamento/pipeline<?= $c['vaga_id'] ? '?vaga_id='.$c['vaga_id'] : '' ?>" class="adm-btn adm-btn-ghost adm-btn-sm" style="justify-content:flex-start">
                    Pipeline<?= $c['vaga_id'] ? ' desta vaga' : '' ?>
                </a>
                <?php if ($c['vaga_id']): ?>
                <a href="/nexora/recrutamento/vagas/form?id=<?= $c['vaga_id'] ?>" class="adm-btn adm-btn-ghost adm-btn-sm" style="justify-content:flex-start">
                    Editar vaga
                </a>
                <a href="/nexora/recrutamento/candidaturas?vaga_id=<?= $c['vaga_id'] ?>" class="adm-btn adm-btn-ghost adm-btn-sm" style="justify-content:flex-start">
                    Outros candidatos
                </a>
                <?php endif; ?>
            </div>
        </div>

    </aside>
</div>

<script>
const CAND_ID = <?= $id ?>;
const CSRF    = '<?= $csrf ?>';
const ADMIN   = '<?= htmlspecialchars($adminUser) ?>';

// ── Tabs ─────────────────────────────────────────────────────
function switchTab(name, btn) {
    document.querySelectorAll('.adm-tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.adm-tab').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
}

// ── Stage progress ────────────────────────────────────────────
async function moveToStage(stage) {
    try {
        const res  = await fetch('/nexora/api/candidatura_mover', {
            method:'POST', headers:{'Content-Type':'application/json'},
            body: JSON.stringify({id: CAND_ID, estado: stage, csrf: CSRF})
        });
        const data = await res.json();
        if (data.ok) { showToast('Estado actualizado'); setTimeout(() => location.reload(), 700); }
        else showToast(data.erro || 'Erro', 'error');
    } catch { showToast('Erro de ligação', 'error'); }
}

// ── Star rating ───────────────────────────────────────────────
let currentScore = <?= (int)($c['score'] ?? 0) ?>;
const scoreLabels = ['Sem avaliação','Fraco','Abaixo da média','Médio','Bom','Excelente'];

function setStar(v) {
    currentScore = v;
    document.querySelectorAll('#starRating .star').forEach((s,i) => s.classList.toggle('filled', i < v));
    document.getElementById('scoreLabel').textContent = scoreLabels[v];
}

// ── Save Avaliação ────────────────────────────────────────────
async function saveAvaliacao() {
    const nota = document.getElementById('avalNota').value.trim();
    try {
        const res  = await fetch('/nexora/api/candidatura_avaliar', {
            method:'POST', headers:{'Content-Type':'application/json'},
            body: JSON.stringify({id: CAND_ID, score: currentScore, nota, csrf: CSRF})
        });
        const data = await res.json();
        if (data.ok) {
            // Update sidebar stars
            document.querySelectorAll('#sidebarStars .star').forEach((s,i) => s.classList.toggle('filled', i < currentScore));
            document.getElementById('sidebarScoreNum').textContent = currentScore > 0 ? currentScore + '/5' : '—';
            document.getElementById('sidebarScoreNum').style.color = currentScore > 0 ? '#92400e' : 'var(--adm-gray-300)';
            document.getElementById('avalNota').value = '';
            if (nota) appendTimeline('avaliacao', nota);
            showToast('Avaliação guardada');
        } else showToast(data.erro || 'Erro', 'error');
    } catch { showToast('Erro de ligação', 'error'); }
}

// ── Save Entrevista ───────────────────────────────────────────
async function saveEntrevista() {
    const payload = {
        id: CAND_ID,
        data:    document.getElementById('eData').value,
        formato: document.getElementById('eFormato').value,
        link:    document.getElementById('eLink').value,
        notas:   document.getElementById('eNotas').value,
        csrf: CSRF
    };
    try {
        const res  = await fetch('/nexora/api/entrevista_save', {
            method:'POST', headers:{'Content-Type':'application/json'},
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.ok) { showToast('Entrevista guardada'); if (payload.notas) appendTimeline('entrevista', 'Entrevista: ' + payload.notas); }
        else showToast(data.erro || 'Erro', 'error');
    } catch { showToast('Erro de ligação', 'error'); }
}

// ── Save Nota ─────────────────────────────────────────────────
async function saveNota() {
    const txt = document.getElementById('notaTexto').value.trim();
    if (!txt) return;
    try {
        const res  = await fetch('/nexora/api/nota_save', {
            method:'POST', headers:{'Content-Type':'application/json'},
            body: JSON.stringify({id: CAND_ID, conteudo: txt, csrf: CSRF})
        });
        const data = await res.json();
        if (data.ok) {
            document.getElementById('notaTexto').value = '';
            appendTimeline('nota', txt);
            showToast('Nota adicionada');
        } else showToast(data.erro || 'Erro', 'error');
    } catch { showToast('Erro de ligação', 'error'); }
}

// ── Contratar Candidato ───────────────────────────────────────
async function contratarCandidato() {
    if (!confirm('Confirmar contratação de ' + <?= json_encode($c['nome']) ?> + '? Esta acção é irreversível.')) return;
    const btns = [document.getElementById('btnContratar'), document.getElementById('btnContratarSidebar')].filter(Boolean);
    btns.forEach(b => { b.disabled = true; b.textContent = 'A contratar...'; });
    try {
        const res  = await fetch('/nexora/api/candidatura_contratar', {
            method:'POST', headers:{'Content-Type':'application/json'},
            body: JSON.stringify({id: CAND_ID, csrf: CSRF})
        });
        const data = await res.json();
        if (data.ok) {
            const div = document.getElementById('contrataResultado');
            if (div) {
                div.style.display = 'block';
                div.innerHTML = '<strong style="color:#15803d">Contratado com sucesso!</strong><br>'
                    + (data.rh_employee_id ? '<span style="font-size:.85rem;color:#166534">Funcionário RH criado (ID: ' + data.rh_employee_id + '). '
                       + 'Agora crie o professor em <a href="/nexora/gestao-escolar/professores" style="color:#15803d">Gestão Escolar → Professores</a>.</span>'
                       : '<span style="font-size:.85rem;color:#166534">' + (data.mensagem || '') + '</span>');
            }
            btns.forEach(b => { b.disabled = true; b.style.opacity = '.5'; });
            showToast('Candidato contratado!');
            setTimeout(() => location.reload(), 2000);
        } else {
            btns.forEach(b => { b.disabled = false; b.textContent = 'Contratar'; });
            showToast(data.erro || 'Erro ao contratar', 'error');
        }
    } catch {
        btns.forEach(b => { b.disabled = false; b.textContent = 'Contratar'; });
        showToast('Erro de ligação', 'error');
    }
}

// ── Append to timeline ────────────────────────────────────────
function appendTimeline(tipo, conteudo) {
    const icons = {
        nota: '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>',
        entrevista: '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="3" y1="10" x2="21" y2="10"/></svg>',
        avaliacao: '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>',
    };
    const dotColors = { nota:'timeline-dot--blue', entrevista:'timeline-dot--indigo', avaliacao:'timeline-dot--yellow' };
    const now = new Date();
    const ts  = now.toLocaleDateString('pt-PT') + ' ' + now.toLocaleTimeString('pt-PT', {hour:'2-digit',minute:'2-digit'});

    const el = document.createElement('div');
    el.className = 'timeline-item';
    el.innerHTML = `
        <div class="timeline-dot ${dotColors[tipo] || 'timeline-dot--gray'}">${icons[tipo] || ''}</div>
        <div class="timeline-body">
            <div class="timeline-header">
                <span class="timeline-author">${ADMIN}</span>
                <span class="timeline-time">${ts}</span>
            </div>
            <div class="timeline-content"><p>${conteudo.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')}</p></div>
        </div>`;

    const tl = document.getElementById('timeline');
    tl.insertBefore(el, tl.firstChild);

    // Update tab badge
    const badge = document.querySelector('#mainTabs .adm-tab:nth-child(4) .adm-tab-badge');
    const cnt = tl.querySelectorAll('.timeline-item').length;
    if (badge) badge.textContent = cnt;
    else {
        const tab = document.querySelector('#mainTabs .adm-tab:nth-child(4)');
        const sp = document.createElement('span');
        sp.className = 'adm-tab-badge'; sp.textContent = cnt;
        tab.appendChild(sp);
    }
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
