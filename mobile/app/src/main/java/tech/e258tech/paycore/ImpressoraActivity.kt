package tech.e258tech.paycore

import android.Manifest
import android.os.Bundle
import android.widget.ImageButton
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.TextView
import android.widget.Toast
import androidx.annotation.RequiresPermission
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.google.android.material.button.MaterialButton
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class ImpressoraActivity : AppCompatActivity() {

    private var selectedAddress: String = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.WHITE
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }

        setContentView(R.layout.activity_impressora)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.header_impressora)) { view, insets ->
            val sb = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, sb.top, view.paddingRight, view.paddingBottom)
            insets
        }

        selectedAddress = PosStore.savedPrinterAddress

        findViewById<ImageButton>(R.id.btn_voltar).setOnClickListener { finish() }

        popularDispositivos()
        atualizarImpressoraAtual()

        findViewById<MaterialButton>(R.id.btn_guardar_impressora).setOnClickListener {
            guardarSelecao()
        }

        findViewById<MaterialButton>(R.id.btn_testar_impressora).setOnClickListener {
            testarImpressao()
        }
    }

    @Suppress("MissingPermission")
    private fun popularDispositivos() {
        val dispositivos = BluetoothPrinterHelper.dispositivosVinculados()
        val radioGroup = findViewById<RadioGroup>(R.id.rg_impressoras)
        val tvSem = findViewById<TextView>(R.id.tv_sem_dispositivos)

        if (dispositivos.isEmpty()) {
            tvSem.visibility = android.view.View.VISIBLE
            radioGroup.visibility = android.view.View.GONE
            return
        }

        dispositivos.forEach { device ->
            val rb = RadioButton(this).apply {
                text = if (!device.name.isNullOrBlank()) "${device.name}\n${device.address}"
                       else device.address
                tag  = device.address
                setPadding(48, 32, 48, 32)
                setTextColor(getColor(R.color.text_primary))
                textSize = 14f
                isChecked = device.address == selectedAddress
            }
            radioGroup.addView(rb)
        }

        radioGroup.setOnCheckedChangeListener { group, checkedId ->
            val rb = group.findViewById<RadioButton>(checkedId)
            selectedAddress = rb?.tag as? String ?: ""
        }
    }

    private fun guardarSelecao() {
        val resultado = findViewById<TextView>(R.id.tv_impressora_resultado)
        if (selectedAddress.isEmpty()) {
            resultado.text = "Selecione um dispositivo primeiro."
            resultado.visibility = android.view.View.VISIBLE
            return
        }
        PosStore.salvarImpressora(selectedAddress)
        atualizarImpressoraAtual()
        resultado.text = "Impressora guardada."
        resultado.visibility = android.view.View.VISIBLE
        Toast.makeText(this, "Impressora guardada", Toast.LENGTH_SHORT).show()
    }

    @Suppress("MissingPermission")
    private fun testarImpressao() {
        val resultado = findViewById<TextView>(R.id.tv_impressora_resultado)
        val address = selectedAddress.ifEmpty { PosStore.savedPrinterAddress }

        if (address.isEmpty()) {
            resultado.text = "Selecione ou guarde uma impressora primeiro."
            resultado.visibility = android.view.View.VISIBLE
            return
        }

        val device = BluetoothPrinterHelper.dispositivosVinculados()
            .firstOrNull { it.address == address }

        if (device == null) {
            resultado.text = "Dispositivo não encontrado. Verifique o Bluetooth."
            resultado.visibility = android.view.View.VISIBLE
            return
        }

        resultado.text = "A enviar teste..."
        resultado.visibility = android.view.View.VISIBLE

        CoroutineScope(Dispatchers.IO).launch {
            val res = BluetoothPrinterHelper.testarImpressora(device)
            withContext(Dispatchers.Main) {
                if (res.isSuccess) {
                    resultado.text = "Teste enviado com sucesso."
                    Toast.makeText(this@ImpressoraActivity, "Teste enviado", Toast.LENGTH_SHORT).show()
                } else {
                    resultado.text = "Erro: ${res.exceptionOrNull()?.message ?: "falha na ligação"}"
                }
            }
        }
    }

    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    private fun atualizarImpressoraAtual() {
        val tv = findViewById<TextView>(R.id.tv_impressora_atual)
        val address = PosStore.savedPrinterAddress
        if (address.isEmpty()) {
            tv.text = "Nenhuma impressora guardada."
        } else {
            val nome = BluetoothPrinterHelper.dispositivosVinculados()
                .firstOrNull { it.address == address }
                ?.name?.takeIf { !it.isNullOrBlank() } ?: address
            tv.text = "Impressora atual: $nome"
        }
    }
}
