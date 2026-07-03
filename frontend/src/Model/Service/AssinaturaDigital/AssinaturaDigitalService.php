<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\AssinaturaDigital;

use E258Tech\Http\BinaryResponse;
use E258Tech\Http\HttpResponse;
use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

final class AssinaturaDigitalService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    public function listarDocumentos(): array
    {
        return $this->ok($this->gateway->request('GET', '/api/assinatura-digital/documentos'));
    }

    public function obterDocumento(int $id): array
    {
        return $this->ok($this->gateway->request('GET', "/api/assinatura-digital/documentos/$id"));
    }

    public function uploadDocumento(string $titulo, string $descricao, array $file): array
    {
        if (empty($file['tmp_name']) || !is_readable($file['tmp_name'])) {
            throw new OperationException('Ficheiro inválido ou não encontrado.');
        }

        $res = $this->gateway->uploadMultipart('/api/assinatura-digital/documentos', [
            'titulo' => $titulo,
            'descricao' => $descricao,
        ], [
            'ficheiro' => $file,
        ]);

        if ($res['status'] < 200 || $res['status'] >= 300) {
            throw new OperationException($res['body']['error'] ?? 'Erro ao enviar documento.');
        }

        return $res['body'];
    }

    public function enviarDocumento(int $id): array
    {
        return $this->ok($this->gateway->request('POST', "/api/assinatura-digital/documentos/$id/enviar"));
    }

    public function cancelarDocumento(int $id): array
    {
        return $this->ok($this->gateway->request('POST', "/api/assinatura-digital/documentos/$id/cancelar"));
    }

    public function adicionarSignatario(int $docId, array $payload): array
    {
        return $this->ok($this->gateway->request('POST', "/api/assinatura-digital/documentos/$docId/signatarios", $payload));
    }

    public function removerSignatario(int $docId, int $sigId): array
    {
        return $this->ok($this->gateway->request('DELETE', "/api/assinatura-digital/documentos/$docId/signatarios/$sigId"));
    }

    public function assinarDocumento(int $docId, array $payload): array
    {
        return $this->ok($this->gateway->request('POST', "/api/assinatura-digital/documentos/$docId/assinar", $payload));
    }

    public function downloadDocumento(int $id): BinaryResponse
    {
        return $this->gateway->download("/api/assinatura-digital/documentos/$id/download");
    }

    private function ok(HttpResponse $response): array
    {
        $this->ensureSuccess($response, 'Erro ao executar a operação.');
        return $response->body ?? [];
    }
}
