package tech.e258tech.paycore.db

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "produtos")
data class ProdutoEntity(
    @PrimaryKey val id: String,
    val nome: String,
    val categoriaNome: String,
    val preco: Double,
    val barcode: String,
    val imagem: String?,
    val imagemLocal: String? = null,
    val ativo: Boolean = true,
    // Inventário — null quando não controlado (o backend ainda não expõe stock
    // por produto; a coluna já existe para quando expuser, ver SaleRepository.adicionarItem).
    val stock: Int? = null
)
