package tech.e258tech.paycore.ui

import android.Manifest
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.google.android.material.button.MaterialButton
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout
import com.google.gson.Gson
import com.journeyapps.barcodescanner.ScanContract
import com.journeyapps.barcodescanner.ScanOptions
import tech.e258tech.paycore.DashboardActivity
import tech.e258tech.paycore.R
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.PosLoginRequest
import tech.e258tech.paycore.api.PosLoginResponse
import tech.e258tech.paycore.utils.ApiErrorParser
import kotlinx.coroutines.launch

/**
 * Activity de Login do Terminal
 * Suporta login manual (serial + código) e login via QR Code.
 * O QR deve conter JSON: {"serialNumber":"...","activationCode":"..."}
 */
class LoginTerminalActivity : AppCompatActivity() {

    companion object {
        const val PREFS_TERMINAL    = "terminal_prefs"
        const val KEY_TERMINAL_ID   = "terminal_id"
        const val KEY_TERMINAL_SERIAL = "terminal_serial"
        const val KEY_TERMINAL_NOME = "terminal_nome"
        const val KEY_TENANT_ID     = "tenant_id"
        const val KEY_TENANT_NOME   = "tenant_name"
        const val KEY_IS_LOGGED     = "is_terminal_logged"
    }

    private lateinit var etSerialNumber: TextInputEditText
    private lateinit var etActivationCode: TextInputEditText
    private lateinit var tilSerialNumber: TextInputLayout
    private lateinit var tilActivationCode: TextInputLayout
    private lateinit var btnLoginTerminal: MaterialButton
    private lateinit var btnScanQr: MaterialButton
    private lateinit var tvErroLogin: TextView
    private lateinit var tvSucessoLogin: TextView
    private lateinit var progressLogin: View

    private lateinit var prefs: SharedPreferences

    // ── QR scanner launcher ───────────────────────────────────────────────────

    private val qrLauncher = registerForActivityResult(ScanContract()) { result ->
        if (result.contents != null) {
            handleQrResult(result.contents)
        }
    }

    // A CAMERA está declarada no manifesto, mas desde o Android 6 isso não
    // chega: sem o pedido em runtime o utilizador nunca chega a ver a câmara.
    private val cameraLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { concedida ->
        if (concedida) {
            abrirScanner()
        } else {
            mostrarErro(getString(R.string.login_terminal_qr_sem_camara))
        }
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_login_terminal)
        hideStatusBar()

        prefs = getSharedPreferences(PREFS_TERMINAL, MODE_PRIVATE)

