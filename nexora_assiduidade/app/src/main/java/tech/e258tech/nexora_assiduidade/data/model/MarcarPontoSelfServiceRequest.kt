package tech.e258tech.nexora_assiduidade.data.model

data class MarcarPontoSelfServiceRequest(
    val metodo: String,
    val dados: SelfiePontoDados
)

data class MarcarPontoFacialSelfServiceRequest(
    val metodo: String = "facial",
    val dados: FacialPontoDados
)

data class FacialPontoDados(
    val verification_token: String,
    val device_id: String
)

data class SelfiePontoDados(
    val latitude: Double,
    val longitude: Double,
    val foto_url: String
)

data class MarcarPontoNfcSelfServiceRequest(
    val metodo: String = "nfc",
    val dados: NfcPontoDados
)

data class NfcPontoDados(
    val nfc_tag_id: String
)

data class MarcarPontoQrSelfServiceRequest(
    val metodo: String = "qr_code",
    val dados: QrPontoDados
)

data class QrPontoDados(
    val qr_code: String
)
