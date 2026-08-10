<?php
/**
 * Componente de paginação reutilizável.
 *
 * Uso:
 *   $pag = PaginationHelper::fromResponse($response['body']);
 *   include 'src/View/templates/partials/components/pagination.php';
 *
 * Variáveis esperadas:
 *   - $pag: PaginationHelper
 *   - $baseUrl: string
 *   - $currentParams: array<string, mixed>
 *   - $pageParam: string (opcional, default 'pagina')
 */

declare(strict_types=1);

use E258Tech\View\Helpers\PaginationHelper;

if (!isset($pag) || !$pag instanceof PaginationHelper || !$pag->hasPages()) {
    return;
}

$baseUrl = $baseUrl ?? strtok($_SERVER['REQUEST_URI'] ?? '', '?');
$currentParams = $currentParams ?? $_GET;
$pageParam = $pageParam ?? 'pagina';
unset($currentParams[$pageParam]);
?>

<nav class="pagination" aria-label="Paginação">
    <?php if ($pag->hasPrevious()): ?>
        <a class="pagination__link pagination__link--prev" href="<?= htmlspecialchars($pag->urlForPage($pag->currentPage() - 1, $baseUrl, $currentParams, $pageParam)) ?>">
            Anterior
        </a>
    <?php else: ?>
        <span class="pagination__link pagination__link--prev pagination__link--disabled">Anterior</span>
    <?php endif; ?>

    <div class="pagination__pages">
        <?php foreach ($pag->visiblePages() as $page): ?>
            <?php if ($page === '...'): ?>
                <span class="pagination__ellipsis">...</span>
            <?php elseif ($page === $pag->currentPage()): ?>
                <span class="pagination__link pagination__link--active" aria-current="page"><?= $page ?></span>
            <?php else: ?>
                <a class="pagination__link" href="<?= htmlspecialchars($pag->urlForPage((int) $page, $baseUrl, $currentParams, $pageParam)) ?>"><?= $page ?></a>
            <?php endif; ?>
        <?php endforeach; ?>
    </div>

    <?php if ($pag->hasNext()): ?>
        <a class="pagination__link pagination__link--next" href="<?= htmlspecialchars($pag->urlForPage($pag->currentPage() + 1, $baseUrl, $currentParams, $pageParam)) ?>">
            Seguinte
        </a>
    <?php else: ?>
        <span class="pagination__link pagination__link--next pagination__link--disabled">Seguinte</span>
    <?php endif; ?>
</nav>
