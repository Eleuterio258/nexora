package tech.e258tech.nexora_assiduidade.data.network

import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.Header
import retrofit2.http.POST
import tech.e258tech.nexora_assiduidade.data.model.FaceVerifyRequest
import tech.e258tech.nexora_assiduidade.data.model.response.FaceVerifyResponse

/**
 * Endpoints que só existem no FaceClock — processamento biométrico local
 * (compara contra o template guardado na BD do FaceClock, o ERP não tem essa
 * capacidade). Todo o resto (login/PIN/TOTP, assiduidade própria, QR/NFC/
 * geolocalização/registo de ponto) passou a chamar o Nexora ERP directamente
 * (`ErpApiService`) desde 2026-07-13 — ver CONTRATO-INTEGRACAO-ERP.md.
 */
interface AssiduidadeApiService {

    @POST("biometric/verify")
    suspend fun verifyFace(
        @Header("Authorization") token: String,
        @Body request: FaceVerifyRequest
    ): Response<FaceVerifyResponse>
}
