package tech.e258tech.paycore.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface UsuarioSessaoDao {

    @Query("SELECT * FROM usuario_sessao LIMIT 1")
    fun getAtual(): UsuarioSessaoEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun upsert(usuario: UsuarioSessaoEntity)

    @Query("DELETE FROM usuario_sessao")
    fun deleteAll()
}
