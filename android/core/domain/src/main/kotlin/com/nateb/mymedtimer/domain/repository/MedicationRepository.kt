package com.nateb.mymedtimer.domain.repository

import com.nateb.mymedtimer.domain.model.DoseLog
import com.nateb.mymedtimer.domain.model.Medication
import kotlinx.coroutines.flow.Flow
import java.time.Instant

interface MedicationRepository {
    fun getAllMedications(): Flow<List<Medication>>
    fun getMedication(id: String): Flow<Medication?>
    suspend fun saveMedication(medication: Medication)
    suspend fun deleteMedication(id: String)
    suspend fun logDose(medicationId: String, scheduledTime: Instant, status: String)
    fun getDoseLogs(medicationId: String): Flow<List<DoseLog>>
}
