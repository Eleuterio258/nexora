<?php

$resp   = $app->nexora->call('GET', '/api/auth/cargos');
$cargos = $resp['body'] ?? [];

$csrf       = $app->security->csrfToken();
$canGerirPerfis = $app->session->can('autorizacao', 'gerir_perfis');
$pageTitle  = 'Cargos & Permissões';
$activePage = 'cargos';
$breadcrumb = [['Admin', '/nexora/'], ['Administração', ''], ['Cargos & Permissões', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Cargos &amp; Permissões</h1>
    <?php if ($canGerirPerfis): ?>
    <div class="adm-page-header-actions">
        <a href="/nexora/admin/cargos/form" class="adm-btn adm-btn-primary">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Novo Cargo
        </a>
    </div>
    <?php endif; ?>
</div>

<?php if ($app->request->queryString('msg') !== ''): ?>
<div class="adm-alert adm-alert--success">
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
    <?= htmlspecialchars($app->request->queryString('msg')) ?>
</div>
<?php endif; ?>

<div class="adm-card">
    <?php if ($cargos): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Nome</th>
                    <th>Descrição</th>
                    <th>Estado</th>
                    <th>Criado em</th>
                    <?php if ($canGerirPerfis): ?><th>Ações</th><?php endif; ?>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($cargos as $c): ?>
            <tr>
                <td><div class="adm-fw-600"><?= htmlspecialchars($c['nome']) ?></div></td>
                <td class="adm-text-muted"><?= htmlspecialchars($c['descricao'] ?? '—') ?></td>
                <td>
                    <?php if (! empty($c['ativo'])): ?>
                    <span class="adm-badge adm-badge--green">Ativo</span>
                    <?php else: ?>
                    <span class="adm-badge adm-badge--gray">Inativo</span>
                    <?php endif; ?>
                </td>
                <td class="adm-text-muted"><?= date('d/m/Y', strtotime($c['created_at'])) ?></td>
                <?php if ($canGerirPerfis): ?>
                <td>
                    <div class="adm-actions">
                        <a href="/nexora/admin/cargos/form?id=<?= $app->id->encode((int)$c['id']) ?>" class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Editar">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                            </svg>
                        </a>
                        <?php if (! empty($c['ativo'])): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Desativar" style="color:var(--adm-gray-400)"
                                onclick="mudarEstadoCargo(<?= $c['id'] ?>, false, '<?= htmlspecialchars(addslashes($c['nome'])) ?>')">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/></svg>
                        </button>
                        <?php else: ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Ativar" style="color:var(--adm-green)"
                                onclick="mudarEstadoCargo(<?= $c['id'] ?>, true, '<?= htmlspecialchars(addslashes($c['nome'])) ?>')">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18.36 6.64a9 9 0 1 1-12.73 0"/><line x1="12" y1="2" x2="12" y2="12"/></svg>
                        </button>
                        <?php endif; ?>
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
            <path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/>
        </svg>
        <p class="adm-empty-title">Nenhum cargo criado</p>
    </div>
    <?php endif; ?>
</div>

<script>
function mudarEstadoCargo(id, ativar, nome) {
    const acao = ativar ? 'Ativar' : 'Desativar';
    openConfirm(
        acao + ' cargo',
        acao + ' o cargo "' + nome + '"?',
        async () => {
            try {
                const res  = await fetch('/nexora/api/cargo_estado', {
                    method: 'POST',
                    headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id, ativo: ativar, csrf: '<?= $csrf ?>'})
                });
                const data = await res.json();
                if (data.ok) {
                    showToast('Estado atualizado');
                    setTimeout(() => location.reload(), 800);
                } else {
                    showToast(data.error || 'Erro', 'error');
                }
            } catch {
                showToast('Erro de ligação', 'error');
            }
        }
    );
}
</script>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
