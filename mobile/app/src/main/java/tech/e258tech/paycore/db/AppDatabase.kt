package tech.e258tech.paycore.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

@Database(
    entities = [
        OperadorEntity::class,
        TransacaoPDVEntity::class,
        CategoriaEntity::class,
        ProdutoEntity::class,
        PedidoEntity::class,
        UsuarioSessaoEntity::class,
        SessaoCaixaEntity::class,
        EstornoEntity::class,
        NotificacaoEntity::class
    ],
    version = 13,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {

    abstract fun operadorDao(): OperadorDao
    abstract fun transacaoDao(): TransacaoDao
    abstract fun categoriaDao(): CategoriaDao
    abstract fun produtoDao(): ProdutoDao
    abstract fun pedidoDao(): PedidoDao
    abstract fun usuarioSessaoDao(): UsuarioSessaoDao
    abstract fun sessaoCaixaDao(): SessaoCaixaDao
    abstract fun estornoDao(): EstornoDao
    abstract fun notificacaoDao(): NotificacaoDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "paycore.db"
                )
                    .addMigrations(MIGRATION_6_7, MIGRATION_7_8, MIGRATION_8_9, MIGRATION_9_10, MIGRATION_10_11, MIGRATION_11_12, MIGRATION_12_13)
                    .fallbackToDestructiveMigration(true)
                    .build()
                    .also { INSTANCE = it }
            }

        // O schema tinha sido alterado em algum momento sem incrementar a versao
        // (exportSchema=false, sem historico), pelo que nao ha registo do formato
        // anterior. Esta migracao descobre em runtime as colunas que realmente
        // existem na tabela antiga (PRAGMA table_info) e copia apenas as que ainda
        // batem pelo nome, preservando o maximo de dados possivel (nomeadamente
        // transacoes/pedidos ainda nao sincronizados) sem assumir qual foi a mudanca.
        private val MIGRATION_6_7 = object : Migration(6, 7) {
            override fun migrate(database: SupportSQLiteDatabase) {
                migrarPreservandoColunasCompativeis(
                    database, "operadores", "id",
                    "CREATE TABLE IF NOT EXISTS `operadores` (`id` TEXT NOT NULL, `nome` TEXT NOT NULL, `pin` TEXT NOT NULL, `perfil` TEXT NOT NULL, PRIMARY KEY(`id`))",
                    linkedMapOf("id" to "''", "nome" to "''", "pin" to "''", "perfil" to "''")
                )
                migrarPreservandoColunasCompativeis(
                    database, "transacoes", "id",
                    "CREATE TABLE IF NOT EXISTS `transacoes` (`id` TEXT NOT NULL, `referencia` TEXT NOT NULL, `metodo` TEXT NOT NULL, `operadorId` TEXT NOT NULL, `operadorNome` TEXT NOT NULL, `dataHora` INTEGER NOT NULL, `itensJson` TEXT NOT NULL, `subtotal` REAL NOT NULL, `desconto` REAL NOT NULL, `total` REAL NOT NULL, `estado` TEXT NOT NULL, `syncPendente` INTEGER NOT NULL, PRIMARY KEY(`id`))",
                    linkedMapOf(
                        "id" to "''", "referencia" to "''", "metodo" to "''",
                        "operadorId" to "''", "operadorNome" to "''", "dataHora" to "0",
                        "itensJson" to "'[]'", "subtotal" to "0.0", "desconto" to "0.0",
                        "total" to "0.0", "estado" to "''",
                        // Se a coluna nao existir na tabela antiga, assume-se pendente
                        // de sincronizacao (mais seguro do que assumir ja sincronizado).
                        "syncPendente" to "1"
                    )
                )
                migrarPreservandoColunasCompativeis(
                    database, "categorias", "nome",
                    "CREATE TABLE IF NOT EXISTS `categorias` (`nome` TEXT NOT NULL, `ordem` INTEGER NOT NULL, PRIMARY KEY(`nome`))",
                    linkedMapOf("nome" to "''", "ordem" to "0")
                )
                migrarPreservandoColunasCompativeis(
                    database, "produtos", "id",
                    "CREATE TABLE IF NOT EXISTS `produtos` (`id` TEXT NOT NULL, `nome` TEXT NOT NULL, `categoriaNome` TEXT NOT NULL, `preco` REAL NOT NULL, `barcode` TEXT NOT NULL, `imagem` TEXT, `imagemLocal` TEXT, PRIMARY KEY(`id`))",
                    linkedMapOf(
                        "id" to "''", "nome" to "''", "categoriaNome" to "''",
                        "preco" to "0.0", "barcode" to "''", "imagem" to "NULL", "imagemLocal" to "NULL"
                    )
                )
                migrarPreservandoColunasCompativeis(
                    database, "pedidos", "id",
                    "CREATE TABLE IF NOT EXISTS `pedidos` (`id` TEXT NOT NULL, `numero` INTEGER NOT NULL, `nota` TEXT NOT NULL, `itensJson` TEXT NOT NULL, `total` REAL NOT NULL, `dataHora` INTEGER NOT NULL, `estado` TEXT NOT NULL, PRIMARY KEY(`id`))",
                    linkedMapOf(
                        "id" to "''", "numero" to "0", "nota" to "''",
                        "itensJson" to "'[]'", "total" to "0.0", "dataHora" to "0", "estado" to "''"
                    )
                )
                migrarPreservandoColunasCompativeis(
                    database, "usuario_sessao", "uid",
                    "CREATE TABLE IF NOT EXISTS `usuario_sessao` (`uid` TEXT NOT NULL, `nome` TEXT NOT NULL, `email` TEXT NOT NULL, `role` TEXT NOT NULL, `tenantId` TEXT NOT NULL, `modulosJson` TEXT NOT NULL, `updatedAt` INTEGER NOT NULL, PRIMARY KEY(`uid`))",
                    linkedMapOf(
                        "uid" to "''", "nome" to "''", "email" to "''", "role" to "''",
                        "tenantId" to "''", "modulosJson" to "'{}'", "updatedAt" to "0"
                    )
                )
            }
        }

        // Suporte a operação offline de caixa/estorno (ver plano de operação
        // offline): duas tabelas novas (sem dados antigos a preservar, por
        // isso CREATE TABLE simples) e uma coluna nova em `transacoes`
        // (sessaoLocalId), que segue o mesmo padrão de preservação de
        // colunas compatíveis da MIGRATION_6_7 — para não perder vendas
        // ainda por sincronizar ao adicionar a coluna.
        private val MIGRATION_7_8 = object : Migration(7, 8) {
            override fun migrate(database: SupportSQLiteDatabase) {
                migrarPreservandoColunasCompativeis(
                    database, "transacoes", "id",
                    "CREATE TABLE IF NOT EXISTS `transacoes` (`id` TEXT NOT NULL, `referencia` TEXT NOT NULL, `metodo` TEXT NOT NULL, `operadorId` TEXT NOT NULL, `operadorNome` TEXT NOT NULL, `dataHora` INTEGER NOT NULL, `itensJson` TEXT NOT NULL, `subtotal` REAL NOT NULL, `desconto` REAL NOT NULL, `total` REAL NOT NULL, `estado` TEXT NOT NULL, `syncPendente` INTEGER NOT NULL, `sessaoLocalId` TEXT NOT NULL, PRIMARY KEY(`id`))",
                    linkedMapOf(
                        "id" to "''", "referencia" to "''", "metodo" to "''",
                        "operadorId" to "''", "operadorNome" to "''", "dataHora" to "0",
                        "itensJson" to "'[]'", "subtotal" to "0.0", "desconto" to "0.0",
                        "total" to "0.0", "estado" to "''", "syncPendente" to "1",
                        // Linhas anteriores a esta migração não têm sessão local —
                        // continuam sincronizáveis pelo caminho antigo (sessaoAtualId
                        // resolvido por fora), só não participam da reconciliação
                        // de sessões de caixa offline.
                        "sessaoLocalId" to "''"
                    )
                )
                database.execSQL(
                    "CREATE TABLE IF NOT EXISTS `sessoes_caixa` (`localId` TEXT NOT NULL, `serverId` INTEGER, `terminalId` INTEGER NOT NULL, `openingAmount` REAL NOT NULL, `abertaEm` INTEGER NOT NULL, `closingAmount` REAL, `fechadaEm` INTEGER, `diferencaLocal` REAL, `status` TEXT NOT NULL, `aberturaSincronizada` INTEGER NOT NULL, `fechoSincronizado` INTEGER NOT NULL, PRIMARY KEY(`localId`))"
                )
                database.execSQL(
                    "CREATE TABLE IF NOT EXISTS `estornos_pendentes` (`transacaoId` TEXT NOT NULL, `motivo` TEXT NOT NULL, `criadoEm` INTEGER NOT NULL, `sincronizado` INTEGER NOT NULL, PRIMARY KEY(`transacaoId`))"
                )
            }
        }

        // Justificativa da diferença de caixa (ver SessaoCaixaEntity) — o backend
        // passou a exigi-la quando há diferença não-trivial no fecho; sem esta
        // coluna, um fecho offline com diferença real ficaria preso para
        // sempre em retry (o servidor rejeitaria sempre por falta de
        // justificativa, e não havia onde a guardar localmente para reenviar).
        private val MIGRATION_8_9 = object : Migration(8, 9) {
            override fun migrate(database: SupportSQLiteDatabase) {
                migrarPreservandoColunasCompativeis(
                    database, "sessoes_caixa", "localId",
                    "CREATE TABLE IF NOT EXISTS `sessoes_caixa` (`localId` TEXT NOT NULL, `serverId` INTEGER, `terminalId` INTEGER NOT NULL, `openingAmount` REAL NOT NULL, `abertaEm` INTEGER NOT NULL, `closingAmount` REAL, `fechadaEm` INTEGER, `diferencaLocal` REAL, `status` TEXT NOT NULL, `aberturaSincronizada` INTEGER NOT NULL, `fechoSincronizado` INTEGER NOT NULL, `justificativaDiferenca` TEXT, PRIMARY KEY(`localId`))",
                    linkedMapOf(
                        "localId" to "''", "serverId" to "NULL", "terminalId" to "0",
                        "openingAmount" to "0.0", "abertaEm" to "0", "closingAmount" to "NULL",
                        "fechadaEm" to "NULL", "diferencaLocal" to "NULL", "status" to "'ABERTA'",
                        "aberturaSincronizada" to "0", "fechoSincronizado" to "0",
                        "justificativaDiferenca" to "NULL"
                    )
                )
            }
        }

        // serverId em `transacoes` (ver TransacaoPDVEntity) — id de pos_sales no
        // servidor, necessário para o estorno parcial poder referenciar a venda
        // do lado do servidor em vez de só pela referência local.
        private val MIGRATION_9_10 = object : Migration(9, 10) {
            override fun migrate(database: SupportSQLiteDatabase) {
                migrarPreservandoColunasCompativeis(
                    database, "transacoes", "id",
                    "CREATE TABLE IF NOT EXISTS `transacoes` (`id` TEXT NOT NULL, `referencia` TEXT NOT NULL, `metodo` TEXT NOT NULL, `operadorId` TEXT NOT NULL, `operadorNome` TEXT NOT NULL, `dataHora` INTEGER NOT NULL, `itensJson` TEXT NOT NULL, `subtotal` REAL NOT NULL, `desconto` REAL NOT NULL, `total` REAL NOT NULL, `estado` TEXT NOT NULL, `syncPendente` INTEGER NOT NULL, `sessaoLocalId` TEXT NOT NULL, `serverId` INTEGER, PRIMARY KEY(`id`))",
                    linkedMapOf(
                        "id" to "''", "referencia" to "''", "metodo" to "''",
                        "operadorId" to "''", "operadorNome" to "''", "dataHora" to "0",
                        "itensJson" to "'[]'", "subtotal" to "0.0", "desconto" to "0.0",
                        "total" to "0.0", "estado" to "''", "syncPendente" to "1",
                        "sessaoLocalId" to "''", "serverId" to "NULL"
                    )
                )
            }
        }

        // ativo/stock em produtos (ver ProdutoEntity) — ativo já vem do backend no delta de
        // sincronização (ProdutoDTO.activo) mas nunca era persistido; produtos existentes antes
        // desta migração assumem-se activos (default '1'), para não desaparecerem do catálogo
        // até ao próximo sync. stock fica sempre NULL (não controlado) até o backend expor
        // inventário por produto — ver SaleRepository.adicionarItem/incrementarItem.
        private val MIGRATION_10_11 = object : Migration(10, 11) {
            override fun migrate(database: SupportSQLiteDatabase) {
                migrarPreservandoColunasCompativeis(
                    database, "produtos", "id",
                    "CREATE TABLE IF NOT EXISTS `produtos` (`id` TEXT NOT NULL, `nome` TEXT NOT NULL, `categoriaNome` TEXT NOT NULL, `preco` REAL NOT NULL, `barcode` TEXT NOT NULL, `imagem` TEXT, `imagemLocal` TEXT, `ativo` INTEGER NOT NULL, `stock` INTEGER, PRIMARY KEY(`id`))",
                    linkedMapOf(
                        "id" to "''", "nome" to "''", "categoriaNome" to "''",
                        "preco" to "0.0", "barcode" to "''", "imagem" to "NULL", "imagemLocal" to "NULL",
                        "ativo" to "1", "stock" to "NULL"
                    )
                )
            }
        }

        // Tabela nova para notificações reais (push FCM persistido localmente — ver
        // PayCoreFirebaseMessagingService/NotificacoesActivity). Sem dados antigos a
        // preservar, por isso CREATE TABLE simples, mesmo padrão de sessoes_caixa/
        // estornos_pendentes em MIGRATION_7_8.
        private val MIGRATION_11_12 = object : Migration(11, 12) {
            override fun migrate(database: SupportSQLiteDatabase) {
                database.execSQL(
                    "CREATE TABLE IF NOT EXISTS `notificacoes` (`id` TEXT NOT NULL, `titulo` TEXT NOT NULL, `mensagem` TEXT NOT NULL, `dataHora` INTEGER NOT NULL, `lida` INTEGER NOT NULL, PRIMARY KEY(`id`))"
                )
            }
        }

        // Máquina de estados de sincronização (ver SyncStatus) — syncStatus/tentativas/
        // ultimoErro/ultimaTentativaEm, aditivos aos booleanos existentes, em transacoes/
        // sessoes_caixa/estornos_pendentes. syncStatus por omissão 'PENDENTE' para linhas
        // antigas é inofensivo mesmo para as já sincronizadas — getPendentes()/
        // getPendentesAbertura()/getPendentesFecho() continuam a filtrar primeiro pelo
        // booleano original, syncStatus só entra depois para excluir FALHADO.
        private val MIGRATION_12_13 = object : Migration(12, 13) {
            override fun migrate(database: SupportSQLiteDatabase) {
                migrarPreservandoColunasCompativeis(
                    database, "transacoes", "id",
                    "CREATE TABLE IF NOT EXISTS `transacoes` (`id` TEXT NOT NULL, `referencia` TEXT NOT NULL, `metodo` TEXT NOT NULL, `operadorId` TEXT NOT NULL, `operadorNome` TEXT NOT NULL, `dataHora` INTEGER NOT NULL, `itensJson` TEXT NOT NULL, `subtotal` REAL NOT NULL, `desconto` REAL NOT NULL, `total` REAL NOT NULL, `estado` TEXT NOT NULL, `syncPendente` INTEGER NOT NULL, `sessaoLocalId` TEXT NOT NULL, `serverId` INTEGER, `syncStatus` TEXT NOT NULL, `tentativas` INTEGER NOT NULL, `ultimoErro` TEXT, `ultimaTentativaEm` INTEGER, PRIMARY KEY(`id`))",
                    linkedMapOf(
                        "id" to "''", "referencia" to "''", "metodo" to "''",
                        "operadorId" to "''", "operadorNome" to "''", "dataHora" to "0",
                        "itensJson" to "'[]'", "subtotal" to "0.0", "desconto" to "0.0",
                        "total" to "0.0", "estado" to "''", "syncPendente" to "1",
                        "sessaoLocalId" to "''", "serverId" to "NULL",
                        "syncStatus" to "'PENDENTE'", "tentativas" to "0",
                        "ultimoErro" to "NULL", "ultimaTentativaEm" to "NULL"
                    )
                )
                migrarPreservandoColunasCompativeis(
                    database, "sessoes_caixa", "localId",
                    "CREATE TABLE IF NOT EXISTS `sessoes_caixa` (`localId` TEXT NOT NULL, `serverId` INTEGER, `terminalId` INTEGER NOT NULL, `openingAmount` REAL NOT NULL, `abertaEm` INTEGER NOT NULL, `closingAmount` REAL, `fechadaEm` INTEGER, `diferencaLocal` REAL, `status` TEXT NOT NULL, `aberturaSincronizada` INTEGER NOT NULL, `fechoSincronizado` INTEGER NOT NULL, `justificativaDiferenca` TEXT, `syncStatus` TEXT NOT NULL, `tentativas` INTEGER NOT NULL, `ultimoErro` TEXT, `ultimaTentativaEm` INTEGER, PRIMARY KEY(`localId`))",
                    linkedMapOf(
                        "localId" to "''", "serverId" to "NULL", "terminalId" to "0",
                        "openingAmount" to "0.0", "abertaEm" to "0", "closingAmount" to "NULL",
                        "fechadaEm" to "NULL", "diferencaLocal" to "NULL", "status" to "'ABERTA'",
                        "aberturaSincronizada" to "0", "fechoSincronizado" to "0",
                        "justificativaDiferenca" to "NULL",
                        "syncStatus" to "'PENDENTE'", "tentativas" to "0",
                        "ultimoErro" to "NULL", "ultimaTentativaEm" to "NULL"
                    )
                )
                migrarPreservandoColunasCompativeis(
                    database, "estornos_pendentes", "transacaoId",
                    "CREATE TABLE IF NOT EXISTS `estornos_pendentes` (`transacaoId` TEXT NOT NULL, `motivo` TEXT NOT NULL, `criadoEm` INTEGER NOT NULL, `sincronizado` INTEGER NOT NULL, `syncStatus` TEXT NOT NULL, `tentativas` INTEGER NOT NULL, `ultimoErro` TEXT, `ultimaTentativaEm` INTEGER, PRIMARY KEY(`transacaoId`))",
                    linkedMapOf(
                        "transacaoId" to "''", "motivo" to "''", "criadoEm" to "0", "sincronizado" to "0",
                        "syncStatus" to "'PENDENTE'", "tentativas" to "0",
                        "ultimoErro" to "NULL", "ultimaTentativaEm" to "NULL"
                    )
                )
            }
        }

        /**
         * Renomeia a tabela antiga, recria-a com o schema atual e copia os dados
         * das colunas cujo nome ainda existe na tabela antiga (via PRAGMA table_info).
         * Colunas novas/renomeadas recebem o literal de [columnDefaults]. Se a propria
         * chave primaria nao existir na tabela antiga, os dados antigos sao descartados
         * (nao ha como reconciliar identidade das linhas com seguranca).
         */
        private fun migrarPreservandoColunasCompativeis(
            database: SupportSQLiteDatabase,
            tableName: String,
            primaryKeyColumn: String,
            createTableSql: String,
            columnDefaults: Map<String, String>
        ) {
            val tempName = "${tableName}_migracao_tmp"
            val existiaAntes = database.query(
                "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
                arrayOf(tableName)
            ).use { it.moveToFirst() }

            if (existiaAntes) {
                database.execSQL("ALTER TABLE `$tableName` RENAME TO `$tempName`")
            }

            database.execSQL(createTableSql)

            if (existiaAntes) {
                val colunasAntigas = mutableSetOf<String>()
                database.query("PRAGMA table_info(`$tempName`)").use { cursor ->
                    val idx = cursor.getColumnIndex("name")
                    while (cursor.moveToNext()) colunasAntigas.add(cursor.getString(idx))
                }

                if (primaryKeyColumn in colunasAntigas) {
                    val destino = columnDefaults.keys.joinToString(", ") { "`$it`" }
                    val origem = columnDefaults.entries.joinToString(", ") { (coluna, defaultLiteral) ->
                        if (coluna in colunasAntigas) "`$coluna`" else defaultLiteral
                    }
                    database.execSQL("INSERT INTO `$tableName` ($destino) SELECT $origem FROM `$tempName`")
                }

                database.execSQL("DROP TABLE `$tempName`")
            }
        }
    }
}
