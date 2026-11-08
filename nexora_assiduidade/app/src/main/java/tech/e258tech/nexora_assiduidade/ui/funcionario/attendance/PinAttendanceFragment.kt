package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.ImageButton
import android.widget.Toast
import androidx.fragment.app.Fragment
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.repository.AttendanceRepository

/**
 * Tela de registo de presenca por PIN.
 *
 * O utilizador seleciona Entrada/Saida, digita o PIN e o codigo e validado
 * directamente no Nexora ERP via POST /api/authcode/pin/validate (deixou de
 * passar pelo proxy do FaceClock em 2026-07-12) — devolve um login completo
 * (tokens+utilizador), tal como /api/auth/login, por isso a sessao e
 * actualizada com o resultado antes de registar o ponto.
 */
class PinAttendanceFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var attendanceRepository: AttendanceRepository

    private lateinit var etPin: EditText
    private lateinit var btnValidatePin: Button
    private lateinit var pinDots: List<View>

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_pin_attendance, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        attendanceRepository = AttendanceRepository(requireContext())

        etPin = view.findViewById(R.id.etPin)
        btnValidatePin = view.findViewById(R.id.btnValidatePin)

        // setShowSoftInputOnFocus é público desde a API 21, mas o atributo XML
        // equivalente (android:showSoftInputOnFocus) é @hide — não existe no SDK
        // público, o aapt2 rejeita-o no layout. Por isso só dá para fazer aqui.
        etPin.setShowSoftInputOnFocus(false)

        setupTecladoNumerico(view)

        btnValidatePin.setOnClickListener {
            val pin = etPin.text.toString().trim()
            if (pin.length < 4) {
                Toast.makeText(context, "PIN deve ter pelo menos 4 digitos", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            validatePinAndRegister(pin)
        }

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }
    }

    /**
     * Teclado numérico próprio (ver funcionario_pin_attendance.xml) — etPin nunca ganha
     * foco do teclado do sistema (focusable=false/showSoftInputOnFocus=false), por isso
     * é este teclado que escreve/apaga o texto directamente.
     */
    private fun setupTecladoNumerico(view: View) {
        val maxLength = 6 // mesmo valor de android:maxLength no layout

        pinDots = listOf(
            R.id.pinDot1, R.id.pinDot2, R.id.pinDot3,
            R.id.pinDot4, R.id.pinDot5, R.id.pinDot6
        ).map { view.findViewById(it) }

        val botoesDigitos = mapOf(
            R.id.btnKey0 to "0", R.id.btnKey1 to "1", R.id.btnKey2 to "2",
            R.id.btnKey3 to "3", R.id.btnKey4 to "4", R.id.btnKey5 to "5",
            R.id.btnKey6 to "6", R.id.btnKey7 to "7", R.id.btnKey8 to "8",
            R.id.btnKey9 to "9"
        )
        botoesDigitos.forEach { (id, digito) ->
            view.findViewById<Button>(id).setOnClickListener {
                if (etPin.text.length < maxLength) {
                    etPin.append(digito)
                    atualizarPontosPin()
                }
            }
        }

        view.findViewById<ImageButton>(R.id.btnBackspace).setOnClickListener {
            val texto = etPin.text
            if (texto.isNotEmpty()) {
                etPin.text = texto.delete(texto.length - 1, texto.length)
                atualizarPontosPin()
            }
        }
    }

    /** Preenche/esvazia os pontos visuais conforme o nº de dígitos já em [etPin] —
     * chamado directamente a seguir a cada toque no teclado (não há TextWatcher: todas
     * as mutações de etPin já passam por [setupTecladoNumerico]). */
    private fun atualizarPontosPin() {
        val digitados = etPin.text.length
        pinDots.forEachIndexed { index, dot ->
            dot.setBackgroundResource(
                if (index < digitados) R.drawable.bg_pin_dot_filled else R.drawable.bg_pin_dot_empty
            )
        }
    }

    /**
     * Marca o ponto por PIN num unico pedido: o ERP verifica o PIN e grava o
     * evento na mesma transaccao (POST /api/self-service/assiduidade/ponto).
     * Antes havia um login por PIN seguido de um registo separado pela rota de
     * hardware, que um cliente modificado podia saltar.
     */
    private fun validatePinAndRegister(pin: String) {
        btnValidatePin.isEnabled = false

        uiScope.launch {
            val registerResult = withContext(Dispatchers.IO) {
                attendanceRepository.marcarPonto(
                    metodo = AttendanceRepository.Metodo.PIN,
                    pin = pin
                )
            }

            btnValidatePin.isEnabled = true

            when (registerResult) {
                is AttendanceRepository.RegisterResult.Success -> {
                    Toast.makeText(context, "Registo de presença realizado com sucesso.", Toast.LENGTH_SHORT).show()
                    parentFragmentManager.popBackStack()
                }
                is AttendanceRepository.RegisterResult.SavedOffline -> {
                    Toast.makeText(
                        context,
                        "Sem internet. O registo e o PIN serão verificados quando houver ligação.",
                        Toast.LENGTH_LONG
                    ).show()
                    parentFragmentManager.popBackStack()
                }
                is AttendanceRepository.RegisterResult.Error -> {
                    etPin.text.clear()
                    atualizarPontosPin()
                    Toast.makeText(context, registerResult.message, Toast.LENGTH_LONG).show()
                }
            }
        }
    }
}
