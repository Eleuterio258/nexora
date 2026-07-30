/* =========================================================
   Recriação — Gestão de Obras
   Interações da tela de login
   ========================================================= */

document.addEventListener('DOMContentLoaded', function () {
    const loginForm = document.getElementById('login-form');
    const recoveryForm = document.getElementById('form-recuperar');
    const usuarioInput = document.getElementById('usuario');
    const senhaInput = document.getElementById('password-field');
    const salvarCheckbox = document.getElementById('salvar_acesso');
    const togglePassword = document.querySelector('.toggle-password');

    const modalOverlay = document.getElementById('modal-recuperar');
    const btnOpenModal = document.getElementById('btn-open-modal');
    const btnCloseModal = document.querySelector('.btn-close');
    const btnCancelModal = document.getElementById('btn-cancel-modal');

    // Modo de teste: preenche credenciais de demonstração
    const modoTeste = true; // Altere para false para desabilitar
    if (modoTeste) {
        setTimeout(() => {
            usuarioInput.value = 'contato@hugocursos.com.br';
            senhaInput.value = '123';
        }, 300);
    }

    // Preenche credenciais salvas no localStorage
    const emailSalvo = localStorage.getItem('email_usu');
    const senhaSalva = localStorage.getItem('senha_usu');

    if (emailSalvo) {
        usuarioInput.value = emailSalvo;
        salvarCheckbox.checked = true;
    }

    if (senhaSalva) {
        senhaInput.value = senhaSalva;
    }

    // Toggle visibilidade da senha
    if (togglePassword) {
        togglePassword.addEventListener('click', function () {
            const type = senhaInput.getAttribute('type') === 'password' ? 'text' : 'password';
            senhaInput.setAttribute('type', type);
            this.classList.toggle('fa-eye');
            this.classList.toggle('fa-eye-slash');
        });
    }

    // Ao enviar o login, salva ou remove as credenciais
    if (loginForm) {
        loginForm.addEventListener('submit', function () {
            if (salvarCheckbox.checked) {
                localStorage.setItem('email_usu', usuarioInput.value);
                localStorage.setItem('senha_usu', senhaInput.value);
            } else {
                localStorage.removeItem('email_usu');
                localStorage.removeItem('senha_usu');
            }
        });
    }

    // Modal: abrir/fechar
    function openModal(event) {
        if (event) event.preventDefault();
        modalOverlay.classList.add('active');
    }

    function closeModal() {
        modalOverlay.classList.remove('active');
    }

    if (btnOpenModal) btnOpenModal.addEventListener('click', openModal);
    if (btnCloseModal) btnCloseModal.addEventListener('click', closeModal);
    if (btnCancelModal) btnCancelModal.addEventListener('click', closeModal);

    modalOverlay.addEventListener('click', function (event) {
        if (event.target === modalOverlay) {
            closeModal();
        }
    });

    // Envio do formulário de recuperação de senha (simulação)
    if (recoveryForm) {
        recoveryForm.addEventListener('submit', function (event) {
            event.preventDefault();
            const mensagem = document.getElementById('mensagem-recuperar');
            const email = document.getElementById('email-recuperar').value.trim();
            const telefone = document.getElementById('telefone-recuperar').value.trim();

            mensagem.textContent = 'Enviando...';
            mensagem.className = 'message';

            setTimeout(() => {
                if (email && telefone) {
                    mensagem.classList.add('text-success');
                    mensagem.textContent = 'Sua Senha foi enviada para o Email';
                    document.getElementById('email-recuperar').value = '';
                    document.getElementById('telefone-recuperar').value = '';
                } else {
                    mensagem.classList.add('text-danger');
                    mensagem.textContent = 'Preencha todos os campos.';
                }
            }, 800);
        });
    }
});
