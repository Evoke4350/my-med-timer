package com.nateb.mymedtimer.data.repository

import com.nateb.mymedtimer.data.local.DoseLogEntity
import com.nateb.mymedtimer.data.local.MedicationDao
import com.nateb.mymedtimer.data.local.DoseLogDao
import com.nateb.mymedtimer.data.local.ScheduleTimeDao
import com.nateb.mymedtimer.data.mapper.toDomain
import com.nateb.mymedtimer.data.mapper.toEntity
import com.nateb.mymedtimer.domain.model.DoseLog
import com.nateb.mymedtimer.domain.model.Medication
import com.nateb.mymedtimer.domain.repository.MedicationRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import java.time.Instant
import java.util.UUID
import javax.inject.Inject

class MedicationRepositoryImpl @Inject constructor(
    private val medicationDao: MedicationDao,
    private val scheduleTimeDao: ScheduleTimeDao,
    private val doseLogDao: DoseLogDao
) : MedicationRepository {

    override fun getAllMedications(): Flow<List<Medication>> =
        medicationDao.getAllMedications().map { entities ->
            entities.map { entity ->
                entity.toDomain(scheduleTimes = emptyList(), doseLogs = emptyList())
            }
        }

    override fun getMedication(id: String): Flow<Medication?> =
        combine(
            medicationDao.getMedicationById(id),
            scheduleTimeDao.getScheduleTimesForMedication(id),
            doseLogDao.getDoseLogsForMedication(id)
        ) { medication, scheduleTimes, doseLogs ->
            medication?.toDomain(scheduleTimes, doseLogs)
        }

    override suspend fun saveMedication(medication: Medication) {
        medicationDao.upsert(medication.toEntity())
        scheduleTimeDao.deleteForMedication(medication.id)
        scheduleTimeDao.insertAll(
            medication.scheduleTimes.map { it.toEntity(medication.id) }
        )
    }

    override suspend fun deleteMedication(id: String) {
        medicationDao.deleteById(id)
    }

    override suspend fun logDose(medicationId: String, scheduledTime: Instant, status: String) {
        doseLogDao.insert(
            DoseLogEntity(
                id = UUID.randomUUID().toString(),
                medicationId = medicationId,
                scheduledTime = scheduledTime.toEpochMilli(),
                actualTime = if (status == "taken") Instant.now().toEpochMilli() else null,
                status = status
            )
        )
    }

    override fun getDoseLogs(medicationId: String): Flow<List<DoseLog>> =
        doseLogDao.getDoseLogsForMedication(medicationId).map { entities ->
            entities.map { it.toDomain() }
        }
}
