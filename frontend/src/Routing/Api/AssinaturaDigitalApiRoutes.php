<?php
declare(strict_types=1);

namespace E258Tech\Routing\Api;

final class AssinaturaDigitalApiRoutes
{
    public static function endpoints(): array
    {
        return [
            'assinatura_digital_documento_listar'     => ['module' => 'assinatura-digital', 'action' => 'ver_documentos',  'method' => 'GET'],
            'assinatura_digital_documento_obter'      => ['module' => 'assinatura-digital', 'action' => 'ver_documentos',  'method' => 'GET'],
            'assinatura_digital_documento_upload'     => ['module' => 'assinatura-digital', 'action' => 'gerir_documentos'],
            'assinatura_digital_documento_enviar'     => ['module' => 'assinatura-digital', 'action' => 'gerir_documentos'],
            'assinatura_digital_documento_cancelar'   => ['module' => 'assinatura-digital', 'action' => 'gerir_documentos'],
            'assinatura_digital_signatario_adicionar' => ['module' => 'assinatura-digital', 'action' => 'gerir_documentos'],
            'assinatura_digital_signatario_remover'   => ['module' => 'assinatura-digital', 'action' => 'gerir_documentos'],
            'assinatura_digital_documento_assinar'    => ['module' => 'assinatura-digital', 'action' => 'gerir_documentos'],
            'assinatura_digital_documento_download'   => ['module' => 'assinatura-digital', 'action' => 'ver_documentos',  'method' => 'GET'],
        ];
    }
}
