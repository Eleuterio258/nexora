<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin;

use E258Tech\Core\Application;
use E258Tech\Infrastructure\Auth\AdminSession;
use E258Tech\Infrastructure\Http\HttpClientException;
use E258Tech\Infrastructure\Security\WebSecurity;
use E258Tech\Http\ServerRequest;

final readonly class AdminAuthController
{
    public function __construct(
        private AdminSession $session,
        private WebSecurity $security,
        private ServerRequest $request,
        private string $viewRoot
    ) {
    }

    public function login(): void
    {
        if ($this->session->isAuthenticated()) {
            header('Location: ' . $this->session->homeUrl());
            exit;
        }

        $erro = '';

        if ($this->request->isPost()) {
            $erro = $this->attemptLogin();
        }

        $csrf = $this->security->csrfToken();
        $app = Application::instance();

        require $this->viewRoot . '/pages/login.php';
    }

    public function logout(): never
    {
        $this->session->logout();
        $this->session->clear();
        header('Location: /nexora/login');
        exit;
    }

    private function attemptLogin(): string
    {
        if (!$this->security->hasValidCsrf($this->request->csrfToken())) {
            return 'Token de segurança inválido. Recarregue a página.';
        }

        if (!$this->security->allow('admin_login', 5, 300)) {
            return 'Demasiadas tentativas. Aguarde 5 minutos.';
        }

        $email = $this->request->postString('email');
        $pass = (string) $this->request->postValue('password', '');

        if ($email === '' || $pass === '') {
            return 'Preencha o email e a senha.';
        }

        if (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            return 'Introduza um endereço de email válido.';
        }

        try {
            $resp = $this->session->login($email, $pass);

            if ($resp['status'] === 200 && !empty($resp['body']['access_token'])) {
                session_regenerate_id(true);
                $this->session->store($resp['body']);

                $next = $this->request->queryString('next', $this->session->homeUrl());
                if (!preg_match('#^/nexora#', $next)) {
                    $next = $this->session->homeUrl();
                }
                header('Location: ' . $next);
                exit;
            }

            return match (true) {
                in_array($resp['status'], [400, 401, 422], true) => 'Email ou senha incorretos.',
                $resp['status'] === 403 => 'A sua conta não tem permissão para aceder ao painel.',
                $resp['status'] === 429 => 'Demasiadas tentativas. Aguarde alguns minutos.',
                $resp['status'] >= 500 => 'O serviço de autenticação está temporariamente indisponível.',
                default => 'Não foi possível concluir o login. Tente novamente.',
            };
        } catch (HttpClientException $exception) {
            error_log(sprintf(
                '[admin-login] Falha na API Nexora: %s',
                $exception->getMessage()
            ));
            return 'Não foi possível comunicar com o serviço de autenticação. Tente novamente mais tarde.';
        }
    }
}
