package tech.e258tech.paycore

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.button.MaterialButton
import com.google.android.material.textfield.TextInputEditText

class EntradaManualActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_BARCODE = "barcode_result"
    }

    private lateinit var etCodigo: TextInputEditText
    private val codigo = StringBuilder()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_entrada_manual)

        etCodigo = findViewById(R.id.et_codigo)

        findViewById<android.widget.ImageButton>(R.id.btn_voltar).setOnClickListener {
            setResult(RESULT_CANCELED)
            finish()
        }

        // Teclas numéricas
        val teclas = mapOf(
            R.id.key_0 to "0", R.id.key_1 to "1", R.id.key_2 to "2",
            R.id.key_3 to "3", R.id.key_4 to "4", R.id.key_5 to "5",
            R.id.key_6 to "6", R.id.key_7 to "7", R.id.key_8 to "8",
            R.id.key_9 to "9"
        )
        teclas.forEach { (id, digit) ->
            findViewById<TextView>(id).setOnClickListener {
                codigo.append(digit)
                etCodigo.setText(codigo.toString())
                etCodigo.setSelection(codigo.length)
            }
        }

        // Backspace
        findViewById<ImageView>(R.id.key_del).setOnClickListener {
            if (codigo.isNotEmpty()) {
                codigo.deleteCharAt(codigo.lastIndex)
                etCodigo.setText(codigo.toString())
                etCodigo.setSelection(codigo.length)
            }
        }

        // Scanner — volta para a câmera
        findViewById<ImageView>(R.id.key_scan).setOnClickListener {
            setResult(Activity.RESULT_CANCELED)
            finish()
        }

        // Confirmar
        findViewById<MaterialButton>(R.id.btn_confirmar).setOnClickListener {
            val cod = codigo.toString().trim()
            if (cod.isNotEmpty()) {
                setResult(RESULT_OK, Intent().putExtra(EXTRA_BARCODE, cod))
                finish()
            }
        }
    }
}
