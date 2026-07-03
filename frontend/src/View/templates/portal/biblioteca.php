<?php
declare(strict_types=1);

$pageTitle  = 'Biblioteca';
$activePage = 'biblioteca';

$_bibBody    = $portalData['biblioteca']['body'] ?? [];
$alunoInfo   = $portalData['me']['body'] ?? [];

// Suporta resposta paginada {records,total,...} e array plano
$emprestimos  = isset($_bibBody['records']) ? ($_bibBody['records'] ?? []) : $_bibBody;
$totalPagesBib= $_bibBody['paginas'] ?? 1;
$currentPageBib = (int)($_GET['page'] ?? 1);

$filtroStatus = $_GET['status'] ?? '';

$activos   = array_filter($emprestimos, fn($e) => in_array($e['status'] ?? '', ['emprestado','atrasado'], true));
$devolvidos= array_filter($emprestimos, fn($e) => ($e['status'] ?? '') === 'devolvido');
$atrasados = array_filter($emprestimos, fn($e) => ($e['status'] ?? '') === 'atrasado');

include dirname(__FILE__) . '/layout_top.php';
?>

<!-- Stats -->
<div class="portal-stats" style="margin-bottom:1rem">
    <div class="portal-stat">
        <span class="portal-stat-label">Emprestados</span>
        <span class="portal-stat-value"><?= count($activos) ?></span>
        <span class="portal-stat-sub">em curso</span>
    </div>
    <?php if (count($atrasados) > 0): ?>
    <div class="portal-stat">
        <span class="portal-stat-label">Em atraso</span>
        <span class="portal-stat-value" style="color:#B91C1C"><?= count($atrasados) ?></span>
        <span class="portal-stat-sub" style="color:#B91C1C">devolver urgente</span>
    </div>
    <?php endif; ?>
    <div class="portal-stat">
        <span class="portal-stat-label">Devolvidos</span>
        <span class="portal-stat-value"><?= count($devolvidos) ?></span>
        <span class="portal-stat-sub">histórico</span>
    </div>
</div>

<!-- Filtros -->
<div style="display:flex;gap:.4rem;flex-wrap:wrap;margin-bottom:.75rem">
    <?php foreach (['' => 'Todos', 'emprestado' => 'Em curso', 'atrasado' => 'Em atraso', 'devolvido' => 'Devolvidos'] as $val => $label): ?>
    <a href="/portal/aluno/biblioteca<?= $val ? "?status=$val" : '' ?>"
       style="padding:.35rem .85rem;border-radius:20px;font-size:.8rem;font-weight:600;text-decoration:none;
              background:<?= $filtroStatus === $val ? '#0EA5E9' : '#fff' ?>;
              color:<?= $filtroStatus === $val ? '#fff' : '#334155' ?>;
              border:1.5px solid <?= $filtroStatus === $val ? '#0EA5E9' : '#CBD5E1' ?>">
        <?= $label ?>
    </a>
    <?php endforeach; ?>
</div>

<!-- Lista de empréstimos -->
<?php if (empty($emprestimos)): ?>
<div class="portal-card">
    <div class="portal-empty">
        <i class="fa-solid fa-book-open"></i>
        <p>Nenhum empréstimo registado.</p>
    </div>
</div>
<?php else: ?>

<?php
$lista = $filtroStatus ? array_filter($emprestimos, fn($e) => ($e['status'] ?? '') === $filtroStatus) : $emprestimos;
?>

<?php if (count($atrasados) > 0 && $filtroStatus !== 'devolvido'): ?>
<div style="background:#FEE2E2;border:1px solid #FECACA;border-radius:10px;padding:.75rem 1rem;margin-bottom:.85rem;
            display:flex;align-items:center;gap:.6rem;font-size:.85rem;color:#B91C1C">
    <i class="fa-solid fa-triangle-exclamation"></i>
    <strong>Atenção:</strong> Tem <?= count($atrasados) ?> livro(s) com devolução em atraso. Devolva o mais depressa possível para evitar penalizações.
</div>
<?php endif; ?>

<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:1rem">
<?php foreach ($lista as $e): ?>
<?php
$status = $e['status'] ?? 'emprestado';
$hoje = date('Y-m-d');
$prevista = $e['devolucao_prevista'] ?? null;
$diasRestantes = $prevista ? (int)ceil((strtotime($prevista) - time()) / 86400) : null;