        setupViews()
        setupListeners()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideStatusBar()
    }

    private fun hideStatusBar() {
        window.insetsController?.let {
            it.hide(WindowInsets.Type.statusBars())
            it.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
    }

    // ── Setup ─────────────────────────────────────────────────────────────────

    private fun setupViews() {
        etSerialNumber   = findViewById(R.id.et_serial_number)
        etActivationCode = findViewById(R.id.et_activation_code)
        tilSerialNumber  = findViewById(R.id.til_serial_number)
        tilActivationCode = findViewById(R.id.til_activation_code)
        btnLoginTerminal = findViewById(R.id.btn_login_terminal)
        btnScanQr        = findViewById(R.id.btn_scan_qr)
        tvErroLogin      = findViewById(R.id.tv_erro_login)
        tvSucessoLogin   = findViewById(R.id.tv_sucesso_login)
        progressLogin    = findViewById(R.id.progress_login)

        tvErroLogin.visibility   = View.GONE
        tvSucessoLogin.visibility = View.GONE
        progressLogin.visibility  = View.GONE

        // Dados fictícios para testes em debug
        if (tech.e258tech.paycore.BuildConfig.DEBUG) {
            etSerialNumber.setText("QBS-CAIXA2")
            etActivationCode.setText("MXNC-K44S-X2ZQ")
        }
    }

    private fun setupListeners() {
        btnLoginTerminal.setOnClickListener { realizarLogin() }

        btnScanQr.setOnClickListener { pedirCamaraEabrirScanner() }

        etSerialNumber.setOnFocusChangeListener { _, hasFocus ->
            if (hasFocus) {
                tilSerialNumber.error = null
                tvErroLogin.visibility = View.GONE
            }
        }

        etActivationCode.setOnFocusChangeListener { _, hasFocus ->
            if (hasFocus) {
                tilActivationCode.error = null
                tvErroLogin.visibility = View.GONE
            }
        }

        findViewById<TextView>(R.id.tv_ajuda).setOnClickListener { mostrarAjuda() }
    }

    // ── QR handling ───────────────────────────────────────────────────────────

    /** Garante a câmara antes de abrir o leitor. */
    private fun pedirCamaraEabrirScanner() {
        val concedida = ContextCompat.checkSelfPermission(
            this, Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED

        if (concedida) {
            abrirScanner()
        } else {
            cameraLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    private fun abrirScanner() {
        val options = ScanOptions().apply {
            setPrompt(getString(R.string.login_terminal_qr_prompt))
            setBeepEnabled(true)
            setOrientationLocked(true)
            setBarcodeImageEnabled(false)
            // Só QR: sem isto o leitor aceita qualquer código de barras e
            // devolve conteúdo que o handleQrResult vai rejeitar como inválido.
            setDesiredBarcodeFormats(ScanOptions.QR_CODE)
        }
        qrLauncher.launch(options)
    }

    private data class QrPayload(
        val serialNumber: String? = null,
        val activationCode: String? = null
    )

    private fun handleQrResult(content: String) {
        try {
            val payload = Gson().fromJson(content, QrPayload::class.java)
            if (payload?.serialNumber.isNullOrBlank() || payload?.activationCode.isNullOrBlank()) {
                mostrarErro(getString(R.string.login_terminal_qr_invalido))
                return
            }
            // Preencher campos e fazer login automaticamente
            etSerialNumber.setText(payload.serialNumber)
            etActivationCode.setText(payload.activationCode)
            realizarLogin()
        } catch (e: Exception) {
            mostrarErro(getString(R.string.login_terminal_qr_invalido))
        }
    }

    // ── Login ─────────────────────────────────────────────────────────────────

    private fun realizarLogin() {
        val codigoTerminal = etSerialNumber.text.toString().trim()
        val activationCode = etActivationCode.text.toString().trim()

        if (codigoTerminal.isEmpty()) {
            tilSerialNumber.error = getString(R.string.login_terminal_erro_serial_obrigatorio)
            etSerialNumber.requestFocus()
            return
        }

        if (activationCode.isEmpty()) {
            tilActivationCode.error = getString(R.string.login_terminal_erro_codigo_obrigatorio)
            etActivationCode.requestFocus()
            return
        }

        // Não se valida o formato do código: no ERP ele é a password da conta
        // do terminal, guardada em bcrypt, e quem cria o terminal escolhe-a
        // livremente. Impor aqui um formato — como os 6 dígitos que este ecrã
        // exigia — deixava de fora qualquer terminal criado pelo ERP com outro
        // código, sem o pedido sequer chegar ao servidor.

        tvErroLogin.visibility   = View.GONE
        tvSucessoLogin.visibility = View.GONE
        setLoading(true)

        lifecycleScope.launch {
            try {
                val request  = PosLoginRequest(
                    tipo = "terminal",
                    codigoTerminal = codigoTerminal,
                    activationCode = activationCode
                )
                val response = ApiClient.service.posLogin(request)
                val body = response.body()

                if (response.isSuccessful && body?.terminalToken != null) {
                    handleLoginSucesso(body)
                } else {
                    val parsed = ApiErrorParser.parse(response)
                    handleLoginErro(response.code(), parsed.userMessage)
                }
            } catch (e: Exception) {
                e.printStackTrace()
                handleLoginErro(0, e.message ?: getString(R.string.login_terminal_erro_generico))
            } finally {
                setLoading(false)
            }
        }
    }

    // ── Handlers ──────────────────────────────────────────────────────────────

    private fun handleLoginSucesso(response: PosLoginResponse) {
        val terminal = response.terminal
        val terminalToken = response.terminalToken ?: return

        // Guardar configuração do device (terminal + tenant). O token técnico do
        // terminal é guardado apenas para chamadas técnicas raras; o token ativo
        // do app continua sendo o do funcionário (quando houver).
        val editor = prefs.edit()
        editor.putString(KEY_TERMINAL_ID,    terminal?.id?.toString())
        editor.putString(KEY_TERMINAL_SERIAL, terminal?.codigo)
        editor.putString(KEY_TERMINAL_NOME,  terminal?.nome)
        editor.putString(KEY_TENANT_ID,      response.tenant?.id?.toString())
        editor.putString(KEY_TENANT_NOME,    response.tenant?.name ?: "")
        editor.putBoolean(KEY_IS_LOGGED,     true)
        editor.putLong("token_expires_at",   System.currentTimeMillis() + (response.expiresIn * 1000L))
        editor.apply()

        // NÃO sobrescrever o access token ativo do funcionário.
        ApiClient.saveTerminalToken(terminalToken)
        response.terminalRefreshToken?.let { ApiClient.saveTerminalRefreshToken(it) }
        tech.e258tech.paycore.utils.TerminalTokenManager.saveTerminalToken(this, terminalToken)

        tech.e258tech.paycore.repository.SessionRepository.terminalId   = terminal?.id?.toString() ?: ""
        tech.e258tech.paycore.repository.SessionRepository.terminalNome = terminal?.nome ?: ""
        tech.e258tech.paycore.repository.SessionRepository.tenantId     = response.tenant?.id?.toString() ?: ""

        tvSucessoLogin.text       = getString(R.string.login_terminal_sucesso)
        tvSucessoLogin.visibility = View.VISIBLE

        // Após ativar o terminal, o próximo passo é autenticar um funcionário.
        android.os.Handler(mainLooper).postDelayed({
            val intent = Intent(this@LoginTerminalActivity, tech.e258tech.paycore.LoginActivity::class.java)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            startActivity(intent)
            finish()
        }, 1000)
    }

    private fun handleLoginErro(code: Int, message: String) {
        val errorMessage = when (code) {
            401  -> getString(R.string.login_terminal_erro_credenciais)
            403  -> getString(R.string.login_terminal_erro_terminal_inativo)
            else -> message
        }
        mostrarErro(errorMessage)
        Toast.makeText(this, errorMessage, Toast.LENGTH_LONG).show()
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun mostrarErro(msg: String) {
        tvErroLogin.text       = msg
        tvErroLogin.visibility = View.VISIBLE
    }

    private fun setLoading(loading: Boolean) {
        btnLoginTerminal.isEnabled = !loading
        btnScanQr.isEnabled        = !loading
        progressLogin.visibility   = if (loading) View.VISIBLE else View.GONE
    }

    private fun mostrarAjuda() {
        Toast.makeText(
            this,
            "O código de ativação é fornecido pelo administrador no painel web.\n\n" +
            "1. Acesse o painel administrativo\n" +
            "2. Vá em Terminais > Criar Terminal\n" +
            "3. Anote o código de ativação gerado\n" +
            "4. Insira neste formulário ou gere o QR Code",
            Toast.LENGTH_LONG
        ).show()
    }

    @Deprecated("Deprecated in Java")
    @Suppress("MissingSuperCall")
    override fun onBackPressed() {
        // Durante a ativação do terminal, permitir voltar para o onboarding/login.
        super.onBackPressed()
    }
}
