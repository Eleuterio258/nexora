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
            header('Location: /nexora/destino');
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
        try {
            $this->session->logout();
        } catch (HttpClientException $exception) {
            // Mesmo que a API falhe, limpa a sessão local.
            error_log('[admin-logout] Falha na API Nexora: ' . $exception->getMessage());
        }
        $this->session->clear();
        header('Location: /nexora/login');
        exit;
    }

    /**
     * /nexora/papel/{tipo} — entra noutro papel da mesma pessoa.
     *
     * Quem autoriza é a API (pessoas.v_pessoa_tipos): daqui só se pede. Um
     * tipo que a pessoa não tenha devolve 403 e volta à escolha de destino.
     */
    public function papel(string $tipo): never
    {
        if (!$this->session->isAuthenticated()) {
            header('Location: /nexora/login');
            exit;
        }

        $urlDoTipo = [
            'candidato'   => '/carreira/candidato/area',
            'aluno'       => '/portal/aluno',
            'encarregado' => '/portal/encarregado',
            'funcionario' => '/nexora/',
        ];
        if (!isset($urlDoTipo[$tipo]) || !$this->session->trocarPapel($tipo)) {
            header('Location: /nexora/destino?erro=papel');
            exit;
        }

        header('Location: ' . $urlDoTipo[$tipo]);
        exit;
    }

    public function destino(): void
    {
        if (!$this->session->isAuthenticated()) {
            header('Location: /nexora/login');
            exit;
        }

        $destinos = [
            [
                'escopo' => 'erp',
                'titulo' => 'ERP',
                'descricao' => 'Area restrita para funcionarios do ERP.',
                'url' => '/nexora/',
                'icone' => 'briefcase',
                'ativo' => $this->session->hasEscopo('erp'),
            ],
            [
                'escopo' => 'escola',
                'titulo' => 'Escola',
                'descricao' => 'Area restrita para funcionarios da escola.',
                'url' => '/escola',
                'icone' => 'school',
                'ativo' => $this->session->hasEscopo('escola') && !$this->session->isProfessor(),
            ],
            [
                'escopo' => 'portal_professor',
                'titulo' => 'Portal do Professor',
                'descricao' => 'Area dedicada aos professores.',
                'url' => '/portal/professor',
                'icone' => 'chalkboard',
                'ativo' => $this->session->isProfessor(),
            ],
            [
                'escopo' => 'portal_aluno',
                'titulo' => 'Portal do Aluno',
                'descricao' => 'Area dedicada aos alunos.',
                'url' => '/portal/aluno',
                'icone' => 'graduation',
                'ativo' => $this->session->hasEscopo('portal_aluno'),
            ],
            [
                'escopo' => 'portal_encarregado',
                'titulo' => 'Portal do Encarregado',
                'descricao' => 'Area dedicada aos encarregados de educacao.',
                'url' => '/portal/encarregado',
                'icone' => 'users',
                'ativo' => $this->session->hasEscopo('portal_encarregado'),
            ],
            [
                'escopo' => 'portal_candidato',
                'titulo' => 'Area do Candidato',
                'descricao' => 'Acompanhe as suas candidaturas a vagas.',
                'url' => '/carreira/candidato/area',
                'icone' => 'briefcase',
                'ativo' => $this->session->hasEscopo('portal_candidato'),
            ],
            [
                'escopo' => 'superadmin',
                'titulo' => 'Superadmin',
                'descricao' => 'Area de administracao e configuracao global.',
                'url' => '/nexora/superadmin',
                'icone' => 'shield',
                'ativo' => $this->session->isSuperAdmin(),
            ],
        ];

        // Papéis que a pessoa tem mas para os quais a sessão actual não tem
        // escopo (pessoas.v_pessoa_tipos). Antes disto a página só mostrava o
        // que o token já permitia, e uma pessoa que fosse ao mesmo tempo
        // funcionária e candidata via apenas a porta por onde entrou — a outra
        // era inalcançável sem alterar o tipo da conta. Estes destinos passam
        // por /nexora/papel/<tipo>, que troca o token antes de encaminhar.
        // O escopo de cada papel vem do backend (pessoaTipo.escopo); aqui só
        // fica o texto que se mostra. Um mapa tipo→escopo do lado do PHP
        // dessincronizava-se assim que um papel novo aparecesse.
        $rotulos = [
            'candidato'   => ['Área do Candidato',     'Acompanhe as suas candidaturas a vagas.',      'briefcase'],
            'aluno'       => ['Portal do Aluno',       'Área dedicada aos alunos.',                    'graduation'],
            'encarregado' => ['Portal do Encarregado', 'Área dedicada aos encarregados de educação.',  'users'],
            'funcionario' => ['ERP',                   'Área restrita para funcionários do ERP.',      'briefcase'],
            'professor'   => ['Portal do Professor',   'Área dedicada aos professores.',               'chalkboard'],
        ];
        $escoposJaActivos = array_column(array_filter($destinos, static fn(array $d): bool => $d['ativo']), 'escopo');
        foreach ($this->session->tipos() as $papel) {
            $tipoPessoa = (string) ($papel['tipo'] ?? '');
            $escopo     = (string) ($papel['escopo'] ?? '');
            // Sem escopo o papel não tem área própria (é o caso de 'cliente'):
            // aparece nas etiquetas da barra lateral, mas não é um destino.
            if (!($papel['activo'] ?? false) || $escopo === '' || !isset($rotulos[$tipoPessoa])) {
                continue;
            }
            if (in_array($escopo, $escoposJaActivos, true)) {
                continue;
            }
            [$titulo, $descricao, $icone] = $rotulos[$tipoPessoa];
            $destinos[] = [
                'escopo'    => $escopo,
                'titulo'    => $titulo,
                'descricao' => $descricao,
                'url'       => '/nexora/papel/' . rawurlencode($tipoPessoa),
                'icone'     => $icone,
                'ativo'     => true,
            ];
            $escoposJaActivos[] = $escopo;
        }

        $destinos = array_values(array_filter($destinos, static fn(array $destino): bool => $destino['ativo']));

        // Se o utilizador tem apenas um destino disponível, redireciona directamente.
        // Sem destinos activos: termina a sessão por segurança.
        if (count($destinos) === 0) {
            $this->session->clear();
            header('Location: /nexora/login');
            exit;
        }

        require $this->viewRoot . '/pages/destino.php';
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

                $next = $this->request->queryString('next', '/nexora/destino');
                // Só aceita redireccionamentos internos conhecidos.
                if (!preg_match('#^/(nexora|escola|portal/aluno|portal/encarregado|portal/professor|carreira|vagas)(/|\?|$)#', $next)) {
                    $next = '/nexora/destino';
                }
                // Restringir ao escopo do utilizador.
                if ($next !== '/nexora/destino') {
                    if ($this->session->isProfessor() && !str_starts_with($next, '/portal/professor')) {
                        $next = '/nexora/destino';
                    } elseif ($this->session->isSchoolOnly() && !$this->session->isProfessor() && !str_starts_with($next, '/escola')) {
                        $next = '/nexora/destino';
                    } elseif ($this->session->isErpOnly() && !str_starts_with($next, '/nexora')) {
                        $next = '/nexora/destino';
                    } elseif ($this->session->hasEscopo('portal_aluno') && !str_starts_with($next, '/portal/aluno')) {
                        $next = '/nexora/destino';
                    } elseif ($this->session->hasEscopo('portal_encarregado') && !str_starts_with($next, '/portal/encarregado')) {
                        $next = '/nexora/destino';
                    } elseif ($this->session->hasEscopo('portal_candidato') && !str_starts_with($next, '/carreira') && !str_starts_with($next, '/vagas')) {
                        $next = '/nexora/destino';
                    }
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
