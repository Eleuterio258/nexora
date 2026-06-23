<?php

$search = $app->request->queryString('search');
$estado = $app->request->queryEnum('estado', ['ativo', 'inativo', 'bloqueado', 'pendente']);
$page   = max(1, $app->request->queryInt('page', 1) ?? 1);
$limit  = 20;

$resp  = $app->nexora->call('GET', '/api/auth/utilizadores', null, ['search' => $search, 'estado' => $estado, 'page' => $page, 'limit' => $limit]);
$users = $resp['body']['data'] ?? [];
$meta  = $resp['body']['meta'] ?? ['total' => 0, 'page' => $page, 'limit' => $limit];
$totalPages = max(1, (int) ceil($meta['total'] / $limit));

$csrf = $app->security->csrfToken();
$pageTitle  = 'Utilizadores';
$activePage = 'utilizadores';
$breadcrumb = [['Admin', '/nexora/'], ['Administração', ''], ['Utilizadores', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Utilizadores</h1>
    <div class="adm-page-header-actions">
        <a href="/nexora/admin/utilizadores/form" class="adm-btn adm-btn-primary">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Novo Utilizador
        </a>
    </div>
</div>

<?php if ($app->request->queryString('msg') !== ''): ?>
<div class="adm-alert adm-alert--success">
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
    <?= htmlspecialchars($app->request->queryString('msg')) ?>
</div>
<?php endif; ?>

<div class="adm-card">
    <form method="get" class="adm-filter-bar">
        <div class="adm-search-wrap">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <input class="adm-input" type="search" name="search" placeholder="Pesquisar nome ou email…" value="<?= htmlspecialchars($search) ?>">
        </div>
        <select class="adm-select" name="estado" style="width:160px">
            <option value="">Todos os estados</option>
            <option value="ativo"     <?= $estado === 'ativo'     ? 'selected' : '' ?>>Ativos</option>
            <option value="inativo"   <?= $estado === 'inativo'   ? 'selected' : '' ?>>Inativos</option>
            <option value="bloqueado" <?= $estado === 'bloqueado' ? 'selected' : '' ?>>Bloqueados</option>
            <option value="pendente"  <?= $estado === 'pendente'  ? 'selected' : '' ?>>Pendentes</option>
        </select>
        <button type="submit" class="adm-btn adm-btn-outline adm-btn-sm">Filtrar</button>
        <span class="adm-filter-count"><?= $meta['total'] ?> utilizador<?= $meta['total'] != 1 ? 'es' : '' ?></span>
    </form>

    <?php if ($users): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Nome</th>
                    <th>Email</th>
                    <th>Telefone</th>
                    <th>Estado</th>
                    <th>Último login</th>
                    <th>Criado em</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($users as $u):
                $estadoBadge = match ($u['estado']) {
                    'ativo'     => ['adm-badge--green',  'Ativo'],
                    'bloqueado' => ['adm-badge--red',    'Bloqueado'],
                    'pendente'  => ['adm-badge--yellow', 'Pendente'],
                    default     => ['adm-badge--gray',   'Inativo'],
                };
            ?>
            <tr>
                <td><div class="adm-fw-600"><?= htmlspecialchars($u['nome']) ?></div></td>
                <td><?= htmlspecialchars($u['email']) ?></td>
                <td><?= htmlspecialchars($u['telefone'] ?? '—') ?></td>
                <td><span class="adm-badge <?= $estadoBadge[0] ?>"><?= $estadoBadge[1] ?></span></td>
                <td class="adm-text-muted"><?= $u['ultimo_login_em'] ? date('d/m/Y H:i', strtotime($u['ultimo_login_em'])) : '—' ?></td>
                <td class="adm-text-muted"><?= date('d/m/Y', strtotime($u['created_at'])) ?></td>
                <td>
                    <div class="adm-actions">
                        <a href="/nexora/admin/utilizadores/form?id=<?= $u['id'] ?>" class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Editar">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                            </svg>
                        </a>
                        <?php if ($u['estado'] !== 'ativo'): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Ativar" style="color:var(--adm-green)"
                                onclick="mudarEstado(<?= $u['id'] ?>, 'activar', '<?= htmlspecialchars(addslashes($u['nome'])) ?>')">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18.36 6.64a9 9 0 1 1-12.73 0"/><line x1="12" y1="2" x2="12" y2="12"/></svg>
                        </button>
                        <?php endif; ?>
                        <?php if ($u['estado'] !== 'bloqueado'): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Bloquear" style="color:var(--adm-red)"
                                onclick="mudarEstado(<?= $u['id'] ?>, 'bloquear', '<?= htmlspecialchars(addslashes($u['nome'])) ?>')">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                        </button>
                        <?php endif; ?>
                        <?php if ($u['estado'] !== 'inativo'): ?>
                        <button class="adm-btn adm-btn-ghost adm-btn-sm adm-btn-icon" title="Desativar" style="color:var(--adm-gray-400)"
                                onclick="mudarEstado(<?= $u['id'] ?>, 'desactivar', '<?= htmlspecialchars(addslashes($u['nome'])) ?>')">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/></svg>
                        </button>
                        <?php endif; ?>
                    </div>
                </td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>

    <?php if ($totalPages > 1): ?>
    <div style="display:flex;justify-content:center;gap:var(--adm-sp-3);padding:var(--adm-sp-5)">
        <?php if ($page > 1): ?>
        <a href="<?= htmlspecialchars($app->view->queryLink('/nexora/admin/utilizadores', $app->request->query(), ['page' => $page - 1])) ?>" class="adm-btn adm-btn-outline adm-btn-sm">« Anterior</a>
        <?php endif; ?>
        <span class="adm-text-sm adm-text-muted" style="align-self:center">Página <?= $page ?> de <?= $totalPages ?></span>
        <?php if ($page < $totalPages): ?>
        <a href="<?= htmlspecialchars($app->view->queryLink('/nexora/admin/utilizadores', $app->request->query(), ['page' => $page + 1])) ?>" class="adm-btn adm-btn-outline adm-btn-sm">Seguinte »</a>
        <?php endif; ?>
    </div>
    <?php endif; ?>

    <?php else: ?>
    <div class="adm-empty">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/>
            <path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>
        </svg>
        <p class="adm-empty-title">Nenhum utilizador encontrado</p>
    </div>
    <?php endif; ?>
</div>

<script>
function mudarEstado(id, acao, nome) {
    const labels = {activar: 'Ativar', bloquear: 'Bloquear', desactivar: 'Desativar'};
    openConfirm(
        labels[acao] + ' utilizador',
        labels[acao] + ' "' + nome + '"?' + (acao === 'bloquear' ? ' Isto também termina todas as sessões activas.' : ''),
        async () => {
            try {
                const res  = await fetch('/nexora/api/utilizador_estado', {
                    method: 'POST',
                    headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({id, acao, csrf: '<?= $csrf ?>'})
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
