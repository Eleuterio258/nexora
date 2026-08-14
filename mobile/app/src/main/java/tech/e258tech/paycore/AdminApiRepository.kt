package tech.e258tech.paycore

import tech.e258tech.paycore.api.AdicionarCodigoBarrasRequest
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.CategoriaDTO
import tech.e258tech.paycore.api.CategoriaUpsertRequest
import tech.e258tech.paycore.api.CashDrawerDTO
import tech.e258tech.paycore.api.CreateTerminalRequest
import tech.e258tech.paycore.api.DefinirPrecoRequest
import tech.e258tech.paycore.api.DiscountDTO
import tech.e258tech.paycore.api.DiscountUpsertRequest
import tech.e258tech.paycore.api.ProdutoDTO
import tech.e258tech.paycore.api.ProdutoUpsertRequest
import tech.e258tech.paycore.api.RelatorioCancelamentosResponse
import tech.e258tech.paycore.api.RelatorioFechoCaixaResponse
import tech.e258tech.paycore.api.RelatorioTerminalDTO
import tech.e258tech.paycore.api.RelatorioTopProdutosResponse
import tech.e258tech.paycore.api.RelatorioVendasResponse
import tech.e258tech.paycore.api.TerminalDTO
import tech.e258tech.paycore.api.TransacaoResponse
import tech.e258tech.paycore.api.UserDTO
import tech.e258tech.paycore.api.UserUpsertRequest
import tech.e258tech.paycore.repository.SessionRepository
import tech.e258tech.paycore.utils.PermissaoHelper.bodyOuSemPermissao
import tech.e258tech.paycore.utils.PermissaoHelper.lancarSeSemPermissao
import kotlin.random.Random

data class AdminDashboardSnapshot(
    val totalVendas: Double,
    val totalProdutos: Int,
    val terminaisAtivos: Int
)

data class AdminTerminalCreateResult(
    val nome: String,
    val serial: String,
    val modelo: String,
    val activationCode: String
)

object AdminApiRepository {
    var selectedTerminal: TerminalDTO? = null
    var selectedProduto: ProdutoDTO? = null
    var selectedCategoria: CategoriaDTO? = null
    var selectedUser: UserDTO? = null
    var selectedDiscount: DiscountDTO? = null

    suspend fun loadDashboard(): Result<AdminDashboardSnapshot> = runCatching {
        requireTenantId()
        val produtos = ApiClient.service.getProdutos().bodyOuSemPermissao().orEmpty()
        val terminais = ApiClient.service.listTerminals().bodyOuSemPermissao().orEmpty()
        val transacoes = ApiClient.service.getTransacoes().bodyOuSemPermissao()?.data.orEmpty()

        AdminDashboardSnapshot(
            totalVendas = transacoes.sumOf { it.total ?: 0.0 },
            totalProdutos = produtos.size,
            terminaisAtivos = terminais.count { terminalStatus(it) == "ATIVO" }
        )
    }

    suspend fun loadProdutos(): Result<List<ProdutoDTO>> = runCatching {
        requireTenantId()
        ApiClient.service.getProdutos().bodyOuSemPermissao().orEmpty().also {
            selectedProduto = it.firstOrNull()
        }
    }

    suspend fun loadCategorias(): Result<List<CategoriaDTO>> = runCatching {
        requireTenantId()
        ApiClient.service.getCategorias().bodyOuSemPermissao().orEmpty().also {
            selectedCategoria = it.firstOrNull()
        }
    }

    suspend fun loadTransacoes(busca: String? = null): Result<List<TransacaoResponse>> = runCatching {
        requireTenantId()
        ApiClient.service.getTransacoes(busca = busca?.trim()?.takeIf { it.isNotEmpty() })
            .bodyOuSemPermissao()?.data.orEmpty()
    }

    suspend fun loadTerminais(): Result<List<TerminalDTO>> = runCatching {
        requireTenantId()
        ApiClient.service.listTerminals().bodyOuSemPermissao().orEmpty().also {
            selectedTerminal = it.firstOrNull()
        }
    }

