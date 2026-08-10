<?php
/**
 * Overlay de loading global.
 *
 * Uso: include 'src/View/templates/partials/components/loading-overlay.php';
 * Ativar via JS: document.body.classList.add('loading-active');
 */

declare(strict_types=1);
?>

<div id="loading-overlay" class="loading-overlay" hidden>
    <div class="loading-overlay__spinner" aria-label="A carregar">
        <span></span><span></span><span></span>
    </div>
    <p class="loading-overlay__text">A carregar...</p>
</div>
