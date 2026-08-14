package tech.e258tech.paycore

import android.os.Bundle
import android.widget.ImageButton
import androidx.appcompat.app.AppCompatActivity

class ClientesActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_clientes)

        findViewById<ImageButton>(R.id.btn_menu).setOnClickListener { finish() }
        findViewById<ImageButton>(R.id.btn_novo_cliente).setOnClickListener {
            // TODO: abrir formulário de novo cliente
        }
    }

}