$statusBadge = match($status) {
    'emprestado' => ['badge-blue',   'Emprestado'],
    'atrasado'   => ['badge-red',    'Em atraso'],
    'devolvido'  => ['badge-green',  'Devolvido'],
    'perdido'    => ['badge-gray',   'Perdido'],
    default      => ['badge-gray',    ucfirst($status)],
};
?>
<div style="background:#fff;border-radius:12px;border:1px solid #E0F2FE;overflow:hidden;display:flex;flex-direction:column">
    <!-- Capa do livro -->
    <div style="height:120px;background:linear-gradient(135deg,#0C4A6E,#0EA5E9);display:flex;align-items:center;justify-content:center;padding:1rem;position:relative">
        <?php if (!empty($e['capa_url'])): ?>
        <img src="<?= htmlspecialchars($e['capa_url']) ?>" style="height:100%;border-radius:4px;object-fit:cover;box-shadow:0 4px 12px rgba(0,0,0,.3)">
        <?php else: ?>
        <i class="fa-solid fa-book" style="font-size:2.5rem;color:rgba(255,255,255,.5)"></i>
        <?php endif; ?>
        <div style="position:absolute;top:.6rem;right:.6rem">
            <span class="portal-badge <?= $statusBadge[0] ?>"><?= $statusBadge[1] ?></span>
        </div>
    </div>

    <div style="padding:.85rem;flex:1;display:flex;flex-direction:column;gap:.4rem">
        <h3 style="font-size:.9rem;font-weight:700;color:#0C4A6E;margin:0;line-height:1.3">
            <?= htmlspecialchars($e['livro_titulo'] ?? 'Livro') ?>
        </h3>
        <?php if (!empty($e['livro_autor'])): ?>
        <div style="font-size:.78rem;color:#64748B"><?= htmlspecialchars($e['livro_autor']) ?></div>
        <?php endif; ?>
        <?php if (!empty($e['livro_categoria'])): ?>
        <span style="font-size:.72rem;font-weight:600;color:#0EA5E9"><?= htmlspecialchars($e['livro_categoria']) ?></span>
        <?php endif; ?>

        <div style="margin-top:auto;padding-top:.6rem;border-top:1px solid #F0F9FF">
            <div style="display:flex;justify-content:space-between;font-size:.78rem">
                <span style="color:#64748B">Emprestado em</span>
                <span style="color:#334155;font-weight:600"><?= $e['emprestado_em'] ? date('d/m/Y', strtotime($e['emprestado_em'])) : '—' ?></span>
            </div>
            <?php if ($status !== 'devolvido' && $prevista): ?>
            <div style="display:flex;justify-content:space-between;font-size:.78rem;margin-top:.25rem">
                <span style="color:#64748B">Devolução prevista</span>
                <span style="font-weight:600;color:<?= $status === 'atrasado' ? '#B91C1C' : '#334155' ?>">
                    <?= date('d/m/Y', strtotime($prevista)) ?>
                    <?php if ($diasRestantes !== null && $status !== 'atrasado'): ?>
                    <span style="font-size:.7rem;color:#64748B"> (<?= $diasRestantes ?> dias)</span>
                    <?php elseif ($status === 'atrasado'): ?>
                    <span style="font-size:.7rem;color:#B91C1C"> (<?= abs($diasRestantes ?? 0) ?> dias atrás)</span>
                    <?php endif; ?>
                </span>
            </div>
            <?php elseif ($status === 'devolvido' && !empty($e['devolvido_em'])): ?>
            <div style="display:flex;justify-content:space-between;font-size:.78rem;margin-top:.25rem">
                <span style="color:#64748B">Devolvido em</span>
                <span style="color:#15803D;font-weight:600"><?= date('d/m/Y', strtotime($e['devolvido_em'])) ?></span>
            </div>
            <?php endif; ?>
        </div>
    </div>
</div>
<?php endforeach; ?>
</div>
<?php endif; ?>

<?php if ($totalPagesBib > 1): ?>
<div style="display:flex;justify-content:center;gap:.4rem;margin-top:1rem">
    <?php for ($i = 1; $i <= $totalPagesBib; $i++): ?>
    <a href="?status=<?= htmlspecialchars($filtroStatus) ?>&page=<?= $i ?>"
       style="padding:.35rem .75rem;border-radius:8px;font-size:.82rem;font-weight:600;text-decoration:none;
              background:<?= $i === $currentPageBib ? '#0EA5E9' : '#fff' ?>;
              color:<?= $i === $currentPageBib ? '#fff' : '#334155' ?>;
              border:1.5px solid <?= $i === $currentPageBib ? '#0EA5E9' : '#CBD5E1' ?>">
        <?= $i ?>
    </a>
    <?php endfor; ?>
</div>
<?php endif; ?>

<?php include dirname(__FILE__) . '/layout_bottom.php'; ?>
