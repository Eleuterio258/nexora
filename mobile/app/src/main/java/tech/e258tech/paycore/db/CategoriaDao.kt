package tech.e258tech.paycore.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface CategoriaDao {

    @Query("SELECT * FROM categorias ORDER BY ordem ASC")
    fun getAll(): List<CategoriaEntity>

    @Query("SELECT COUNT(*) FROM categorias")
    fun count(): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAll(categorias: List<CategoriaEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(categoria: CategoriaEntity)

    @Query("DELETE FROM categorias WHERE nome = :nome")
    fun deleteByNome(nome: String)

    @Query("DELETE FROM categorias")
    fun deleteAll()
}
