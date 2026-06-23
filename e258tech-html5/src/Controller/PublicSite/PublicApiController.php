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

        $name = $this->security->sanitize($this->request->postString('nome'), 150);
        $phone = $this->security->sanitize($this->request->postString('telefone'), 30);
        $vacancyId = $this->request->postInt('vaga_id');
        $vacancyTitle = $this->security->sanitize($this->request->postString('vaga_titulo'), 200);
        $letter = $this->security->sanitize($this->request->postString('carta'), 3000);
        $email = $this->security->sanitizeEmail($this->request->postString('email'));
        $errors = [];

        if (strlen($name) < 2) {
            $errors[] = 'Nome inválido.';
        }
        if (!$email) {
            $errors[] = 'Email inválido.';
        }
        if ($vacancyTitle === '') {
            $errors[] = 'Vaga não identificada.';
        }
        if ($errors) {
            $this->security->jsonResponse(['erro' => implode(' ', $errors)], 422);
        }

        $response = $this->nexora->uploadPublicData(
            '/api/public/recrutamento/candidaturas',
            [
                'nome' => $name,
                'email' => $email,
                'telefone' => $phone,
                'vaga_id' => (string) ($vacancyId ?: ''),
                'vaga_titulo' => $vacancyTitle,
                'carta' => $letter,
            ],
            [
                'cv' => $this->request->file('cv'),
                'carta_ficheiro' => $this->request->file('carta_ficheiro'),
            ]
        );
        $this->respond($response, 'Erro ao guardar candidatura. Tente novamente.');
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
