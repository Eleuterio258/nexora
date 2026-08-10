<?php

declare(strict_types=1);

namespace E258Tech\Infrastructure\Nexora;

/**
 * Gera cabeçalhos de assinatura HMAC-SHA256 para identificação de tenant
 * nos endpoints públicos do Nexora ERP.
 *
 * Contrato (espelha o backend em internal/modules/recrutamento/handlers/tenant_signature.go):
 *
 *   X-Tenant-Code:      código do tenant (saas.tenants.codigo)
 *   X-Tenant-Timestamp: unix seconds do pedido
 *   X-Tenant-Signature: hex(HMAC-SHA256(segredo, "<codigo>.<timestamp>.<method>.<path>"))
 *
 * Se NENHUM segredo estiver configurado, as chamadas públicas continuam a usar
 * X-Forwarded-Host (mecanismo de transição/desenvolvimento).
 */
final class TenantSignature
{
    public function __construct(
        private readonly ?string $tenantCode,
        private readonly ?string $tenantSecret
    ) {
    }

    /**
     * @return array<int, string> cabeçalhos HTTP a adicionar ao pedido
     */
    public function headers(string $method, string $path): array
    {
        if ($this->tenantCode === null || $this->tenantCode === ''
            || $this->tenantSecret === null || $this->tenantSecret === '') {
            return [];
        }

        $timestamp = (string) time();
        $message = $this->tenantCode . '.' . $timestamp . '.' . strtoupper($method) . '.' . $path;
        $signature = hash_hmac('sha256', $message, $this->tenantSecret);

        return [
            'X-Tenant-Code: ' . $this->tenantCode,
            'X-Tenant-Timestamp: ' . $timestamp,
            'X-Tenant-Signature: ' . $signature,
        ];
    }

    public function isConfigured(): bool
    {
        return ($this->tenantCode ?? '') !== '' && ($this->tenantSecret ?? '') !== '';
    }
}
