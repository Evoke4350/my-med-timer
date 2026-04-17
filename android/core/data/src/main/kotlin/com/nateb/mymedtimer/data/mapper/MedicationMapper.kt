package com.nateb.mymedtimer.data.mapper

import com.nateb.mymedtimer.data.local.DoseLogEntity
import com.nateb.mymedtimer.data.local.MedicationEntity
import com.nateb.mymedtimer.data.local.ScheduleTimeEntity
import com.nateb.mymedtimer.domain.model.DoseLog
import com.nateb.mymedtimer.domain.model.Medication
import com.nateb.mymedtimer.domain.model.ScheduleTime
import java.time.Instant

fun MedicationEntity.toDomain(
    scheduleTimes: List<ScheduleTimeEntity>,
    doseLogs: List<DoseLogEntity>
): Medication = Medication(
    id = id,
    name = name,
    dosage = dosage,
    colorHex = colorHex,
    alertStyle = alertStyle,
    isPRN = isPRN,
    minIntervalMinutes = minIntervalMinutes,
    isActive = isActive,
    createdAt = Instant.ofEpochMilli(createdAt),
    scheduleTimes = scheduleTimes.map { it.toDomain() },
    doseLogs = doseLogs.map { it.toDomain() }
)

fun Medication.toEntity(): MedicationEntity = MedicationEntity(
    id = id,
    name = name,
    dosage = dosage,
    colorHex = colorHex,
    alertStyle = alertStyle,
    isPRN = isPRN,
    minIntervalMinutes = minIntervalMinutes,
    isActive = isActive,
    createdAt = createdAt.toEpochMilli()
)

fun ScheduleTimeEntity.toDomain(): ScheduleTime = ScheduleTime(
    hour = hour,
    minute = minute
)

fun ScheduleTime.toEntity(medicationId: String): ScheduleTimeEntity = ScheduleTimeEntity(
    medicationId = medicationId,
    hour = hour,
    minute = minute
)

fun DoseLogEntity.toDomain(): DoseLog = DoseLog(
    id = id,
    scheduledTime = Instant.ofEpochMilli(scheduledTime),
    actualTime = actualTime?.let { Instant.ofEpochMilli(it) },
    status = status
)

fun DoseLog.toEntity(medicationId: String): DoseLogEntity = DoseLogEntity(
    id = id,
    medicationId = medicationId,
    scheduledTime = scheduledTime.toEpochMilli(),
    actualTime = actualTime?.toEpochMilli(),
    status = status
)