    suspend fun loadUsers(): Result<List<UserDTO>> = runCatching {
        requireTenantId()
        ApiClient.service.getUsers().bodyOuSemPermissao().orEmpty().also {
            selectedUser = it.firstOrNull()
        }
    }

    suspend fun saveUser(
        email: String,
        name: String,
        password: String?,
        role: String?,
        phoneNumber: String?
    ): Result<UserDTO> = runCatching {
        requireTenantId()
        val request = UserUpsertRequest(
            email = email,
            name = name,
            password = password?.ifBlank { null },
            role = role?.ifBlank { null },
            active = true,
            phoneNumber = phoneNumber?.ifBlank { null }
        )
        val user = selectedUser
        val response = if (user?.id != null) {
            ApiClient.service.updateUser(user.id, request)
        } else {
            ApiClient.service.createUser(request)
        }
        response.bodyOuSemPermissao() ?: error("Resposta vazia ao guardar utilizador")
    }.onSuccess {
        selectedUser = it
    }

    suspend fun deleteSelectedUser(): Result<Unit> = runCatching {
        val user = selectedUser ?: error("Nenhum utilizador selecionado")
        requireTenantId()
        // ERP não tem DELETE de utilizador, só desativação (soft)
        ApiClient.service.desactivarUser(user.id).lancarSeSemPermissao()
        Unit
    }.onSuccess {
        selectedUser = null
    }

    suspend fun loadDiscounts(): Result<List<DiscountDTO>> = runCatching {
        requireTenantId()
        ApiClient.service.getDiscounts().bodyOuSemPermissao().orEmpty().also {
            selectedDiscount = it.firstOrNull()
        }
    }

    suspend fun loadCashDrawers(): Result<List<CashDrawerDTO>> = runCatching {
        requireTenantId()
        ApiClient.service.getCashDrawers().bodyOuSemPermissao().orEmpty()
    }

    suspend fun loadRelatorioVendas(
        agruparPor: String = "dia",
        from: String? = null,
        to: String? = null
    ): Result<RelatorioVendasResponse> = runCatching {
        requireTenantId()
        ApiClient.service.relatorioVendas(agruparPor, from, to).bodyOuSemPermissao()
            ?: RelatorioVendasResponse()
    }

    suspend fun loadRelatorioTopProdutos(
        from: String? = null,
        to: String? = null,
        limit: Int = 10
    ): Result<RelatorioTopProdutosResponse> = runCatching {
        requireTenantId()
        ApiClient.service.relatorioTopProdutos(from, to, limit).bodyOuSemPermissao()
            ?: RelatorioTopProdutosResponse()
    }

    suspend fun loadRelatorioCancelamentos(
        from: String? = null,
        to: String? = null
    ): Result<RelatorioCancelamentosResponse> = runCatching {
        requireTenantId()
        ApiClient.service.relatorioCancelamentos(from, to).bodyOuSemPermissao()
            ?: RelatorioCancelamentosResponse()
    }

    suspend fun loadRelatorioFechoCaixa(
        from: String? = null,
        to: String? = null
    ): Result<RelatorioFechoCaixaResponse> = runCatching {
        requireTenantId()
        ApiClient.service.relatorioFechoCaixa(from, to).bodyOuSemPermissao()
            ?: RelatorioFechoCaixaResponse()
    }

    suspend fun loadRelatorioTerminais(): Result<List<RelatorioTerminalDTO>> = runCatching {
        requireTenantId()
        ApiClient.service.relatorioTerminais().bodyOuSemPermissao().orEmpty()
    }

