<?php
declare(strict_types=1);

namespace E258Tech\Controller\PublicSite;

use E258Tech\Infrastructure\Nexora\NexoraClient;
use E258Tech\Infrastructure\Security\WebSecurity;
use E258Tech\Http\ServerRequest;

final readonly class PublicApiController
{
    public function __construct(
        private ServerRequest $request,
        private WebSecurity $security,
        private NexoraClient $nexora
    ) {
    }

    public function submitContact(): never
    {
        $this->requirePost();
        if (!$this->security->allow('contacto', 3, 60)) {
            $this->security->jsonResponse(['erro' => 'Demasiadas tentativas. Aguarde um momento.'], 429);
        }
        if (!$this->security->hasValidCsrf($this->request->csrfToken())) {
            $this->security->jsonResponse(['erro' => 'Token de segurança inválido.'], 403);
        }

        $name = $this->security->sanitize($this->request->postString('nome'), 150);
        $subject = $this->security->sanitize($this->request->postString('assunto'), 255);
        $message = $this->security->sanitize($this->request->postString('mensagem'), 2000);
        $email = $this->security->sanitizeEmail($this->request->postString('email'));
        $errors = [];

        if (strlen($name) < 2) {
            $errors[] = 'Nome inválido.';
        }
        if (!$email) {
            $errors[] = 'Email inválido.';
        }
        if (strlen($subject) < 3) {
            $errors[] = 'Assunto inválido.';
        }
        if (strlen($message) < 10) {
            $errors[] = 'Mensagem demasiado curta.';
        }
        if ($errors) {
            $this->security->jsonResponse(['erro' => implode(' ', $errors)], 422);
        }

        $response = $this->nexora->callPublic('POST', '/api/public/recrutamento/contacto', [
            'nome' => $name,
            'email' => $email,
            'assunto' => $subject,
            'mensagem' => $message,
        ]);
        $this->respond($response, 'Erro ao guardar. Tente novamente.');
    }

    public function submitApplication(): never
    {
        $this->requirePost();
        if (!$this->security->allow('candidatura', 2, 120)) {
            $this->security->jsonResponse(['erro' => 'Demasiadas tentativas. Aguarde dois minutos.'], 429);
        }
        if (!$this->security->hasValidCsrf($this->request->csrfToken())) {
            $this->security->jsonResponse(['erro' => 'Token de segurança inválido.'], 403);
        }

        // Passar todos os campos do formulário ao backend (excepto o token CSRF)
        $fields = [];
        foreach ($_POST as $key => $value) {
            if ($key === 'csrf_token') {
                continue;
            }
            $fields[$key] = is_array($value) ? implode(',', $value) : (string) $value;
        }

        // Passar todos os ficheiros enviados
        $files = [];
        foreach ($_FILES as $key => $file) {
            $files[$key] = $file;
        }

        $response = $this->nexora->uploadPublicData(
            '/api/public/recrutamento/candidaturas',
            $fields,
            $files
        );
        $this->respond($response, 'Erro ao guardar candidatura. Tente novamente.');
    }

    public function proxyGet(string $uri): never
    {
        $response = $this->nexora->callPublic('GET', $uri, null, $_GET);
        header('Content-Type: application/json');
        http_response_code($response['status'] ?: 200);
        echo json_encode($response['body']);
        exit;
    }

    private function respond(array $response, string $fallback): never
    {
        $this->security->jsonResponse(
            $response['body'] ?? ['erro' => $fallback],
            $response['status'] ?: 500
        );
    }

    private function requirePost(): void
    {
        if (!$this->request->isPost()) {
            $this->security->jsonResponse(['erro' => 'Metodo nao permitido.'], 405);
        }
    }
}
