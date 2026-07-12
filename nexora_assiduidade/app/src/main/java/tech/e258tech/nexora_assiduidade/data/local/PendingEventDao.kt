package tech.e258tech.nexora_assiduidade.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update

@Dao
interface PendingEventDao {

    @Insert
    suspend fun insert(event: PendingEventEntity): Long

    @Update
    suspend fun update(event: PendingEventEntity)

    @Delete
    suspend fun delete(event: PendingEventEntity)

    @Query("SELECT * FROM pending_events WHERE syncStatus = :status ORDER BY createdAt ASC")
    suspend fun getByStatus(status: String): List<PendingEventEntity>

    @Query("SELECT * FROM pending_events WHERE syncStatus IN (:statuses) ORDER BY createdAt ASC LIMIT :limit")
    suspend fun getByStatuses(statuses: List<String>, limit: Int = 100): List<PendingEventEntity>

    @Query("SELECT * FROM pending_events ORDER BY createdAt ASC LIMIT :limit")
    suspend fun getAll(limit: Int = 100): List<PendingEventEntity>

    @Query("SELECT COUNT(*) FROM pending_events WHERE syncStatus = :status")
    suspend fun countByStatus(status: String): Int

    @Query("DELETE FROM pending_events WHERE syncStatus = :status AND createdAt < :olderThan")
    suspend fun deleteOldByStatus(status: String, olderThan: Long)
}
