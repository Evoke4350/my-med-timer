package com.nateb.mymedtimer.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface ScheduleTimeDao {

    @Query("SELECT * FROM schedule_times WHERE medicationId = :medicationId ORDER BY hour ASC, minute ASC")
    fun getScheduleTimesForMedication(medicationId: String): Flow<List<ScheduleTimeEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(scheduleTimes: List<ScheduleTimeEntity>)

    @Query("DELETE FROM schedule_times WHERE medicationId = :medicationId")
    suspend fun deleteForMedication(medicationId: String)
}
