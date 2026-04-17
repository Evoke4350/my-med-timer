package com.nateb.mymedtimer.data.mapper

import com.nateb.mymedtimer.data.local.DoseLogEntity
import com.nateb.mymedtimer.data.local.MedicationEntity
import com.nateb.mymedtimer.data.local.ScheduleTimeEntity
import com.nateb.mymedtimer.domain.model.DoseLog
import com.nateb.mymedtimer.domain.model.Medication
import com.nateb.mymedtimer.domain.model.ScheduleTime
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test
import java.time.Instant

class MedicationMapperTest {

    @Test
    fun `MedicationEntity toDomain maps all fields`() {
        val entity = MedicationEntity(
            id = "med-1",
            name = "Aspirin",
            dosage = "100mg",
            colorHex = "#FF0000",
            alertStyle = "urgent",
            isPRN = true,
            minIntervalMinutes = 240,
            isActive = true,
            createdAt = 1700000000000L
        )
        val schedules = listOf(
            ScheduleTimeEntity(id = 1, medicationId = "med-1", hour = 8, minute = 0),
            ScheduleTimeEntity(id = 2, medicationId = "med-1", hour = 20, minute = 30)
        )
        val logs = listOf(
            DoseLogEntity(
                id = "log-1",
                medicationId = "med-1",
                scheduledTime = 1700000000000L,
                actualTime = 1700000060000L,
                status = "taken"
            )
        )

        val domain = entity.toDomain(schedules, logs)

        assertEquals("med-1", domain.id)
        assertEquals("Aspirin", domain.name)
        assertEquals("100mg", domain.dosage)
        assertEquals("#FF0000", domain.colorHex)
        assertEquals("urgent", domain.alertStyle)
        assertEquals(true, domain.isPRN)
        assertEquals(240, domain.minIntervalMinutes)
        assertEquals(true, domain.isActive)
        assertEquals(Instant.ofEpochMilli(1700000000000L), domain.createdAt)
        assertEquals(2, domain.scheduleTimes.size)
        assertEquals(8, domain.scheduleTimes[0].hour)
        assertEquals(0, domain.scheduleTimes[0].minute)
        assertEquals(20, domain.scheduleTimes[1].hour)
        assertEquals(30, domain.scheduleTimes[1].minute)
        assertEquals(1, domain.doseLogs.size)
        assertEquals("log-1", domain.doseLogs[0].id)
        assertEquals("taken", domain.doseLogs[0].status)
    }

    @Test
    fun `Medication toEntity maps all fields`() {
        val domain = Medication(
            id = "med-1",
            name = "Aspirin",
            dosage = "100mg",
            colorHex = "#FF0000",
            alertStyle = "urgent",
            isPRN = true,
            minIntervalMinutes = 240,
            isActive = true,
            createdAt = Instant.ofEpochMilli(1700000000000L)
        )

        val entity = domain.toEntity()

        assertEquals("med-1", entity.id)
        assertEquals("Aspirin", entity.name)
        assertEquals("100mg", entity.dosage)
        assertEquals("#FF0000", entity.colorHex)
        assertEquals("urgent", entity.alertStyle)
        assertEquals(true, entity.isPRN)
        assertEquals(240, entity.minIntervalMinutes)
        assertEquals(true, entity.isActive)
        assertEquals(1700000000000L, entity.createdAt)
    }

    @Test
    fun `ScheduleTime round-trips through entity`() {
        val original = ScheduleTime(hour = 14, minute = 30)
        val entity = original.toEntity("med-1")
        val result = entity.toDomain()

        assertEquals(original.hour, result.hour)
        assertEquals(original.minute, result.minute)
        assertEquals("med-1", entity.medicationId)
    }

    @Test
    fun `DoseLog round-trips through entity with actualTime`() {
        val original = DoseLog(
            id = "log-1",
            scheduledTime = Instant.ofEpochMilli(1700000000000L),
            actualTime = Instant.ofEpochMilli(1700000060000L),
            status = "taken"
        )
        val entity = original.toEntity("med-1")
        val result = entity.toDomain()

        assertEquals(original.id, result.id)
        assertEquals(original.scheduledTime, result.scheduledTime)
        assertEquals(original.actualTime, result.actualTime)
        assertEquals(original.status, result.status)
        assertEquals("med-1", entity.medicationId)
    }

    @Test
    fun `DoseLog round-trips through entity with null actualTime`() {
        val original = DoseLog(
            id = "log-2",
            scheduledTime = Instant.ofEpochMilli(1700000000000L),
            actualTime = null,
            status = "skipped"
        )
        val entity = original.toEntity("med-1")
        val result = entity.toDomain()

        assertNull(result.actualTime)
        assertEquals("skipped", result.status)
    }
}
