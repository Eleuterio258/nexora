package com.e258tech.factpro.emolasms

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.provider.Telephony
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView

class MainActivity : AppCompatActivity() {

    private lateinit var recyclerView: RecyclerView
    private lateinit var adapter: TransactionAdapter
    private lateinit var textoCaminho: TextView

    private val pedirPermissoes = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { resultados ->
        val concedidas = resultados.values.all { it }
        if (concedidas) {
            importarSmsExistentes()
        } else {
            Toast.makeText(this, "Permissao de SMS negada", Toast.LENGTH_LONG).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        recyclerView = findViewById(R.id.recyclerTransacoes)
        recyclerView.layoutManager = LinearLayoutManager(this)
        adapter = TransactionAdapter(mutableListOf())
        recyclerView.adapter = adapter

        textoCaminho = findViewById(R.id.textoCaminhoJson)
        textoCaminho.text = "JSON: ${TransactionStore.caminhoFicheiro(this)}"

        val botaoImportar = findViewById<Button>(R.id.botaoImportar)
        botaoImportar.setOnClickListener { verificarPermissoesEImportar() }

        atualizarLista()
    }

    override fun onResume() {
        super.onResume()
        atualizarLista()
    }

    private fun verificarPermissoesEImportar() {
        val permissoesNecessarias = arrayOf(
            Manifest.permission.READ_SMS,
            Manifest.permission.RECEIVE_SMS
        )
        val faltam = permissoesNecessarias.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (faltam.isEmpty()) {
            importarSmsExistentes()
        } else {
            pedirPermissoes.launch(faltam.toTypedArray())
        }
    }

    private fun importarSmsExistentes() {
        val uri = Telephony.Sms.Inbox.CONTENT_URI
        val projecao = arrayOf(Telephony.Sms.ADDRESS, Telephony.Sms.BODY, Telephony.Sms.DATE)
        val cursor = contentResolver.query(uri, projecao, null, null, "${Telephony.Sms.DATE} DESC")

        var novas = 0
        cursor?.use {
            val idxEndereco = it.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)
            val idxCorpo = it.getColumnIndexOrThrow(Telephony.Sms.BODY)
            val idxData = it.getColumnIndexOrThrow(Telephony.Sms.DATE)

            while (it.moveToNext()) {
                val remetente = it.getString(idxEndereco) ?: continue
                if (!EmolaSmsParser.ehEmola(remetente)) continue

                val corpo = it.getString(idxCorpo) ?: continue
                val dataMs = it.getLong(idxData)

                val transacao = EmolaSmsParser.parse(remetente, corpo, dataMs)
                if (TransactionStore.adicionar(this, transacao)) {
                    novas++
                }
            }
        }

        Toast.makeText(this, "$novas nova(s) transacao(oes) importada(s)", Toast.LENGTH_LONG).show()
        atualizarLista()
    }

    private fun atualizarLista() {
        adapter.atualizar(TransactionStore.carregar(this))
    }
}
