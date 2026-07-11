package tech.e258tech.nexora_assiduidade.ui.common

import com.journeyapps.barcodescanner.CaptureActivity

/**
 * Atividade de captura de QR Code em modo retrato.
 *
 * A biblioteca journeyapps/zxing-android-embedded utiliza por defeito uma
 * atividade paisagem. Esta classe permite manter a orientacao preferida da app.
 */
class CaptureActivityPortrait : CaptureActivity()
