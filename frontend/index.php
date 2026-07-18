<?php
declare (strict_types = 1);

require_once __DIR__ . '/src/autoload.php';
require_once __DIR__ . '/vendor/autoload.php';

use E258Tech\Controller\Admin\AdminApiRuntime;
use E258Tech\Controller\Portal\PortalAlunoController;
use E258Tech\Controller\Portal\PortalEncarregadoController;
use E258Tech\Controller\Portal\PortalProfessorController;
use E258Tech\Infrastructure\Auth\PortalAlunoSession;
use E258Tech\Core\Application;

function renderAccessDenied(string $message): void
{
    http_response_code(403);
    echo '<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sem acesso</title>
    <style>
        body { font-family: system-ui, -apple-system, sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; background: #f3f4f6; }
        .box { background: white; padding: 2rem; border-radius: 0.75rem; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); text-align: center; max-width: 420px; }
        h1 { color: #dc2626; margin-bottom: 0.5rem; }
        p { color: #4b5563; margin-bottom: 1.5rem; }
        a { display: inline-block; padding: 0.6rem 1.2rem; background: #2563eb; color: white; text-decoration: none; border-radius: 0.375rem; }
        a:hover { background: #1d4ed8; }
    </style>
</head>
<body>
    <div class="box">
        <h1>Sem acesso</h1>
        <p>' . htmlspecialchars($message, ENT_QUOTES, 'UTF-8') . '</p>
        <a href="/nexora/logout">Sair e entrar com outra conta</a>
    </div>
</body>
</html>';
    exit;
}

$uri = (string) parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

if (str_starts_with($uri, '/admin')) {
    $target = '/nexora' . substr($uri, strlen('/admin'));
    header('Location: ' . $target, true, 301);
    exit;
} elseif (preg_match('#^/nexora/api/recrutamento/vagas/(\d+)/campos(?:/(\d+))?$#', $uri, $m)) {
    // Proxy REST para Form Builder (campos por vaga)
    $app    = Application::bootstrap();
    $path   = '/api/recrutamento/vagas/' . $m[1] . '/campos' . (isset($m[2]) ? '/' . $m[2] : '');
    $method = $_SERVER['REQUEST_METHOD'];
    $body   = in_array($method, ['POST','PUT']) ? json_decode(file_get_contents('php://input'), true) : null;
    $resp   = $app->nexora->call($method, $path, $body);
    header('Content-Type: application/json');
    http_response_code($resp['status'] ?: 200);
    echo json_encode($resp['body']);
    exit;
} elseif (str_starts_with($uri, '/nexora/api/')) {
    (new AdminApiRuntime(Application::bootstrap()))->dispatch(basename($uri, '.php'));
} elseif (str_starts_with($uri, '/aluno')) {
    // ── Gestão do Portal do Aluno — rota independente /aluno/* ──────────────────
    $app  = Application::bootstrap();
    $path = rtrim(parse_url($uri, PHP_URL_PATH), '/') ?: '/aluno';

    // Auth
    if (!$app->session->isAuthenticated()) {
        header('Location: /nexora/login?next=' . urlencode($uri));
        exit;
    }
    if (!$app->session->isSuperAdmin() && !$app->session->isSchoolOnly() && !$app->session->isBoth()) {
        renderAccessDenied('Este painel é reservado a utilizadores com acesso à Escola.');
    }
    // Sincronizar permissões caso o cargo/permissoes tenham sido alterados
    $app->session->refreshPermTimestamp();
    if ($app->session->modulosExpirados()) {
        $app->session->syncModulos();
    }
    if (!$app->session->canModule('gestao-escolar')) {
        renderAccessDenied('Não tem permissão para o módulo de Gestão Escolar.');
    }

    // Usar layout do Painel Escolar
    $GLOBALS['_escolarPanel'] = true;

    $pageKey = $app->studentRoutes->resolveByPath($path);
    if ($pageKey === null) {
        http_response_code(404);
        echo 'Página não encontrada.';
        exit;
    }

    $def = $app->studentRoutes->definition($pageKey);
    $view = __DIR__ . '/src/View/templates/pages/' . $def['view'];
    if (!is_file($view)) {
        http_response_code(500);
        echo 'View não encontrada.';
        exit;
    }
    require $view;
    exit;
} elseif (str_starts_with($uri, '/escola')) {
    // ── Painel Escolar — URL independente com sidebar dedicada ──────────────
    $app  = Application::bootstrap();
    $path = rtrim(parse_url($uri, PHP_URL_PATH), '/') ?: '/escola';

    // Auth
    if (!$app->session->isAuthenticated()) {
        header('Location: /nexora/login?next=' . urlencode($uri));
        exit;
    }
    if (!$app->session->isSuperAdmin() && !$app->session->isSchoolOnly() && !$app->session->isBoth()) {
        renderAccessDenied('Este painel é reservado a utilizadores com acesso à Escola.');
    }
    // Sincronizar permissões caso o cargo/permissoes tenham sido alterados
    $app->session->refreshPermTimestamp();
    if ($app->session->modulosExpirados()) {
        $app->session->syncModulos();
    }
    if (!$app->session->canModule('gestao-escolar')) {
        renderAccessDenied('Não tem permissão para o módulo de Gestão Escolar.');
    }

    // Activar layout da escola em TODOS os includes seguintes
    $GLOBALS['_escolarPanel'] = true;

    // Mapa de rotas /escola/* → chave de dispatch
    $escolaRoutes = [
        '/escola'                    => 'escolar_dashboard',
        '/escola/dashboard'          => 'escolar_dashboard',
        '/escola/anos-lectivos'      => 'escolar_anos_lectivos',
        '/escola/niveis'             => 'escolar_niveis',
        '/escola/series'             => 'escolar_series',
        '/escola/cursos'             => 'escolar_cursos',
        '/escola/turmas'             => 'escolar_turmas',
        '/escola/disciplinas'        => 'escolar_disciplinas',
        '/escola/professores'        => 'escolar_professores',
        '/escola/atribuicoes'        => 'escolar_atribuicoes',
        '/escola/horarios'           => 'escolar_horarios',
        '/escola/calendario'         => 'escolar_calendario',
        '/escola/alunos'             => 'escolar_alunos',
        '/escola/matriculas'         => 'escolar_matriculas',
        '/escola/cargos-alunos'      => 'escolar_cargos_alunos',
        '/escola/cargos-professores' => 'escolar_cargos_professores',
        '/escola/ocorrencias'        => 'escolar_ocorrencias',
        '/escola/frequencia'         => 'escolar_frequencia',
        '/escola/avaliacoes'         => 'escolar_avaliacoes',
        '/escola/notas'              => 'escolar_notas',
        '/escola/boletins'           => 'escolar_boletins',
        '/escola/planos-propinas'    => 'escolar_planos_cobranca',
        '/escola/cobrancas'          => 'escolar_cobrancas',
        '/escola/pagamentos'         => 'escolar_pagamentos',
        '/escola/aging'              => 'escolar_inadimplencia',
        '/escola/biblioteca'         => 'escolar_biblioteca',
        '/escola/emprestimos'        => 'escolar_emprestimos',
        '/escola/comunicacao'        => 'escolar_comunicacao',
        '/escola/resumo-academico'   => 'escolar_resumo_academico',
        '/escola/resumo-financeiro'  => 'escolar_resumo_financeiro',
        '/escola/bolsas'             => 'escolar_inadimplencia', // reutiliza temporariamente

        '/escola/config-financeira'  => 'escolar_config_financeira',
    ];

    $pageKey = $escolaRoutes[$path] ?? null;
    if ($pageKey !== null) {
        $app->adminPages->dispatch($pageKey);
    } else {
        http_response_code(404);
        echo 'Página não encontrada no painel escolar.';
    }
} elseif (str_starts_with($uri, '/nexora')) {
    $app  = Application::bootstrap();

    // Utilizadores exclusivamente escolares não podem aceder ao ERP
    if ($app->session->isAuthenticated() && !$app->session->isSuperAdmin() && $app->session->isSchoolOnly() && $uri !== '/nexora/destino' && $uri !== '/nexora/logout') {
        header('Location: ' . ($app->session->isProfessor() ? '/portal/professor' : '/escola'));
        exit;
    }
    if ($app->session->isAuthenticated() && $uri !== '/nexora/destino' && $uri !== '/nexora/logout') {
        if ($app->session->hasEscopo('portal_aluno')) {
            $portalAluno = new \E258Tech\Infrastructure\Auth\PortalAlunoSession();
            if ($portalAluno->isAuthenticated()) {
                header('Location: /portal/aluno');
                exit;
            }
            // Token do portal expirou mas AdminSession ainda activa — limpa sessão
            // para evitar redirect loop entre /portal/aluno e /nexora/login.
            $app->session->clear();
        } elseif ($app->session->hasEscopo('portal_encarregado')) {
            $encToken     = (string) ($_SESSION['enc_token'] ?? '');
            $encExpiresAt = (int) ($_SESSION['enc_expires_at'] ?? 0);
            if ($encToken !== '' && $encExpiresAt > time()) {
                header('Location: /portal/encarregado');
                exit;
            }
            // Token do encarregado expirou — mesma protecção contra loop.
            $app->session->clear();
        }
    }

    $path = rtrim($uri, '/') ?: '/nexora';
    if ($path === '/nexora/login') {
        $app->adminAuth->login();
    } elseif ($path === '/nexora/destino') {
        $app->adminAuth->destino();
    } elseif ($path === '/nexora/logout') {
        $app->adminAuth->logout();
    } elseif ($path === '/nexora/download') {
        $app->adminDownload->download();
    } elseif ($path === '/nexora' || $path === '/nexora/index') {
        $app->adminPages->dispatch('dashboard');
    } else {
        $route = $app->routes->resolveByPath($path);
        if ($route === null) {
            http_response_code(404);
            echo 'Página não encontrada.';
        } else {
            $app->adminPages->dispatch($route);
        }
    }
} elseif (str_starts_with($uri, '/portal/professor')) {
    $app      = Application::bootstrap();
    $path     = rtrim($uri, '/');
    $viewRoot = __DIR__ . '/src/View/templates/portal_professor';

    // Rotas públicas
    if ($path === '/portal/professor/login') {
        header('Location: /nexora/login?next=' . urlencode('/portal/professor'));
        exit;
    }
    if ($path === '/portal/professor/logout') {
        (new PortalProfessorController(
            rtrim((string)(getenv('NEXORA_API_URL') ?: 'http://127.0.0.1:8080'), '/'),
            $app->session->token()
        ))->logout($app->session);
        exit;
    }

    // Autenticação
    if (!$app->session->isAuthenticated() || !$app->session->isProfessor()) {
        if ($app->session->isAuthenticated() && !$app->session->isProfessor()) {
            renderAccessDenied('Esta área é reservada a professores.');
        }
        header('Location: /nexora/login?next=' . urlencode('/portal/professor'));
        exit;
    }

    $token = $app->session->token();
    $prof  = new PortalProfessorController(
        rtrim((string)(getenv('NEXORA_API_URL') ?: 'http://127.0.0.1:8080'), '/'),
        $token
    );

    // Endpoint AJAX de presenças
    if ($path === '/portal/professor/api/presencas') {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $resp = $prof->api('/api/portal/professor/me/presencas', 'POST', $body);
        header('Content-Type: application/json');
        http_response_code($resp['status'] ?: 200);
        echo json_encode($resp['body']);
        exit;
    }
    // Endpoint AJAX de notas
    if ($path === '/portal/professor/api/notas') {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $resp = $prof->api('/api/portal/professor/me/notas', 'POST', $body);
        header('Content-Type: application/json');
        http_response_code($resp['status'] ?: 200);
        echo json_encode($resp['body']);
        exit;
    }
    // Endpoint AJAX de alterar senha
    if ($path === '/portal/professor/api/alterar-senha') {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $resp = $prof->api('/api/portal/professor/alterar-senha', 'POST', $body);
        header('Content-Type: application/json');
        http_response_code($resp['status'] ?: 200);
        echo json_encode($resp['body']);
        exit;
    }

    // Dados comuns a todas as páginas
    $meResp      = $prof->api('/api/portal/professor/me');
    $profInfo    = $meResp['body'] ?? [];
    $portalData  = [];

    match ($path) {
        '/portal/professor', '/portal/professor/dashboard' => (function () use ($app, $prof, $profInfo, $portalData, $viewRoot) {
            $portalData['turmas']      = $prof->api('/api/portal/professor/me/turmas');
            $portalData['horario']     = $prof->api('/api/portal/professor/me/horario');
            $portalData['comunicacao'] = $prof->api('/api/portal/professor/me/comunicacao');
            require $viewRoot . '/dashboard.php';
        })(),
        '/portal/professor/turmas' => (function () use ($app, $prof, $profInfo, $portalData, $viewRoot) {
            $portalData['turmas'] = $prof->api('/api/portal/professor/me/turmas');
            require $viewRoot . '/turmas.php';
        })(),
        '/portal/professor/turma' => (function () use ($app, $prof, $profInfo, $portalData, $viewRoot) {
            $turmaHash = $_GET['id'] ?? '';
            $turmaId   = $turmaHash ? $app->id->decode($turmaHash) : 0;
            $portalData['turma']   = $prof->api("/api/portal/professor/me/turmas/$turmaId");
            $portalData['alunos']  = $prof->api("/api/portal/professor/me/turmas/$turmaId/alunos");
            require $viewRoot . '/turma.php';
        })(),
        '/portal/professor/horario' => (function () use ($app, $prof, $profInfo, $portalData, $viewRoot) {
            $portalData['horario'] = $prof->api('/api/portal/professor/me/horario');
            require $viewRoot . '/horario.php';
        })(),
        '/portal/professor/presencas' => (function () use ($app, $prof, $profInfo, $portalData, $viewRoot) {
            $turmaHash  = $_GET['turma_id'] ?? '';
            $turmaId    = $turmaHash ? $app->id->decode($turmaHash) : 0;
            $data       = $_GET['data'] ?? date('Y-m-d');
            $qry        = http_build_query(array_filter(['turma_id' => $turmaId ?: null, 'data' => $data]));
            $portalData['presencas'] = $prof->api('/api/portal/professor/me/presencas' . ($qry ? "?$qry" : ''));
            $portalData['turmas']    = $prof->api('/api/portal/professor/me/turmas');
            require $viewRoot . '/presencas.php';
        })(),
        '/portal/professor/notas' => (function () use ($app, $prof, $profInfo, $portalData, $viewRoot) {
            $turmaHash  = $_GET['turma_id'] ?? '';
            $discHash   = $_GET['disciplina_id'] ?? '';
            $turmaId    = $turmaHash ? $app->id->decode($turmaHash) : 0;
            $disciplina = $discHash ? $app->id->decode($discHash) : 0;
            $qry = http_build_query(array_filter(['turma_id' => $turmaId ?: null, 'disciplina_id' => $disciplina ?: null]));
            $portalData['notas']  = $turmaId ? $prof->api('/api/portal/professor/me/notas' . ($qry ? "?$qry" : '')) : ['body' => []];
            $portalData['turmas'] = $prof->api('/api/portal/professor/me/turmas');
            require $viewRoot . '/notas.php';
        })(),
        '/portal/professor/comunicacao' => (function () use ($prof, $profInfo, $portalData, $viewRoot) {
            $portalData['comunicacao'] = $prof->api('/api/portal/professor/me/comunicacao');
            require $viewRoot . '/comunicacao.php';
        })(),
        '/portal/professor/conta' => (function () use ($profInfo, $viewRoot) {
            require $viewRoot . '/conta.php';
        })(),
        default => (function () { http_response_code(404); echo 'Página não encontrada.'; })(),
    };
} elseif (str_starts_with($uri, '/portal/aluno')) {
    $baseUrl  = rtrim((string) (getenv('NEXORA_API_URL') ?: 'http://127.0.0.1:8080'), '/');
    $portal   = new PortalAlunoController($baseUrl);
    $session  = new PortalAlunoSession();
    $path     = rtrim($uri, '/');

    // Rotas públicas
    if ($path === '/portal/aluno/login') {
        header('Location: /nexora/login?next=' . urlencode('/portal/aluno'));
        exit;
    } elseif ($path === '/portal/aluno/logout') {
        $portal->logout($session);
    } elseif ($path === '/portal/aluno/definir-senha') {
        $portal->definirSenha();
    } else {
        // Todas as outras requerem autenticação
        if (!$session->isAuthenticated()) {
            $app = Application::bootstrap();
            if ($app->session->isAuthenticated() && $app->session->hasEscopo('portal_aluno')) {
                $app->session->clear();
            }
            header('Location: /nexora/login?next=' . urlencode('/portal/aluno'));
            exit;
        }
        $session->requireAuthenticated();

        // Endpoint AJAX de alterar senha (JSON)
        if ($path === '/portal/aluno/api/alterar-senha') {
            $body = json_decode(file_get_contents('php://input'), true) ?? [];
            $resp = $portal->api($session, '/api/portal/aluno/alterar-senha', 'POST', $body);
            header('Content-Type: application/json');
            http_response_code($resp['status'] ?: 200);
            echo json_encode($resp['body']);
            exit;
        }

        // Pré-carregar dados comuns a todas as páginas
        $portalData = [];
        $portalData['me'] = $portal->api($session, '/api/portal/aluno/me');
        $alunoInfo = $portalData['me']['body'] ?? [];
        $viewRoot  = __DIR__ . '/src/View/templates/portal';

        // Rotas dinâmicas (padrão com ID)
        if (preg_match('#^/portal/aluno/cobrancas/(\d+)/recibo$#', $path, $m)) {
            $cobrancaId = (int) $m[1];
            $cobranca   = $portal->api($session, "/api/portal/aluno/me/cobrancas/$cobrancaId/recibo")['body'] ?? [];
            require $viewRoot . '/recibo_print.php';
            exit;
        }

        match ($path) {
            '/portal/aluno', '/portal/aluno/dashboard' => (function () use ($portal, $session, $portalData, $viewRoot, $alunoInfo) {
                $portalData['cobrancas'] = $portal->api($session, '/api/portal/aluno/me/cobrancas');
                $portalData['mensagens'] = $portal->api($session, '/api/portal/aluno/me/mensagens');
                $portalData['eventos']   = $portal->api($session, '/api/portal/aluno/me/eventos');
                require $viewRoot . '/dashboard.php';
            })(),
            '/portal/aluno/perfil' => (function () use ($portalData, $viewRoot, $alunoInfo) {
                require $viewRoot . '/perfil.php';
            })(),
            '/portal/aluno/boletim' => (function () use ($portal, $session, $portalData, $viewRoot, $alunoInfo) {
                $portalData['boletim'] = $portal->api($session, '/api/portal/aluno/me/boletim');
                require $viewRoot . '/boletim.php';
            })(),
            '/portal/aluno/boletim/imprimir' => (function () use ($portal, $session, $portalData, $viewRoot, $alunoInfo) {
                $boletim     = $portal->api($session, '/api/portal/aluno/me/boletim')['body'] ?? [];
                $termos      = $boletim['termos'] ?? [];
                $disciplinas = $boletim['disciplinas'] ?? [];
                $media       = $boletim['media'] ?? null;
                $cfg         = $boletim['config'] ?? [];
                $notaMinima  = (float)($cfg['nota_minima'] ?? 10);
                $stats       = $boletim['stats'] ?? [];
                $totalFaltas = (int)($stats['faltas'] ?? 0);
                $termId      = (int)($_GET['term_id'] ?? 0);
                require $viewRoot . '/boletim_print.php';
            })(),
            '/portal/aluno/cobrancas' => (function () use ($portal, $session, $portalData, $viewRoot, $alunoInfo) {
                $status = $_GET['status'] ?? '';
                $qry    = $status ? "?status=$status" : '';
                $portalData['cobrancas'] = $portal->api($session, "/api/portal/aluno/me/cobrancas$qry");
                require $viewRoot . '/cobrancas.php';
            })(),
            '/portal/aluno/horario' => (function () use ($portal, $session, $portalData, $viewRoot, $alunoInfo) {
                $portalData['horario'] = $portal->api($session, '/api/portal/aluno/me/horario');
                require $viewRoot . '/horario.php';
            })(),
            '/portal/aluno/ocorrencias' => (function () use ($portal, $session, $portalData, $viewRoot, $alunoInfo) {
                $portalData['ocorrencias'] = $portal->api($session, '/api/portal/aluno/me/ocorrencias');
                require $viewRoot . '/ocorrencias.php';
            })(),
            '/portal/aluno/biblioteca' => (function () use ($portal, $session, $portalData, $viewRoot, $alunoInfo) {
                $status = $_GET['status'] ?? '';
                $page   = max(1, (int)($_GET['page'] ?? 1));
                $params = array_filter(['status' => $status, 'page' => $page > 1 ? $page : null]);
                $qry    = $params ? '?' . http_build_query($params) : '';
                $portalData['biblioteca'] = $portal->api($session, "/api/portal/aluno/me/biblioteca$qry");
                require $viewRoot . '/biblioteca.php';
            })(),
            '/portal/aluno/mensagens' => (function () use ($portal, $session, $portalData, $viewRoot, $alunoInfo) {
                $portalData['mensagens'] = $portal->api($session, '/api/portal/aluno/me/mensagens');
                require $viewRoot . '/mensagens.php';
            })(),
            '/portal/aluno/eventos' => (function () use ($portal, $session, $portalData, $viewRoot, $alunoInfo) {
                $portalData['eventos'] = $portal->api($session, '/api/portal/aluno/me/eventos');
                require $viewRoot . '/eventos.php';
            })(),
            '/portal/aluno/presencas' => (function () use ($portal, $session, $portalData, $viewRoot, $alunoInfo) {
                $mes  = $_GET['mes']  ?? date('Y-m');
                $page = max(1, (int)($_GET['page'] ?? 1));
                $qry  = '?mes=' . urlencode($mes) . ($page > 1 ? "&page=$page" : '');
                $portalData['presencas'] = $portal->api($session, "/api/portal/aluno/me/presencas$qry");
                require $viewRoot . '/presencas.php';
            })(),
            '/portal/aluno/conta' => (function () use ($portalData, $viewRoot, $alunoInfo) {
                require $viewRoot . '/conta.php';
            })(),
            default => (function () {
                http_response_code(404);
                echo 'Página não encontrada.';
            })(),
        };
    }
} elseif (str_starts_with($uri, '/portal/encarregado')) {
    $baseUrl    = rtrim((string) (getenv('NEXORA_API_URL') ?: 'http://127.0.0.1:8080'), '/');
    $enc        = new PortalEncarregadoController($baseUrl);
    $app        = Application::bootstrap();
    $path       = rtrim($uri, '/');
    $viewRoot   = __DIR__ . '/src/View/templates/portal_encarregado';

    // Rotas públicas
    if ($path === '/portal/encarregado/login')   { header('Location: /nexora/login?next=' . urlencode('/portal/encarregado')); exit; }
    if ($path === '/portal/encarregado/logout')  { $enc->logout(); exit; }
    if ($path === '/portal/encarregado/definir-senha') { $enc->definirSenha(); exit; }

    // Rotas autenticadas
    if (!$enc->isAuthenticated()) {
        if ($app->session->isAuthenticated() && $app->session->hasEscopo('portal_encarregado')) {
            $app->session->clear();
        }
        header('Location: /nexora/login?next=' . urlencode('/portal/encarregado'));
        exit;
    }
    $enc->requireAuth();
    $meResp            = $enc->api('/api/portal/encarregado/me');
    $portalEncarregado = $meResp['body'] ?? [];
    $educandos         = $portalEncarregado['educandos'] ?? [];
    $selectedHash      = $_GET['educando_id'] ?? '';
    $selectedId        = $selectedHash ? $app->id->decode($selectedHash) : (int)($educandos[0]['student_id'] ?? 0);
    $selectedHash      = $app->id->encode($selectedId);

    $portalData = [];

    match ($path) {
        '/portal/encarregado', '/portal/encarregado/dashboard' => (function () use ($app, $enc, $portalEncarregado, $portalData, $viewRoot, $selectedId, $selectedHash) {
            $portalData['boletim']   = $enc->api("/api/portal/encarregado/me/educandos/$selectedId/boletim");
            $portalData['cobrancas'] = $enc->api("/api/portal/encarregado/me/educandos/$selectedId/cobrancas");
            $portalData['presencas'] = $enc->api("/api/portal/encarregado/me/educandos/$selectedId/presencas");
            require $viewRoot . '/dashboard.php';
        })(),
        '/portal/encarregado/boletim' => (function () use ($app, $enc, $portalEncarregado, $portalData, $viewRoot, $selectedId, $selectedHash) {
            $termId = (int)($_GET['term_id'] ?? 0);
            $qry    = $termId ? "?term_id=$termId" : '';
            $portalData['boletim'] = $enc->api("/api/portal/encarregado/me/educandos/$selectedId/boletim$qry");
            require $viewRoot . '/boletim.php';
        })(),
        '/portal/encarregado/cobrancas' => (function () use ($app, $enc, $portalEncarregado, $portalData, $viewRoot, $selectedId, $selectedHash) {
            $status = $_GET['status'] ?? '';
            $qry    = $status ? "?status=$status" : '';
            $portalData['cobrancas'] = $enc->api("/api/portal/encarregado/me/educandos/$selectedId/cobrancas$qry");
            require $viewRoot . '/cobrancas.php';
        })(),
        '/portal/encarregado/presencas' => (function () use ($app, $enc, $portalEncarregado, $portalData, $viewRoot, $selectedId, $selectedHash) {
            $mes = $_GET['mes'] ?? date('Y-m');
            $portalData['presencas'] = $enc->api("/api/portal/encarregado/me/educandos/$selectedId/presencas?mes=$mes");
            require $viewRoot . '/presencas.php';
        })(),
        '/portal/encarregado/ocorrencias' => (function () use ($app, $enc, $portalEncarregado, $portalData, $viewRoot, $selectedId, $selectedHash) {
            $portalData['ocorrencias'] = $enc->api("/api/portal/encarregado/me/educandos/$selectedId/ocorrencias");
            require $viewRoot . '/ocorrencias.php';
        })(),
        '/portal/encarregado/conta' => (function () use ($app, $portalEncarregado, $viewRoot, $selectedId, $selectedHash) {
            require $viewRoot . '/conta.php';
        })(),
        default => (function () { http_response_code(404); echo 'Página não encontrada.'; })(),
    };
} elseif (preg_match('#^/carreira/candidato/api/mensagens/(\d+)$#', $uri, $m) && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $app = Application::bootstrap();
    $app->carreira->apiEnviarMensagem((int) $m[1]);
    exit;
} elseif ($uri === '/carreira/candidato/api/perfil' && $_SERVER['REQUEST_METHOD'] === 'PUT') {
    $app = Application::bootstrap();
    $app->carreira->apiActualizarPerfil();
    exit;
} elseif (str_starts_with($uri, '/api/public/recrutamento/candidaturas') && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $app = Application::bootstrap();
    $app->publicApi->submitApplication();
} elseif (str_starts_with($uri, '/api/public/')) {
    // Proxy genérico (GET/POST/PUT) para o backend Go — reencaminha corpo JSON
    // e o cabeçalho Authorization, usado pelo portal do candidato autenticado.
    $app = Application::bootstrap();
    $app->publicApi->proxyJson($uri, $_SERVER['REQUEST_METHOD']);
} elseif ($uri === '/api/auth/login' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    // Login unificado (funcionário/aluno/encarregado/candidato) — proxy directo ao backend Go.
    $app = Application::bootstrap();
    $app->publicApi->proxyJson($uri, 'POST');
} elseif (str_starts_with($uri, '/api/')) {
    $app = Application::bootstrap();
    match (basename($uri, '.php')) {
        'contacto'    => $app->publicApi->submitContact(),
        'candidatura' => $app->publicApi->submitApplication(),
        default       => http_response_code(404),
    };
} else {
    $app = Application::bootstrap();
    $path = rtrim($uri, '/') ?: '/';
    match ($path) {
        '/vagas'                      => $app->carreira->render(),
        '/carreira'                   => $app->carreira->render(),
        '/carreira/estado'            => $app->carreira->estado(),
        '/carreira/candidato/login'        => $app->carreira->loginCandidato(),
        '/carreira/candidato/registar'     => $app->carreira->registarCandidato(),
        '/carreira/candidato/area'         => $app->carreira->areaCandidato(),
        '/carreira/candidato/candidaturas' => $app->carreira->candidaturasCandidato(),
        '/carreira/candidato/mensagens'    => $app->carreira->mensagensCandidato(),
        '/carreira/candidato/perfil'       => $app->carreira->perfilCandidato(),
        '/carreira/candidato/logout'       => $app->carreira->logoutCandidato(),
        default                       => $app->home->render(),
    };
}
