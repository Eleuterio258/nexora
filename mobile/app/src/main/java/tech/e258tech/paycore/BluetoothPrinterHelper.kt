package tech.e258tech.paycore

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import tech.e258tech.paycore.api.ReciboResponse
import java.io.IOException
import java.io.OutputStream
import java.util.UUID

object BluetoothPrinterHelper {

    private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    private val ESC_INIT        = byteArrayOf(0x1B, 0x40)
    private val ALIGN_CENTER    = byteArrayOf(0x1B, 0x61, 0x01)
    private val ALIGN_LEFT      = byteArrayOf(0x1B, 0x61, 0x00)
    private val BOLD_ON         = byteArrayOf(0x1B, 0x45, 0x01)
    private val BOLD_OFF        = byteArrayOf(0x1B, 0x45, 0x00)
    private val DOUBLE_SIZE     = byteArrayOf(0x1D, 0x21, 0x11)
    private val NORMAL_SIZE     = byteArrayOf(0x1D, 0x21, 0x00)
    private val LF              = byteArrayOf(0x0A)
    private val CUT             = byteArrayOf(0x1D, 0x56, 0x42, 0x00)
    private val DIVIDER         = "--------------------------------\n"

    @Suppress("MissingPermission")
    fun dispositivosVinculados(): List<BluetoothDevice> {
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return emptyList()
        if (!adapter.isEnabled) return emptyList()
        return adapter.bondedDevices?.toList() ?: emptyList()
    }

    @Suppress("MissingPermission")
    fun testarImpressora(device: BluetoothDevice): Result<Unit> {
        var socket: BluetoothSocket? = null
        return try {
            socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
            BluetoothAdapter.getDefaultAdapter()?.cancelDiscovery()
            socket.connect()
            val out = socket.outputStream
            out.esc(ESC_INIT, ALIGN_CENTER, BOLD_ON)
            out.txt("PayCore POS\n")
            out.esc(BOLD_OFF)
            out.txt(DIVIDER)
            out.txt("Teste de impressao\n")
            out.txt("${java.text.SimpleDateFormat("dd/MM/yyyy HH:mm", java.util.Locale.getDefault()).format(java.util.Date())}\n")
            out.txt(DIVIDER)
            out.linha()
            out.linha()
            out.esc(CUT)
            out.flush()
            Result.success(Unit)
        } catch (e: IOException) {
            Result.failure(e)
        } finally {
            try { socket?.close() } catch (_: IOException) {}
        }
    }

    @Suppress("MissingPermission")
    fun imprimir(device: BluetoothDevice, transacao: TransacaoPDV): Result<Unit> {
        var socket: BluetoothSocket? = null
        return try {
            socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
            BluetoothAdapter.getDefaultAdapter()?.cancelDiscovery()
            socket.connect()
            val out = socket.outputStream
            enviarRecibo(out, transacao)
            out.flush()
            Result.success(Unit)
        } catch (e: IOException) {
            Result.failure(e)
        } finally {
            try { socket?.close() } catch (_: IOException) {}
        }
    }

    // Reimpressão a partir dos dados do servidor (ver ApiService.obterRecibo)
    // — usada quando a venda não existe (ou já não reflecte devoluções) no
    // Room local do aparelho que está a imprimir. Inclui o cabeçalho fiscal
    // da empresa, que o recibo local nunca teve.
    @Suppress("MissingPermission")
    fun imprimir(device: BluetoothDevice, recibo: ReciboResponse): Result<Unit> {
        var socket: BluetoothSocket? = null
        return try {
            socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
            BluetoothAdapter.getDefaultAdapter()?.cancelDiscovery()
            socket.connect()
            val out = socket.outputStream
            enviarReciboServidor(out, recibo)
            out.flush()
            Result.success(Unit)
        } catch (e: IOException) {
            Result.failure(e)
        } finally {
            try { socket?.close() } catch (_: IOException) {}
        }
    }

    private fun OutputStream.esc(vararg cmds: ByteArray) = cmds.forEach { write(it) }
    private fun OutputStream.txt(s: String) = write(s.toByteArray(Charsets.UTF_8))
    private fun OutputStream.linha() = write(LF)

