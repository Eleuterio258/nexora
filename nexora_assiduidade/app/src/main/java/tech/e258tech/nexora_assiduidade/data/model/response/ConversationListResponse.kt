package tech.e258tech.nexora_assiduidade.data.model.response

import tech.e258tech.nexora_assiduidade.data.model.chat.Conversation

/**
 * Resposta do endpoint GET /chat/conversas.
 * O backend retorna a lista diretamente (jsonOK).
 */
typealias ConversationListResponse = List<Conversation>
