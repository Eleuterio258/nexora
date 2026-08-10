/**
 * Cliente JS utilitário para chamadas AJAX ao proxy PHP.
 *
 * Funcionalidades:
 * - Mostra/oculte o loading overlay automaticamente
 * - Trata códigos de erro comuns (401, 402, 403, 422, 5xx)
 * - Suporta CSRF token
 */

(function (global) {
    'use strict';

    const LOADING_OVERLAY_ID = 'loading-overlay';
    const CSRF_INPUT_SELECTOR = 'input[name="csrf_token"]';

    function getCsrfToken() {
        const input = document.querySelector(CSRF_INPUT_SELECTOR);
        return input ? input.value : '';
    }

    function toggleLoading(show) {
        const overlay = document.getElementById(LOADING_OVERLAY_ID);
        if (!overlay) return;
        overlay.hidden = !show;
        document.body.classList.toggle('loading-active', show);
    }

    function showFlash(type, message) {
        const container = document.querySelector('.flash-messages');
        if (!container) return;

        const el = document.createElement('div');
        el.className = 'flash-message flash-message--' + type;
        el.setAttribute('data-auto-dismiss', '5000');
        el.innerHTML = '<span class="flash-message__text">' + escapeHtml(message) + '</span>' +
            '<button type="button" class="flash-message__close" aria-label="Fechar">&times;</button>';

        container.appendChild(el);
        bindCloseButton(el);
        scheduleAutoDismiss(el);
    }

    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    function bindCloseButton(el) {
        const btn = el.querySelector('.flash-message__close');
        if (btn) {
            btn.addEventListener('click', () => el.remove());
        }
    }

    function scheduleAutoDismiss(el) {
        const delay = parseInt(el.getAttribute('data-auto-dismiss'), 10) || 5000;
        setTimeout(() => {
            el.style.opacity = '0';
            setTimeout(() => el.remove(), 300);
        }, delay);
    }

    function handleHttpError(status, body) {
        const message = (body && (body.erro || body.error || body.message || body.mensagem))
            || defaultErrorMessage(status);

        if (status === 401) {
            window.location.href = '/nexora/login?next=' + encodeURIComponent(window.location.pathname);
            return;
        }

        if (status === 402) {
            const modal = document.getElementById('license-modal');
            if (modal) modal.hidden = false;
            return;
        }

        showFlash(status === 403 ? 'warning' : 'error', message);
    }

    function defaultErrorMessage(status) {
        const messages = {
            400: 'Pedido inválido. Verifica os dados enviados.',
            403: 'Sem permissão para realizar esta operação.',
            404: 'Recurso não encontrado.',
            409: 'Conflito de dados.',
            422: 'Dados inválidos. Verifica os campos do formulário.',
            429: 'Muitos pedidos. Tenta novamente dentro de momentos.',
            500: 'Erro interno do servidor.',
            502: 'Serviço indisponível.',
            503: 'Serviço temporariamente indisponível.',
        };
        return messages[status] || 'Ocorreu um erro inesperado. Tenta novamente.';
    }

    /**
     * Faz uma chamada fetch ao backend via proxy PHP.
     *
     * @param {string} url
     * @param {object} options
     * @returns {Promise<object>}
     */
    async function apiFetch(url, options = {}) {
        const opts = {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'X-Requested-With': 'XMLHttpRequest',
            },
            ...options,
        };

        const csrf = getCsrfToken();
        if (csrf && ['POST', 'PUT', 'PATCH', 'DELETE'].includes(opts.method.toUpperCase())) {
            opts.headers['X-CSRF-Token'] = csrf;
        }

        if (opts.body && typeof opts.body === 'object' && !(opts.body instanceof FormData)) {
            opts.headers['Content-Type'] = 'application/json';
            opts.body = JSON.stringify(opts.body);
        }

        toggleLoading(true);

        try {
            const response = await fetch(url, opts);
            const contentType = response.headers.get('content-type') || '';
            const body = contentType.includes('application/json') ? await response.json() : await response.text();

            if (!response.ok) {
                handleHttpError(response.status, body);
                throw new Error(body && body.erro ? body.erro : defaultErrorMessage(response.status));
            }

            return body;
        } catch (err) {
            if (!err.message || err.name === 'TypeError') {
                showFlash('error', 'Erro de ligação. Verifica a internet ou o servidor.');
            }
            throw err;
        } finally {
            toggleLoading(false);
        }
    }

    // Auto-bind das flash messages existentes no DOM
    document.addEventListener('DOMContentLoaded', () => {
        document.querySelectorAll('.flash-message').forEach(el => {
            bindCloseButton(el);
            scheduleAutoDismiss(el);
        });
    });

    global.e258tech = global.e258tech || {};
    global.e258tech.api = {
        fetch: apiFetch,
        showFlash,
        toggleLoading,
    };
})(window);