    private fun enviarRecibo(out: OutputStream, t: TransacaoPDV) {
        out.esc(ESC_INIT)

        // Cabecalho
        out.esc(ALIGN_CENTER, BOLD_ON, DOUBLE_SIZE)
        out.txt("PayCore POS\n")
        out.esc(NORMAL_SIZE, BOLD_OFF)
        out.txt(DIVIDER)

        // Dados da transacao
        out.esc(ALIGN_LEFT)
        out.txt("Referencia: ${t.referencia}\n")
        out.txt("Data/Hora : ${PosStore.formatarDataHora(t.dataHora)}\n")
        out.txt("Metodo    : ${t.metodo}\n")
        out.txt("Operador  : ${t.operadorNome}\n")
        out.txt("Estado    : ${t.estado}\n")

        // Itens
        out.txt(DIVIDER)
        for (item in t.itens) {
            val desc  = "${item.quantidade}x ${item.nome}".take(20).padEnd(20)
            val valor = PosStore.formatarValor(item.quantidade * item.precoUnitario).padStart(12)
            out.txt("$desc$valor\n")
        }
        out.txt(DIVIDER)

        // Subtotal / Desconto / Total
        if (t.desconto > 0) {
            out.txt("${"Subtotal".padEnd(20)}${PosStore.formatarValor(t.subtotal).padStart(12)}\n")
            out.txt("${"Desconto".padEnd(20)}${("-" + PosStore.formatarValor(t.desconto)).padStart(12)}\n")
        }
        out.esc(BOLD_ON)
        out.txt("${"TOTAL".padEnd(20)}${PosStore.formatarValor(t.total).padStart(12)}\n")
        out.esc(BOLD_OFF)

        // Rodape
        out.txt(DIVIDER)
        out.esc(ALIGN_CENTER)
        out.txt("Obrigado pela preferencia!\n")
        out.linha()
        out.linha()
        out.linha()
        out.esc(CUT)
    }

    private fun enviarReciboServidor(out: OutputStream, r: ReciboResponse) {
        val venda = r.venda
        out.esc(ESC_INIT)

        // Cabecalho — nome/NUIT/endereco da empresa, quando configurados.
        out.esc(ALIGN_CENTER, BOLD_ON, DOUBLE_SIZE)
        out.txt("${r.empresa.nome.ifBlank { "PayCore POS" }}\n")
        out.esc(NORMAL_SIZE, BOLD_OFF)
        r.empresa.nuit?.let { out.txt("NUIT: $it\n") }
        r.empresa.endereco?.let { out.txt("$it\n") }
        out.txt(DIVIDER)

        out.esc(ALIGN_LEFT)
        out.txt("Numero    : ${venda.numero}\n")
        venda.soldAt?.let { out.txt("Data/Hora : $it\n") }
        out.txt("Estado    : ${venda.status}\n")
        venda.invoiceNumero?.let { out.txt("Fatura    : $it\n") }

        // Itens
        out.txt(DIVIDER)
        for (item in r.itens) {
            val desc  = "${item.quantidade}x ${item.descricao ?: "Produto"}".take(20).padEnd(20)
            val valor = PosStore.formatarValor(item.total).padStart(12)
            out.txt("$desc$valor\n")
            if (item.quantidadeDevolvida > 0) {
                out.txt("  (devolvido: ${item.quantidadeDevolvida})\n")
            }
        }
        out.txt(DIVIDER)

        // Subtotal / Desconto / Total
        if (venda.descontoTotal > 0) {
            out.txt("${"Subtotal".padEnd(20)}${PosStore.formatarValor(venda.subtotal).padStart(12)}\n")
            out.txt("${"Desconto".padEnd(20)}${("-" + PosStore.formatarValor(venda.descontoTotal)).padStart(12)}\n")
        }
        out.esc(BOLD_ON)
        out.txt("${"TOTAL".padEnd(20)}${PosStore.formatarValor(venda.total).padStart(12)}\n")
        out.esc(BOLD_OFF)

        // Pagamentos
        out.txt(DIVIDER)
        for (p in r.pagamentos) {
            out.txt("${p.tipo.padEnd(20)}${PosStore.formatarValor(p.valor).padStart(12)}\n")
        }

        // Rodape
        out.txt(DIVIDER)
        out.esc(ALIGN_CENTER)
        out.txt("Obrigado pela preferencia!\n")
        out.linha()
        out.linha()
        out.linha()
        out.esc(CUT)
    }
}
