package tech.e258tech.nexora_assiduidade.utils

/**
 * Converte mensagens técnicas do FaceClock em orientações amigáveis ao utilizador.
 *
 * O FaceClock (FastAPI) devolve erros no campo `detail`, por exemplo:
 *   "Captura 1 invalida: low_quality_capture (score=0.51)."
 *
 * Esta classe extrai a razão e o score (quando disponível) e devolve uma mensagem
 * que ajuda o gestor/funcionário a corrigir a captura.
 */
object BiometricErrorParser {

    data class ParsedError(
        val rawMessage: String,
        val userMessage: String,
        val isRetryable: Boolean,
        val score: Float? = null
    )

    fun parse(rawMessage: String?): ParsedError {
        val raw = rawMessage?.trim()?.ifBlank { null } ?: "Erro desconhecido"
        val normalized = raw.lowercase()
        val score = extractScore(raw)

        return when {
            normalized.contains("low_quality_capture") ||
            normalized.contains("blurry_capture") -> ParsedError(
                rawMessage = raw,
                userMessage = buildString {
                    append("A foto ficou embaçada ou de baixa qualidade.")
                    append("\n\nDicas:")
                    append("\n• Limpe a lente da câmara")
                    append("\n• Aumente a iluminação do ambiente")
                    append("\n• Segure o telemóvel firme ao tirar a foto")
                    append("\n• Evite movimento durante a captura")
                    score?.let { append("\n\nScore de qualidade: ${String.format("%.2f", it)}") }
                },
                isRetryable = true,
                score = score
            )

            normalized.contains("poor_lighting") -> ParsedError(
                rawMessage = raw,
                userMessage = buildString {
                    append("A iluminação está fraca ou irregular.")
                    append("\n\nDicas:")
                    append("\n• Procure um local mais iluminado")
                    append("\n• Evite luz vinda de trás (contraluz)")
                    append("\n• Deixe a luz do rosto uniforme")
                    score?.let { append("\n\nScore de qualidade: ${String.format("%.2f", it)}") }
                },
                isRetryable = true,
                score = score
            )

            normalized.contains("face_too_small") -> ParsedError(
                rawMessage = raw,
                userMessage = "O rosto está muito pequeno na foto. Aproxime o telemóvel do funcionário.",
                isRetryable = true,
                score = score
            )

            normalized.contains("eyes_closed") -> ParsedError(
                rawMessage = raw,
                userMessage = "Os olhos parecem fechados na foto. Peça ao funcionário para abrir bem os olhos.",
                isRetryable = true,
                score = score
            )

            normalized.contains("nenhuma_face_detectada") -> ParsedError(
                rawMessage = raw,
                userMessage = "Nenhum rosto foi detectado. Posicione o rosto no centro do ecrã e certifique-se de que não está tapado.",
                isRetryable = true,
                score = score
            )

            normalized.contains("multiplas_faces_detectadas") -> ParsedError(
                rawMessage = raw,
                userMessage = "Foram detectadas várias faces. Apenas o funcionário deve estar em frente à câmara.",
                isRetryable = true,
                score = score
            )

            normalized.contains("liveness_failed") -> ParsedError(
                rawMessage = raw,
                userMessage = "Não foi possível confirmar que é uma pessoa real. Tente novamente sem usar fotos ou ecrãs.",
                isRetryable = true,
                score = score
            )

            else -> ParsedError(
                rawMessage = raw,
                userMessage = "Não foi possível cadastrar o rosto.\n\nDetalhe técnico: $raw",
                isRetryable = true,
                score = score
            )
        }
    }

    /**
     * Extrai o score numérico de mensagens como:
     *   "Captura 1 invalida: low_quality_capture (score=0.51)."
     * Retorna null se não encontrar.
     */
    private fun extractScore(message: String): Float? {
        val regex = Regex("""score=([0-9]+\\.?[0-9]*)""")
        val match = regex.find(message)
        return match?.groupValues?.get(1)?.toFloatOrNull()
    }
}
