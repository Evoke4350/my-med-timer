package com.nateb.mymedtimer.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface DoseLogDao {

    @Query("SELECT * FROM dose_logs WHERE medicationId = :medicationId ORDER BY scheduledTime DESC")
    fun getDoseLogsForMedication(medicationId: String): Flow<List<DoseLogEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(doseLog: DoseLogEntity)
}
