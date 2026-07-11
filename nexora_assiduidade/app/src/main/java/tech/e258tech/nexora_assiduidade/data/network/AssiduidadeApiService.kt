package tech.e258tech.nexora_assiduidade.data.network

import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.POST
import retrofit2.http.Query
import tech.e258tech.nexora_assiduidade.data.model.AdjustmentRequestInput
import tech.e258tech.nexora_assiduidade.data.model.ClockRegisterRequest
import tech.e258tech.nexora_assiduidade.data.model.FaceVerifyRequest
import tech.e258tech.nexora_assiduidade.data.model.GeoValidateRequest
import tech.e258tech.nexora_assiduidade.data.model.LoginRequest
import tech.e258tech.nexora_assiduidade.data.model.NFCValidateRequest
import tech.e258tech.nexora_assiduidade.data.model.PinValidateRequest
import tech.e258tech.nexora_assiduidade.data.model.QRValidateRequest
import tech.e258tech.nexora_assiduidade.data.model.RefreshTokenRequest
import tech.e258tech.nexora_assiduidade.data.model.response.AdjustmentRequestResponse
import tech.e258tech.nexora_assiduidade.data.model.response.ClockRecordResponse
import tech.e258tech.nexora_assiduidade.data.model.response.FaceVerifyResponse
import tech.e258tech.nexora_assiduidade.data.model.response.GeoValidateResponse
import tech.e258tech.nexora_assiduidade.data.model.response.LoginResponse
import tech.e258tech.nexora_assiduidade.data.model.response.AuthCodeResponse
import tech.e258tech.nexora_assiduidade.data.model.response.NFCValidateResponse
import tech.e258tech.nexora_assiduidade.data.model.response.QRValidateResponse
import tech.e258tech.nexora_assiduidade.data.model.response.PaginatedAdjustmentRequestsResponse
import tech.e258tech.nexora_assiduidade.data.model.response.PaginatedClockRecordsResponse
import tech.e258tech.nexora_assiduidade.data.model.response.RefreshTokenResponse

interface AssiduidadeApiService {

    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): Response<LoginResponse>

    @POST("auth/refresh")
    suspend fun refreshToken(@Body request: RefreshTokenRequest): Response<RefreshTokenResponse>

    @POST("biometric/verify")
    suspend fun verifyFace(
        @Header("Authorization") token: String,
        @Body request: FaceVerifyRequest
    ): Response<FaceVerifyResponse>

    @POST("qr/validate")
    suspend fun validateQR(
        @Header("Authorization") token: String,
        @Body request: QRValidateRequest
    ): Response<QRValidateResponse>

    @POST("nfc/validate")
    suspend fun validateNFC(
        @Header("Authorization") token: String,
        @Body request: NFCValidateRequest
    ): Response<NFCValidateResponse>

    @POST("geolocation/validate")
    suspend fun validateGeolocation(
        @Header("Authorization") token: String,
        @Body request: GeoValidateRequest
    ): Response<GeoValidateResponse>

    @POST("authcode/pin/validate")
    suspend fun validatePin(
        @Header("Authorization") token: String,
        @Body request: PinValidateRequest
    ): Response<AuthCodeResponse>

    @POST("clock/register")
    suspend fun registerClock(
        @Header("Authorization") token: String,
        @Body request: ClockRegisterRequest
    ): Response<ClockRecordResponse>

    @GET("clock/me")
    suspend fun getMyClockRecords(
        @Header("Authorization") token: String,
        @Query("page") page: Int = 1,
        @Query("page_size") pageSize: Int = 20
    ): Response<PaginatedClockRecordsResponse>

    @POST("clock/adjustments")
    suspend fun createAdjustment(
        @Header("Authorization") token: String,
        @Body request: AdjustmentRequestInput
    ): Response<AdjustmentRequestResponse>

    @GET("clock/adjustments/me")
    suspend fun getMyAdjustments(
        @Header("Authorization") token: String,
        @Query("page") page: Int = 1,
        @Query("page_size") pageSize: Int = 20
    ): Response<PaginatedAdjustmentRequestsResponse>
}
