<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\Tarefas;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;

final class TarefasService
{
    public function __construct(private readonly NexoraGateway $gateway) {}

    public function listQuadros(bool $arquivados = false): array
    {
        $r = $this->gateway->request('GET', '/api/tarefas/quadros', null, ['arquivado' => $arquivados ? '1' : '0']);
        $this->assertOk($r, 'Erro ao listar quadros.');
        return (array) ($r->body ?? []);
    }

    public function getQuadro(int $id): array
    {
        $r = $this->gateway->request('GET', "/api/tarefas/quadros/$id");
        if ($r->status === 404) {
            throw new OperationException('Quadro não encontrado.');
        }
        $this->assertOk($r, 'Erro ao obter quadro.');
        return (array) ($r->body ?? []);
    }

    public function saveQuadro(?int $id, array $payload): array
    {
        if ($id) {
            $r = $this->gateway->request('PUT', "/api/tarefas/quadros/$id", $payload);
            $this->assertOk($r, 'Erro ao actualizar quadro.');
            return ['ok' => true, 'id' => $id];
        }
        $r = $this->gateway->request('POST', '/api/tarefas/quadros', $payload);
        $this->assertOk($r, 'Erro ao criar quadro.');
        return array_merge(['ok' => true], (array) ($r->body ?? []));
    }

    public function deleteQuadro(int $id): array
    {
        $r = $this->gateway->request('DELETE', "/api/tarefas/quadros/$id");
        $this->assertOk($r, 'Erro ao eliminar quadro.');
        return ['ok' => true];
    }

    public function archiveQuadro(int $id): array
    {
        $r = $this->gateway->request('POST', "/api/tarefas/quadros/$id/arquivar");
        $this->assertOk($r, 'Erro ao arquivar quadro.');
        return ['ok' => true];
    }

    public function saveLista(?int $id, array $payload): array
    {
        if ($id) {
            $r = $this->gateway->request('PUT', "/api/tarefas/listas/$id", $payload);
            $this->assertOk($r, 'Erro ao actualizar lista.');
            return ['ok' => true, 'id' => $id];
        }
        $quadroId = (int) ($payload['quadro_id'] ?? 0);
        $r = $this->gateway->request('POST', "/api/tarefas/quadros/$quadroId/listas", $payload);
        $this->assertOk($r, 'Erro ao criar lista.');
        return array_merge(['ok' => true], (array) ($r->body ?? []));
    }

    public function deleteLista(int $id): array
    {
        $r = $this->gateway->request('DELETE', "/api/tarefas/listas/$id");
        $this->assertOk($r, 'Erro ao eliminar lista.');
        return ['ok' => true];
    }

    public function reorderListas(array $payload): array
    {
        $listaId = (int) ($payload['lista_id'] ?? 0);
        $r = $this->gateway->request('POST', "/api/tarefas/listas/$listaId/reordenar", $payload);
        $this->assertOk($r, 'Erro ao reordenar listas.');
        return ['ok' => true];
    }

    public function saveCartao(?int $id, array $payload): array
    {
        if ($id) {
            $r = $this->gateway->request('PUT', "/api/tarefas/cartoes/$id", $payload);
            $this->assertOk($r, 'Erro ao actualizar cartão.');
            return ['ok' => true, 'id' => $id];
        }
        $listaId = (int) ($payload['lista_id'] ?? 0);
        $r = $this->gateway->request('POST', "/api/tarefas/listas/$listaId/cartoes", $payload);
        $this->assertOk($r, 'Erro ao criar cartão.');
        return array_merge(['ok' => true], (array) ($r->body ?? []));
    }

    public function getCartao(int $id): array
    {
        $r = $this->gateway->request('GET', "/api/tarefas/cartoes/$id");
        if ($r->status === 404) {
            throw new OperationException('Cartão não encontrado.');
        }
        $this->assertOk($r, 'Erro ao obter cartão.');
        return (array) ($r->body ?? []);
    }

    public function moveCartao(int $id, array $payload): array
    {
        $r = $this->gateway->request('PUT', "/api/tarefas/cartoes/$id/mover", $payload);
        $this->assertOk($r, 'Erro ao mover cartão.');
        return ['ok' => true];
    }

    public function concludeCartao(int $id): array
    {
        $r = $this->gateway->request('POST', "/api/tarefas/cartoes/$id/concluir");
        $this->assertOk($r, 'Erro ao concluir cartão.');
        return ['ok' => true];
    }

    public function deleteCartao(int $id): array
    {
        $r = $this->gateway->request('DELETE', "/api/tarefas/cartoes/$id");
        $this->assertOk($r, 'Erro ao eliminar cartão.');
        return ['ok' => true];
    }

    private function assertOk(object $r, string $msg): void
    {
        if ($r->status >= 400) {
            $err = (string) ($r->body->error ?? $msg);
            throw new OperationException($err);
        }
    }
}
