package tech.e258tech.nexora_assiduidade.data.model

/**
 * Corpo comum de POST /api/self-service/notificacoes/lida e
 * POST /api/self-service/comunicados/lido (self-service/handlers/home.go).
 */
data class MarcarLidaRequest(val id: Long)
