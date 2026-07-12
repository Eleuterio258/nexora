package tech.e258tech.nexora_assiduidade.data.model

/**
 * Pedido de login directamente ao Nexora ERP (Fase 6 da integração —
 * o FaceClock deixou de ter login próprio, ver
 * assiduidade_system_backend/CONTRATO-INTEGRACAO-ERP.md secção 8.4).
 *
 * Contrato diferente do login antigo do FaceClock: `email`, não `username`
 * (ver backend/internal/modules/auth/handlers/auth.go:132).
 */
data class ErpLoginRequest(
    val email: String,
    val password: String
)
