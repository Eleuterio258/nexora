package tech.e258tech.nexora_assiduidade.data.model

/**
 * Payload para cadastro de biometria facial de um funcionário.
 * O enrollment é feito pelo gestor RH via ERP, que depois delega no FaceClock.
 */
data class EnrollFacialRequest(
    val captures: List<CaptureImage>
)