    // Encadeia três chamadas porque o backend guarda produto/preço/barcode em
    // três recursos separados (produtos.products / product_prices /
    // product_barcodes — ver comentário em ProdutoUpsertRequest). A criação
    // do produto (ou a sua edição) só falha o Result se o passo base falhar;
    // falha ao gravar o preço também é fatal (um produto sem preço não é
    // vendável no POS). Falha a gravar o barcode é tolerada (ex.: reeditar
    // sem mudar o barcode dá 409 "já existe" no backend) e só fica registada.
    suspend fun saveProduto(
        codigo: String,
        nome: String,
        categoriaId: Long?,
        descricao: String?,
        preco: Double,
        barcode: String?
    ): Result<ProdutoDTO> = runCatching {
        requireTenantId()
        val produtoExistente = selectedProduto
        val request = ProdutoUpsertRequest(
            codigo = codigo,
            nome = nome,
            descricao = descricao?.ifBlank { null },
            categoryId = categoriaId,
            ativo = produtoExistente?.activo ?: true
        )
        val id = if (produtoExistente?.id != null) {
            val resp = ApiClient.service.updateProduto(produtoExistente.id, request)
            resp.lancarSeSemPermissao()
            if (!resp.isSuccessful) error("Falha ao actualizar produto (${resp.code()})")
            produtoExistente.id
        } else {
            ApiClient.service.createProduto(request).bodyOuSemPermissao()?.id
                ?: error("Resposta vazia ao criar produto")
        }

        val precoResp = ApiClient.service.definirPreco(id, DefinirPrecoRequest(valor = preco))
        precoResp.lancarSeSemPermissao()
        if (!precoResp.isSuccessful) error("Falha ao gravar preço (${precoResp.code()})")

        if (!barcode.isNullOrBlank()) {
            runCatching {
                ApiClient.service.adicionarCodigoBarras(id, AdicionarCodigoBarrasRequest(barcode = barcode))
            }
        }

        // A resposta do backend não devolve o produto completo (ver
        // IdResponse) — construímos o DTO localmente a partir do que
        // acabámos de enviar, que é exactamente o que ficou gravado.
        ProdutoDTO(
            id = id,
            codigo = codigo,
            nome = nome,
            descricao = descricao?.ifBlank { null },
            categoriaId = categoriaId,
            categoriaNome = produtoExistente?.categoriaNome,
            precoVenda = preco,
            preco = preco,
            barcode = barcode?.ifBlank { null } ?: produtoExistente?.barcode,
            imagemUrl = produtoExistente?.imagemUrl,
            activo = request.ativo
        )
    }.onSuccess {
        selectedProduto = it
    }

    suspend fun deleteSelectedProduto(): Result<Unit> = runCatching {
        val produto = selectedProduto ?: error("Nenhum produto selecionado")
        requireTenantId()
        // ERP não tem DELETE de produto, só desativação (soft)
        ApiClient.service.desactivarProduto(produto.id).lancarSeSemPermissao()
        Unit
    }.onSuccess {
        selectedProduto = null
    }

    // "ordem" não é persistido pelo backend (produtos.product_categories não
    // tem essa coluna) — o parâmetro é mantido só para o formulário poder
    // continuar a mostrar o que o utilizador escreveu, não é enviado à API.
    suspend fun createCategoria(
        nome: String,
        descricao: String?,
        ordem: Int
    ): Result<CategoriaDTO> = runCatching {
        requireTenantId()
        val id = ApiClient.service.createCategoria(
            CategoriaUpsertRequest(
                nome = nome,
                descricao = descricao?.ifBlank { null }
            )
        ).bodyOuSemPermissao()?.id ?: error("Resposta vazia ao criar categoria")
        CategoriaDTO(id = id, nome = nome, descricao = descricao?.ifBlank { null }, ordem = ordem)
    }.onSuccess {
        selectedCategoria = it
    }

    suspend fun updateCategoria(
        id: Long,
        nome: String,
        descricao: String?,
        ordem: Int
    ): Result<CategoriaDTO> = runCatching {
        requireTenantId()
        val response = ApiClient.service.updateCategoria(
            id,
            CategoriaUpsertRequest(
                nome = nome,
                descricao = descricao?.ifBlank { null }
            )
        )
        response.lancarSeSemPermissao()
        if (!response.isSuccessful) error("Falha ao actualizar categoria (${response.code()})")
        CategoriaDTO(id = id, nome = nome, descricao = descricao?.ifBlank { null }, ordem = ordem)
    }.onSuccess {
        selectedCategoria = it
    }

    suspend fun deleteSelectedCategoria(): Result<Unit> = runCatching {
        val categoria = selectedCategoria ?: error("Nenhuma categoria selecionada")
        requireTenantId()
        ApiClient.service.deleteCategoria(categoria.id).lancarSeSemPermissao()
        Unit
    }.onSuccess {
        selectedCategoria = null
    }

