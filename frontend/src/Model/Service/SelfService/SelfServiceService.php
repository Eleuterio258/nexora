<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\SelfService;

use E258Tech\Model\Contract\NexoraGateway;

final class SelfServiceService
{
    public function __construct(private readonly NexoraGateway $gateway) {}

    // ── Chat ─────────────────────────────────────────────────────────────────

    public function listarConversas(): array
    {
        $r = $this->gateway->request('GET', '/api/self-service/chat/conversas');
        return ['ok' => $r->status === 200, 'conversas' => $r->body ?? []];
    }

    public function criarConversa(string $tipo, ?string $nome, array $participantes): array
    {
        $r = $this->gateway->request('POST', '/api/self-service/chat/conversas', [
            'tipo' => $tipo, 'nome' => $nome, 'participantes' => $participantes,
        ]);
        return array_merge(['ok' => $r->status === 201], $r->body ?? []);
    }

    public function listarMensagens(int $conversaId): array
    {
        $r = $this->gateway->request('GET', "/api/self-service/chat/conversas/$conversaId/mensagens");
        return ['ok' => $r->status === 200, 'mensagens' => $r->body ?? []];
    }

    public function enviarMensagem(int $conversaId, string $conteudo): array
    {
        $r = $this->gateway->request('POST', "/api/self-service/chat/conversas/$conversaId/mensagens", [
            'conteudo' => $conteudo, 'tipo' => 'texto',
        ]);
        return array_merge(['ok' => in_array($r->status, [200, 201])], $r->body ?? []);
    }

    // ── Assiduidade ───────────────────────────────────────────────────────────

    public function criarJustificacao(string $tipo, string $data, string $motivo): array
    {
        $r = $this->gateway->request('POST', '/api/self-service/assiduidade/justificacoes', [
            'tipo' => $tipo, 'data' => $data, 'motivo' => $motivo,
        ]);
        return array_merge(['ok' => in_array($r->status, [200, 201])], $r->body ?? []);
    }

    // ── Perfil ────────────────────────────────────────────────────────────────

    public function actualizarPerfil(?string $nome, ?string $telefone): array
    {
        $r = $this->gateway->request('PUT', '/api/self-service/perfil/', array_filter([
            'nome' => $nome, 'telefone' => $telefone,
        ]));
        return ['ok' => $r->status === 204];
    }

    public function alterarSenha(string $senhaActual, string $senhaNova): array
    {
        $r = $this->gateway->request('POST', '/api/self-service/perfil/senha', [
            'senha_actual' => $senhaActual, 'senha_nova' => $senhaNova,
        ]);
        if ($r->status === 204) return ['ok' => true];
        return array_merge(['ok' => false], $r->body ?? []);
    }

    // ── Utilizadores (lista para chat) ────────────────────────────────────────

    public function listarUtilizadores(): array
    {
        $r = $this->gateway->request('GET', '/api/auth/utilizadores');
        $lista = [];
        if ($r->status === 200 && is_array($r->body)) {
            foreach ($r->body['data'] ?? $r->body as $u) {
                if (isset($u['id'], $u['nome'])) {
                    $lista[] = ['id' => $u['id'], 'nome' => $u['nome'], 'email' => $u['email'] ?? ''];
                }
            }
        }
        return ['ok' => true, 'utilizadores' => $lista];
    }
}
