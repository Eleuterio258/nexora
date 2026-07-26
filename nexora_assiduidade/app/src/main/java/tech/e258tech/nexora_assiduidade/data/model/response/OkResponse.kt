package tech.e258tech.nexora_assiduidade.data.model.response

/** Resposta partilhada pelos endpoints CRM que só devolvem `{"ok":true}`
 * (mudar estado/estágio, marcar perdida, concluir atividade). */
data class OkResponse(val ok: Boolean)
