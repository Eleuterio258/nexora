<?php

$modulos = require dirname(__DIR__) . '/partials/modules.php';

$requestedModule = $app->request->queryString('modulo');
$modulo   = isset($modulos[$requestedModule]) ? $requestedModule : '';
$acao     = $app->request->queryString('acao');
$entidade = $app->request->queryString('entidade');
$userId   = $app->request->queryInt('user_id') ?: '';
$page     = max(1, $app->request->queryInt('page', 1) ?? 1);
$limit    = 50;

$resp = $app->nexora->call('GET', '/api/audit-logs', null, [
    'modulo'   => $modulo,
    'acao'     => $acao,
    'entidade' => $entidade,
    'user_id'  => $userId,
    'page'     => $page,
    'limit'    => $limit,
]);
$logs = $resp['body']['data'] ?? [];
$meta = $resp['body']['meta'] ?? ['total' => 0, 'page' => $page, 'limit' => $limit];
$totalPages = max(1, (int) ceil($meta['total'] / $limit));

$pageTitle  = 'Auditoria';
$activePage = 'auditoria';
$breadcrumb = [['Admin', '/nexora/'], ['Administração', ''], ['Auditoria', '']];

include dirname(__DIR__) . '/layouts/top.php';
?>

<div class="adm-page-header">
    <h1 class="adm-page-title">Auditoria</h1>
</div>

<div class="adm-card">
    <form method="get" class="adm-filter-bar">
        <select class="adm-select" name="modulo" style="width:200px">
            <option value="">Todos os módulos</option>
            <?php foreach ($modulos as $key => $info): ?>
            <option value="<?= $key ?>" <?= $modulo === $key ? 'selected' : '' ?>><?= htmlspecialchars($info['nome']) ?></option>
            <?php endforeach; ?>
        </select>
        <input class="adm-input" type="text" name="acao" placeholder="Ação (ex: criar, editar)" value="<?= htmlspecialchars($acao) ?>" style="max-width:200px">
        <input class="adm-input" type="text" name="entidade" placeholder="Entidade" value="<?= htmlspecialchars($entidade) ?>" style="max-width:160px">
        <input class="adm-input" type="number" name="user_id" placeholder="User ID" value="<?= htmlspecialchars((string) $userId) ?>" style="max-width:120px">
        <button type="submit" class="adm-btn adm-btn-outline adm-btn-sm">Filtrar</button>
        <span class="adm-filter-count"><?= $meta['total'] ?> registo<?= $meta['total'] != 1 ? 's' : '' ?></span>
    </form>

    <?php if ($logs): ?>
    <div class="adm-table-wrap">
        <table class="adm-table">
            <thead>
                <tr>
                    <th>Data/Hora</th>
                    <th>Utilizador</th>
                    <th>Módulo</th>
                    <th>Entidade</th>
                    <th>Ação</th>
                    <th>Detalhes</th>
                    <th>IP</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($logs as $l):
                $modInfo = $modulos[$l['modulo']] ?? null;
                $detalhes = $l['detalhes'] ?? null;
            ?>
            <tr>
                <td class="adm-text-muted"><?= date('d/m/Y H:i:s', strtotime($l['created_at'])) ?></td>
                <td><?= $l['user_id'] ?? '—' ?></td>
                <td>
                    <?php if ($modInfo): ?>
                    <span class="adm-badge" style="background:<?= htmlspecialchars($modInfo['cor']) ?>22;color:<?= htmlspecialchars($modInfo['cor']) ?>"><?= htmlspecialchars($modInfo['nome']) ?></span>
                    <?php else: ?>
                    <span class="adm-badge adm-badge--gray"><?= htmlspecialchars($l['modulo']) ?></span>
                    <?php endif; ?>
                </td>
                <td class="adm-text-muted"><?= htmlspecialchars($l['entidade']) ?><?= $l['entidade_id'] ? ' #' . $l['entidade_id'] : '' ?></td>
                <td><?= htmlspecialchars($l['acao']) ?></td>
                <td>
                    <?php if (! empty($detalhes)): ?>
                    <details>
                        <summary class="adm-text-sm" style="cursor:pointer;color:var(--adm-blue)">Ver detalhes</summary>
                        <pre class="adm-text-xs" style="white-space:pre-wrap;margin-top:var(--adm-sp-2);max-width:360px"><?= htmlspecialchars(json_encode($detalhes, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT)) ?></pre>
                    </details>
                    <?php else: ?>
                    <span class="adm-text-muted">—</span>
                    <?php endif; ?>
                </td>
                <td class="adm-text-muted"><?= htmlspecialchars($l['ip_address'] ?? '—') ?></td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>

    <?php if ($totalPages > 1): ?>
    <div style="display:flex;justify-content:center;gap:var(--adm-sp-3);padding:var(--adm-sp-5)">
        <?php if ($page > 1): ?>
        <a href="<?= htmlspecialchars($app->view->queryLink('/nexora/admin/auditoria', $app->request->query(), ['page' => $page - 1])) ?>" class="adm-btn adm-btn-outline adm-btn-sm">« Anterior</a>
        <?php endif; ?>
        <span class="adm-text-sm adm-text-muted" style="align-self:center">Página <?= $page ?> de <?= $totalPages ?></span>
        <?php if ($page < $totalPages): ?>
        <a href="<?= htmlspecialchars($app->view->queryLink('/nexora/admin/auditoria', $app->request->query(), ['page' => $page + 1])) ?>" class="adm-btn adm-btn-outline adm-btn-sm">Seguinte »</a>
        <?php endif; ?>
    </div>
    <?php endif; ?>

    <?php else: ?>
    <div class="adm-empty">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
        </svg>
        <p class="adm-empty-title">Nenhum registo de auditoria encontrado</p>
    </div>
    <?php endif; ?>
</div>

<?php include dirname(__DIR__) . '/layouts/bottom.php'; ?>
