<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;

final class AssinaturaDigitalController
{
    public function assinaturaDigitalDocumentoListar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->assinaturaDigital->listarDocumentos());
    }

    public function assinaturaDigitalDocumentoObter(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->assinaturaDigital->obterDocumento((int) $request->int('id')));
    }

    public function assinaturaDigitalDocumentoUpload(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(function () use ($d, $request): array {
            $file = $_FILES['ficheiro'] ?? [];
            $titulo = $request->string('titulo') ?: ($file['name'] ?? 'Documento');
            $descricao = $request->string('descricao') ?? '';
            return $d->assinaturaDigital->uploadDocumento($titulo, $descricao, $file);
        });
    }

    public function assinaturaDigitalDocumentoEnviar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->assinaturaDigital->enviarDocumento((int) $request->int('id')));
    }

    public function assinaturaDigitalDocumentoCancelar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->assinaturaDigital->cancelarDocumento((int) $request->int('id')));
    }

    public function assinaturaDigitalSignatarioAdicionar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(function () use ($d, $request): array {
            $id = (int) $request->int('id');
            $payload = [
                'nome' => $request->string('nome'),
                'email' => $request->string('email') ?: null,
                'nuit' => $request->string('nuit') ?: null,
                'bi' => $request->string('bi') ?: null,
                'telefone' => $request->string('telefone') ?: null,
                'ordem' => $request->int('ordem') ?? 1,
                'tipo' => $request->string('tipo') ?: null,
                'pagina' => $request->int('pagina'),
                'x' => $request->float('x'),
                'y' => $request->float('y'),
                'largura' => $request->float('largura'),
                'altura' => $request->float('altura'),
            ];
            return $d->assinaturaDigital->adicionarSignatario($id, array_filter($payload, fn($v) => $v !== null));
        });
    }

    public function assinaturaDigitalSignatarioRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(function () use ($d, $request): array {
            $id = (int) $request->int('id');
            $sigId = (int) $request->int('sig_id');
            return $d->assinaturaDigital->removerSignatario($id, $sigId);
        });
    }

    public function assinaturaDigitalDocumentoAssinar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(function () use ($d, $request): array {
            $id = (int) $request->int('id');
            $payload = [
                'signatario_id' => $request->int('signatario_id'),
                'nome' => $request->string('nome'),
                'email' => $request->string('email') ?: null,
                'pin' => $request->string('pin') ?: null,
            ];
            return $d->assinaturaDigital->assinarDocumento($id, array_filter($payload, fn($v) => $v !== null));
        });
    }

    public function assinaturaDigitalDocumentoDownload(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(function () use ($d, $request): array {
            $id = (int) $request->int('id');
            $resp = $d->assinaturaDigital->downloadDocumento($id);
            return [
                'content_type' => $resp->contentType ?: 'application/pdf',
                'pdf' => base64_encode($resp->body),
            ];
        });
    }

}
