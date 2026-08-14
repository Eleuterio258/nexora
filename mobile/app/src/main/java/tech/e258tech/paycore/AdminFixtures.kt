package tech.e258tech.paycore

data class AdminProdutoResumo(
    val nome: String,
    val categoria: String,
    val preco: Double,
    val stock: Int
)

data class AdminCategoriaResumo(
    val nome: String,
    val totalProdutos: Int
)

data class AdminTransacaoResumo(
    val referencia: String,
    val estado: String,
    val metodo: String,
    val total: Double,
    val data: String
)

data class AdminTerminalResumo(
    val nome: String,
    val serial: String,
    val estado: String,
    val activationCode: String
)

data class AdminUtilizadorResumo(
    val nome: String,
    val role: String,
    val email: String
)

data class AdminDescontoResumo(
    val nome: String,
    val regra: String,
    val estado: String
)

data class AdminCaixaResumo(
    val operador: String,
    val abertura: String,
    val fecho: String,
    val total: Double
)

object AdminFixtures {
    val produtos = listOf(
        AdminProdutoResumo("POS Portatil A920", "Terminais", 18500.0, 12),
        AdminProdutoResumo("Leitor NFC Slim", "Perifericos", 4200.0, 7),
        AdminProdutoResumo("Rolo Termico 57mm", "Consumiveis", 180.0, 96)
    )

    val categorias = listOf(
        AdminCategoriaResumo("Terminais", 8),
        AdminCategoriaResumo("Perifericos", 5),
        AdminCategoriaResumo("Consumiveis", 14)
    )

    val transacoes = listOf(
        AdminTransacaoResumo("TRX-24001", "Aprovada", "Cartao", 1250.0, "Hoje 08:32"),
        AdminTransacaoResumo("TRX-24002", "Aprovada", "QR Code", 760.0, "Hoje 09:14"),
        AdminTransacaoResumo("TRX-24003", "Pendente", "NFC", 330.0, "Hoje 10:05")
    )

    val terminais = listOf(
        AdminTerminalResumo("Balcao Principal", "PAY-TERM-001", "Ativo", "AB12CD"),
        AdminTerminalResumo("Caixa Drive", "PAY-TERM-002", "Pendente", "EF34GH")
    )

    val utilizadores = listOf(
        AdminUtilizadorResumo("Maria Santos", "ADMIN", "maria@tenant.paycore"),
        AdminUtilizadorResumo("Paulo Ernesto", "TERMINAL", "paulo@tenant.paycore")
    )

    val descontos = listOf(
        AdminDescontoResumo("Campanha Semana", "10% acima de 5.000 MZN", "Ativo"),
        AdminDescontoResumo("Cliente VIP", "Valor fixo 500 MZN", "Agendado")
    )

    val caixas = listOf(
        AdminCaixaResumo("Maria Santos", "08:00", "16:30", 12450.0),
        AdminCaixaResumo("Paulo Ernesto", "16:40", "22:00", 9320.0)
    )
}
