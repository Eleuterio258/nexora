<!DOCTYPE html>
<html lang="pt">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="E258Tech — Vagas de estágio em Maputo. Candidata-te agora.">
    <title>E258Tech | Vagas</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/css/styles.css">
    <link rel="stylesheet" href="/assets/css/vagas.css">
</head>

<body>

    <?php include 'src/View/templates/partials/nav.php'; ?>

    <!-- ═══════════════ HERO ═══════════════ -->
    <section class="vagas-hero">
        <div class="container">

            <div class="vagas-hero-eyebrow">
                <?php if ($totalVagas > 0): ?>
                <span class="vagas-pill-live">
                    <span class="vagas-pill-dot"></span>
                    <?php echo $totalVagas ?> vaga<?php echo $totalVagas !== 1 ? 's' : '' ?> em aberto
                </span>
                <?php else: ?>
                <span class="vagas-pill-live vagas-pill-live--closed">
                    Nenhuma vaga disponível no momento
                </span>
                <?php endif; ?>
            </div>

            <h1 class="vagas-hero-title">Faz parte da equipa<br><span class="vagas-hero-accent">e258tech</span></h1>
            <p class="vagas-hero-sub">Estágios presenciais em Maputo. Cresce connosco.</p>

            <?php if ($totalVagas > 0): ?>
            <div class="vagas-tabs" role="tablist">
                <?php foreach ($vagas as $i => $v): $slug = $view->vacancySlug($v['area']); ?>
                    <button class="vaga-tab <?php echo $i === 0 ? 'active' : '' ?>"
                        role="tab"
                        aria-selected="<?php echo $i === 0 ? 'true' : 'false' ?>"
                        aria-controls="vaga-<?php echo $slug ?>"
                        onclick="showVaga('<?php echo $slug ?>', this)">
                        <?php echo htmlspecialchars($v['area']) ?>
                    </button>
                <?php endforeach; ?>
            </div>
            <?php endif; ?>

        </div>
    </section>

    <?php if ($totalVagas === 0): ?>
    <!-- ═══════════════ ESTADO VAZIO ═══════════════ -->
    <div class="container">
        <div class="vagas-empty">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                <path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>
            </svg>
            <h2>Não há vagas abertas de momento</h2>
            <p>Estamos sempre à procura de talento. Deixa o teu contacto e avisamos quando surgirem novas oportunidades.</p>
            <a href="mailto:info@e258tech.tech" class="btn-primary" style="display:inline-flex;align-items:center;gap:0.5rem;margin-top:0.5rem;">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                Enviar candidatura espontânea
            </a>
        </div>
    </div>
    <?php else: ?>
    <!-- ═══════════════ CONTEÚDO ═══════════════ -->
    <div class="container">
        <div class="vagas-layout">

            <!-- Painéis das vagas -->
            <div class="vagas-panels">
                <?php foreach ($vagas as $i => $v):
                        $slug     = $view->vacancySlug($v['area']);
                        $prazoFmt = $view->vacancyDeadline($v['prazo'] ?? null);
                        $dias     = isset($v['dias_restantes']) ? (int) $v['dias_restantes'] : null;
                        $vagaData = json_encode([
                            'id'          => (int) $v['id'],
                            'titulo'      => $v['titulo'],
                            'local'       => $v['local'],
                            'regime'      => $v['regime'],
                            'tipo'        => $v['tipo'],
                            'num_vagas'   => (int) $v['num_vagas'],
                            'prazo'       => $prazoFmt,
                            'prazo_label' => $view->vacancyDeadlineLabel($prazoFmt, $dias),
                            'prazo_class' => $view->vacancyDeadlineClass($dias),
                        ]);
                ?>
                    <div class="vaga-panel <?php echo $i === 0 ? 'active' : '' ?>"
                        id="vaga-<?php echo $slug ?>"
                        role="tabpanel"
                        data-vaga="<?php echo htmlspecialchars($vagaData) ?>">

                        <div class="vaga-header">
                            <div class="vaga-header-top">
                                <span class="vaga-badge">
                                    <svg width="8" height="8" viewBox="0 0 8 8" fill="currentColor">
                                        <circle cx="4" cy="4" r="4" />
                                    </svg>
                                    <?php echo htmlspecialchars($v['tipo']) ?> · Em aberto
                                </span>
                                <span class="vaga-prazo-badge<?php echo $view->vacancyDeadlineClass($dias) ?>">
                                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <rect x="3" y="4" width="18" height="18" rx="2" />
                                        <line x1="16" y1="2" x2="16" y2="6" />
                                        <line x1="8" y1="2" x2="8" y2="6" />
                                        <line x1="3" y1="10" x2="21" y2="10" />
                                    </svg>
                                    <?php echo $view->vacancyDeadlineLabel($prazoFmt, $dias) ?>
                                </span>
                            </div>
                            <h1 class="vaga-title"><?php echo htmlspecialchars($v['titulo']) ?></h1>
                            <div class="vaga-meta">
                                <span class="vaga-meta-item">
                                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
                                        <circle cx="12" cy="10" r="3" />
                                    </svg>
                                    <?php echo htmlspecialchars($v['local']) ?>
                                </span>
                                <span class="vaga-meta-item">
                                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <rect x="2" y="3" width="20" height="14" rx="2" />
                                        <line x1="8" y1="21" x2="16" y2="21" />
                                        <line x1="12" y1="17" x2="12" y2="21" />
                                    </svg>
                                    <?php echo htmlspecialchars($v['regime']) ?>
                                </span>
                                <span class="vaga-meta-item">
                                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <circle cx="12" cy="12" r="10" />
                                        <polyline points="12 6 12 12 16 14" />
                                    </svg>
                                    Tempo inteiro
                                </span>
                                <span class="vaga-meta-item">
                                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                                        <circle cx="9" cy="7" r="4" />
                                    </svg>
                                    <?php echo (int)$v['num_vagas'] ?> posição<?php echo (int)$v['num_vagas'] > 1 ? 'ões' : '' ?>
                                </span>
                            </div>
                        </div>

                        <!-- CTA inline mobile -->
                        <a href="#sidebar-form" class="btn-cta-inline">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <line x1="22" y1="2" x2="11" y2="13" />
                                <polygon points="22 2 15 22 11 13 2 9 22 2" />
                            </svg>
                            Candidatar-me agora
                        </a>

                        <?php if ($v['descricao']): ?>
                            <div class="vaga-section">
                                <h2 class="vaga-section-title">Sobre a e258tech</h2>
                                <p class="vaga-text"><?php echo htmlspecialchars($v['descricao']) ?></p>
                            </div>
                        <?php endif; ?>

                        <?php if ($v['sobre_funcao']): ?>
                            <div class="vaga-section">
                                <h2 class="vaga-section-title">Sobre a Função</h2>
                                <p class="vaga-text"><?php echo htmlspecialchars($v['sobre_funcao']) ?></p>
                            </div>
                        <?php endif; ?>

                        <?php if ($v['responsabilidades']): ?>
                            <div class="vaga-section">
                                <h2 class="vaga-section-title">Principais Responsabilidades</h2>
                                <ul class="vaga-list">
                                    <?php foreach ($v['responsabilidades'] as $r): ?>
                                        <li><?php echo htmlspecialchars($r) ?></li>
                                    <?php endforeach; ?>
                                </ul>
                            </div>
                        <?php endif; ?>

                        <?php if ($v['req_obrigatorios'] || $v['req_preferenciais']): ?>
                            <div class="vaga-section">
                                <h2 class="vaga-section-title">Requisitos</h2>
                                <div class="requisitos-grid">
                                    <div>
                                        <p class="req-col-title obrigatorio">✓ Obrigatórios</p>
                                        <?php foreach ($v['req_obrigatorios'] as $r): ?>
                                            <div class="req-item">
                                                <span class="req-check green"><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg></span>
                                                <?php echo htmlspecialchars($r) ?>
                                            </div>
                                        <?php endforeach; ?>
                                    </div>
                                    <div>
                                        <p class="req-col-title preferencial">○ Preferenciais</p>
                                        <?php foreach ($v['req_preferenciais'] as $r): ?>
                                            <div class="req-item">
                                                <span class="req-check yellow"><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><circle cx="12" cy="12" r="4"/></svg></span>
                                                <?php echo htmlspecialchars($r) ?>
                                            </div>
                                        <?php endforeach; ?>
                                    </div>
                                </div>
                            </div>
                        <?php endif; ?>

                        <?php if ($v['oferece']): ?>
                            <div class="vaga-section">
                                <h2 class="vaga-section-title">O que Oferecemos</h2>
                                <div class="oferece-grid">
                                    <?php foreach ($v['oferece'] as $o): ?>
                                        <div class="oferece-item">
                                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
                                            <?php echo htmlspecialchars($o) ?>
                                        </div>
                                    <?php endforeach; ?>
                                </div>
                            </div>
                        <?php endif; ?>

                    </div><!-- /vaga-<?php echo $slug ?> -->
                <?php endforeach; ?>
            </div><!-- /vagas-panels -->

            <!-- ═══════════════ SIDEBAR ═══════════════ -->
            <aside class="vaga-sidebar" id="sidebar-form">

                <!-- Detalhes dinâmicos -->
                <div id="sidebar-details" class="sidebar-box">
                    <p class="sidebar-box-title">Detalhes da Vaga</p>
                    <div class="sd-row">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
                        <span class="sd-label">Localização</span>
                        <span class="sd-value" id="sd-local">—</span>
                    </div>
                    <div class="sd-row">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
                        <span class="sd-label">Regime</span>
                        <span class="sd-value" id="sd-regime">—</span>
                    </div>
                    <div class="sd-row">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                        <span class="sd-label">Tipo</span>
                        <span class="sd-value" id="sd-tipo">—</span>
                    </div>
                    <div class="sd-row">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                        <span class="sd-label">Vagas</span>
                        <span class="sd-value" id="sd-vagas">—</span>
                    </div>
                    <div class="sd-row sd-row--prazo">
                        <svg id="sd-prazo-icon" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                        <span class="sd-label">Prazo</span>
                        <span class="sd-value" id="sd-prazo">—</span>
                    </div>
                </div>

                <!-- Formulário -->
                <div class="sidebar-box">
                    <div class="form-msg" id="form-msg"></div>

                    <form id="form-candidatura" enctype="multipart/form-data" novalidate>
                        <input type="hidden" name="csrf_token" value="<?= $csrf ?>">
                        <input type="hidden" name="vaga_id" id="f-vaga-id" value="">
                        <input type="hidden" name="vaga_titulo" id="f-vaga-titulo" value="">

                        <div class="form-group">
                            <label for="f-nome">Nome completo <span class="req-star">*</span></label>
                            <input type="text" id="f-nome" name="nome" required maxlength="150" placeholder="O seu nome">
                        </div>
                        <div class="form-group">
                            <label for="f-email">Email <span class="req-star">*</span></label>
                            <input type="email" id="f-email" name="email" required maxlength="255" placeholder="email@exemplo.com">
                        </div>
                        <div class="form-group">
                            <label for="f-telefone">Telefone</label>
                            <input type="tel" id="f-telefone" name="telefone" maxlength="30" placeholder="+258 84 000 0000">
                        </div>
                        <div class="form-group">
                            <label>CV (PDF, máx. 3 MB) <span class="req-star">*</span></label>
                            <label class="file-label" id="cv-label">
                                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                                    <polyline points="17 8 12 3 7 8" />
                                    <line x1="12" y1="3" x2="12" y2="15" />
                                </svg>
                                <span id="cv-name">Escolher ficheiro…</span>
                                <input type="file" name="cv" id="f-cv" accept=".pdf,application/pdf">
                            </label>
                        </div>
                        <div class="form-group">
                            <label>Carta de motivação <span class="form-optional">(PDF/Word, máx. 3 MB)</span></label>
                            <label class="file-label" id="carta-label">
                                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                                    <polyline points="14 2 14 8 20 8" />
                                    <line x1="16" y1="13" x2="8" y2="13" />
                                    <line x1="16" y1="17" x2="8" y2="17" />
                                </svg>
                                <span id="carta-name">Escolher ficheiro…</span>
                                <input type="file" name="carta_ficheiro" id="f-carta" accept=".pdf,.doc,.docx,application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document">
                            </label>
                        </div>

                        <button type="submit" class="btn-candidatar" id="btn-submit">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <line x1="22" y1="2" x2="11" y2="13" />
                                <polygon points="22 2 15 22 11 13 2 9 22 2" />
                            </svg>
                            Enviar Candidatura
                        </button>
                    </form>

                    <p class="form-disclaimer">Apenas candidatos seleccionados serão contactados.</p>
                </div>

            </aside>

        </div><!-- /vagas-layout -->
    </div>
    <?php endif; ?>

    <!-- ═══════════════ FOOTER ═══════════════ -->
    <footer class="vagas-footer">
        <div class="container vagas-footer-inner">
            <div class="vagas-footer-info">
                <img src="/assets/images/e258tech-logo.png" alt="E258Tech">
                <div class="vagas-footer-divider"></div>
                <p>Maputo, Moçambique</p>
            </div>
            <a href="https://e258tech.tech">e258tech.tech</a>
        </div>
    </footer>

    <script>
        const VAGAS = {};
        <?php foreach ($vagas as $v): $slug = $view->vacancySlug($v['area']); ?>
            VAGAS[<?php echo json_encode($slug) ?>] = <?php echo json_encode([
                'id'          => (int)$v['id'],
                'titulo'      => $v['titulo'],
                'local'       => $v['local'],
                'regime'      => $v['regime'],
                'tipo'        => $v['tipo'],
                'num_vagas'   => (int)$v['num_vagas'],
                'prazo'       => $view->vacancyDeadline($v['prazo'] ?? null),
                'prazo_label' => $view->vacancyDeadlineLabel($view->vacancyDeadline($v['prazo'] ?? null), isset($v['dias_restantes']) ? (int)$v['dias_restantes'] : null),
                'prazo_class' => $view->vacancyDeadlineClass(isset($v['dias_restantes']) ? (int)$v['dias_restantes'] : null),
            ]) ?>;
        <?php endforeach; ?>

        function updateSidebar(key) {
            const d = VAGAS[key];
            if (!d) return;
            document.getElementById('sd-local').textContent  = d.local;
            document.getElementById('sd-regime').textContent = d.regime;
            document.getElementById('sd-tipo').textContent   = d.tipo + ' · Tempo inteiro';
            document.getElementById('sd-vagas').textContent  = d.num_vagas + ' posição' + (d.num_vagas > 1 ? 'ões' : '');
            const prazoEl  = document.getElementById('sd-prazo');
            const prazoRow = document.querySelector('.sd-row--prazo');
            prazoEl.textContent = d.prazo_label || d.prazo || 'Em aberto';
            if (prazoRow) {
                prazoRow.classList.remove('prazo--aviso', 'prazo--urgente');
                if (d.prazo_class) prazoRow.classList.add(d.prazo_class.trim());
            }
            document.getElementById('f-vaga-id').value     = d.id;
            document.getElementById('f-vaga-titulo').value = d.titulo;
        }

        function showVaga(key, btn) {
            document.querySelectorAll('.vaga-panel').forEach(p => {
                p.classList.remove('active');
                p.setAttribute('aria-hidden', 'true');
            });
            document.querySelectorAll('.vaga-tab').forEach(b => {
                b.classList.remove('active');
                b.setAttribute('aria-selected', 'false');
            });
            document.getElementById('vaga-' + key).classList.add('active');
            document.getElementById('vaga-' + key).removeAttribute('aria-hidden');
            btn.classList.add('active');
            btn.setAttribute('aria-selected', 'true');
            updateSidebar(key);
            const msg = document.getElementById('form-msg');
            msg.style.display = 'none';
            msg.className = 'form-msg';
        }

        const firstKey = Object.keys(VAGAS)[0];
        if (firstKey) updateSidebar(firstKey);

        function filePreview(inputId, spanId, labelId) {
            document.getElementById(inputId).addEventListener('change', function() {
                const name = this.files[0]?.name;
                document.getElementById(spanId).textContent = name || 'Escolher ficheiro…';
                document.getElementById(labelId).classList.toggle('has-file', !!name);
            });
        }
        filePreview('f-cv', 'cv-name', 'cv-label');
        filePreview('f-carta', 'carta-name', 'carta-label');

        document.getElementById('form-candidatura').addEventListener('submit', async function(e) {
            e.preventDefault();
            const btn = document.getElementById('btn-submit');
            const msg = document.getElementById('form-msg');

            btn.disabled = true;
            btn.innerHTML = `<svg class="spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg> A enviar…`;
            msg.style.display = 'none';

            try {
                const res = await fetch('/api/candidatura', {
                    method: 'POST',
                    body: new FormData(this)
                });
                const data = await res.json();

                if (data.sucesso) {
                    msg.className = 'form-msg sucesso';
                    msg.innerHTML = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg> ${data.sucesso}`;
                    this.reset();
                    document.getElementById('cv-name').textContent = 'Escolher ficheiro…';
                    document.getElementById('carta-name').textContent = 'Escolher ficheiro…';
                    document.getElementById('cv-label').classList.remove('has-file');
                    document.getElementById('carta-label').classList.remove('has-file');
                } else {
                    msg.className = 'form-msg erro';
                    msg.innerHTML = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg> ${data.erro || 'Erro ao enviar candidatura.'}`;
                }
            } catch {
                msg.className = 'form-msg erro';
                msg.textContent = 'Erro de ligação. Tente novamente.';
            }

            msg.style.display = 'flex';
            btn.disabled = false;
            btn.innerHTML = `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg> Enviar Candidatura`;
        });
    </script>

</body>
</html>
