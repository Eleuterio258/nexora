<?php
/**
 * Modal exibido quando a licença do tenant está expirada ou suspensa (HTTP 402).
 *
 * Uso: include 'src/View/templates/partials/components/license-modal.php';
 */

declare(strict_types=1);
?>

<div id="license-modal" class="license-modal" hidden>
    <div class="license-modal__overlay"></div>
    <div class="license-modal__box" role="dialog" aria-modal="true" aria-labelledby="license-modal-title">
        <div class="license-modal__icon">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
            </svg>
        </div>
        <h2 id="license-modal-title" class="license-modal__title">Licença expirada</h2>
        <p class="license-modal__text">
            A licença da aplicação está expirada ou suspensa para este tenant.
            Contacta o administrador do sistema para reactivar o acesso.
        </p>
        <div class="license-modal__actions">
            <a href="/nexora/logout" class="btn-primary">Sair</a>
        </div>
    </div>
</div>