    // O backend (CriarTerminal) exige um activation_code não vazio, e mais
    // nada: não impõe formato nem comprimento, e nunca gera nem devolve um — é
    // o admin (aqui, o próprio app) quem o define, e o backend só guarda o
    // hash bcrypt. Por isso é gerado localmente e mostrado ao utilizador para
    // o passar a quem for configurar o aparelho.
    //
    // Os 6 dígitos abaixo são convenção deste app, não regra do servidor: um
    // terminal criado pelo ERP pode ter um código de qualquer forma, e o ecrã
    // de login aceita-o na mesma.
    suspend fun createTerminal(nome: String, serial: String, modelo: String): Result<AdminTerminalCreateResult> = runCatching {
        requireTenantId()
        val activationCode = Random.nextInt(100000, 1000000).toString()
        val response = ApiClient.service.createTerminal(
            CreateTerminalRequest(
                codigo = serial,
                nome = nome,
                activationCode = activationCode
            )
        )
        val body = response.bodyOuSemPermissao() ?: error("Resposta vazia ao criar terminal")
        selectedTerminal = body
        AdminTerminalCreateResult(
            nome = body.nome ?: nome,
            serial = body.codigo ?: serial,
            modelo = body.model ?: modelo,
            activationCode = activationCode
        )
    }

    suspend fun updateSelectedTerminalStatus(status: String): Result<TerminalDTO> = runCatching {
        val terminal = selectedTerminal ?: error("Nenhum terminal selecionado")
        requireTenantId()
        val response = if (status.equals("ATIVO", ignoreCase = true) || status.equals("ACTIVE", ignoreCase = true)) {
            ApiClient.service.activateTerminal(terminal.id)
        } else {
            ApiClient.service.deactivateTerminal(terminal.id)
        }
        response.bodyOuSemPermissao() ?: error("Resposta vazia ao alterar estado do terminal")
    }.onSuccess {
        selectedTerminal = it
    }

    suspend fun deleteSelectedTerminal(): Result<Unit> = runCatching {
        val terminal = selectedTerminal ?: error("Nenhum terminal selecionado")
        requireTenantId()
        // ERP não tem DELETE de terminal, só desativação (soft)
        ApiClient.service.deactivateTerminal(terminal.id).lancarSeSemPermissao()
        Unit
    }.onSuccess {
        selectedTerminal = null
    }

    suspend fun saveDiscount(
        name: String,
        type: String,
        value: Double,
        description: String?,
        minAmount: Double?,
        maxAmount: Double?
    ): Result<DiscountDTO> = runCatching {
        requireTenantId()
        val request = DiscountUpsertRequest(
            name = name,
            description = description?.ifBlank { null },
            type = type,
            value = value,
            minAmount = minAmount,
            maxAmount = maxAmount,
            validFrom = selectedDiscount?.validFrom,
            validUntil = selectedDiscount?.validUntil,
            active = selectedDiscount?.active ?: true
        )
        val discount = selectedDiscount
        val response = if (discount?.id != null) {
            ApiClient.service.updateDiscount(discount.id, request)
        } else {
            ApiClient.service.createDiscount(request)
        }
        response.bodyOuSemPermissao() ?: error("Resposta vazia ao guardar desconto")
    }.onSuccess {
        selectedDiscount = it
    }

    suspend fun deleteSelectedDiscount(): Result<Unit> = runCatching {
        val discount = selectedDiscount ?: error("Nenhum desconto selecionado")
        requireTenantId()
        ApiClient.service.deleteDiscount(discount.id).lancarSeSemPermissao()
        Unit
    }.onSuccess {
        selectedDiscount = null
    }

    fun terminalTitle(terminal: TerminalDTO): String = terminal.nome ?: "Terminal"

    fun terminalStatus(terminal: TerminalDTO): String = terminal.status?.uppercase().orEmpty().ifBlank { "DESCONHECIDO" }

    fun productPrice(produto: ProdutoDTO): Double = produto.precoVenda ?: produto.preco ?: 0.0

    private fun requireTenantId(): String = SessionRepository.tenantId.ifBlank {
        error("tenantId indisponivel")
    }
}
