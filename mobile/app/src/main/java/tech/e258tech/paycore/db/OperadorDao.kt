package tech.e258tech.paycore.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface OperadorDao {

    @Query("SELECT * FROM operadores")
    fun getAll(): List<OperadorEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(operador: OperadorEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAll(operadores: List<OperadorEntity>)

    @Query("DELETE FROM operadores")
    fun deleteAll()
}
