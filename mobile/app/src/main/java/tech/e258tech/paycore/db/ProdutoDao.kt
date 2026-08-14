package tech.e258tech.paycore.db

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface ProdutoDao {

    @Query("SELECT * FROM produtos WHERE ativo = 1 ORDER BY nome ASC")
    fun getAll(): List<ProdutoEntity>

    @Query("SELECT COUNT(*) FROM produtos")
    fun count(): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAll(produtos: List<ProdutoEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(produto: ProdutoEntity)

    @Delete
    fun delete(produto: ProdutoEntity)

    @Query("DELETE FROM produtos WHERE id = :id")
    fun deleteById(id: String)

    @Query("DELETE FROM produtos")
    fun deleteAll()
}
