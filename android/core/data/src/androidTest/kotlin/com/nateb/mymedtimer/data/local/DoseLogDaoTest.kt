package com.nateb.mymedtimer.data.local

import androidx.room.Room
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import app.cash.turbine.test
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class DoseLogDaoTest {

    private lateinit var db: AppDatabase
    private lateinit var medicationDao: MedicationDao
    private lateinit var doseLogDao: DoseLogDao

    @Before
    fun setup() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        db = Room.inMemoryDatabaseBuilder(context, AppDatabase::class.java)
            .allowMainThreadQueries()
            .build()
        medicationDao = db.medicationDao()
        doseLogDao = db.doseLogDao()
    }

    @After
    fun teardown() {
        db.close()
    }

    private val medication = MedicationEntity(
        id = "med-1",
        name = "Aspirin",
        dosage = "100mg",
        colorHex = "#FF6B6B",
        alertStyle = "gentle",
        isPRN = false,
        minIntervalMinutes = 0,
        isActive = true,
        createdAt = 1700000000000L
    )

    @Test
    fun insertAndRetrieveDoseLogs() = runTest {
        medicationDao.upsert(medication)
        doseLogDao.insert(
            DoseLogEntity(
                id = "log-1",
                medicationId = "med-1",
                scheduledTime = 1700000000000L,
                actualTime = 1700000060000L,
                status = "taken"
            )
        )

        doseLogDao.getDoseLogsForMedication("med-1").test {
            val result = awaitItem()
            assertEquals(1, result.size)
            assertEquals("taken", result[0].status)
            assertEquals(1700000060000L, result[0].actualTime)
            cancelAndIgnoreRemainingEvents()
        }
    }

    @Test
    fun doseLogsReturnedInDescendingScheduledTimeOrder() = runTest {
        medicationDao.upsert(medication)
        doseLogDao.insert(
            DoseLogEntity(
                id = "log-1",
                medicationId = "med-1",
                scheduledTime = 1700000000000L,
                actualTime = null,
                status = "skipped"
            )
        )
        doseLogDao.insert(
            DoseLogEntity(
                id = "log-2",
                medicationId = "med-1",
                scheduledTime = 1700003600000L,
                actualTime = 1700003600000L,
                status = "taken"
            )
        )

        doseLogDao.getDoseLogsForMedication("med-1").test {
            val result = awaitItem()
            assertEquals(2, result.size)
            assertEquals("log-2", result[0].id)
            assertEquals("log-1", result[1].id)
            cancelAndIgnoreRemainingEvents()
        }
    }

    @Test
    fun deleteMedicationCascadesToDoseLogs() = runTest {
        medicationDao.upsert(medication)
        doseLogDao.insert(
            DoseLogEntity(
                id = "log-1",
                medicationId = "med-1",
                scheduledTime = 1700000000000L,
                actualTime = null,
                status = "skipped"
            )
        )

        medicationDao.deleteById("med-1")

        doseLogDao.getDoseLogsForMedication("med-1").test {
            val result = awaitItem()
            assertEquals(0, result.size)
            cancelAndIgnoreRemainingEvents()
        }
    }

    @Test
    fun doseLogWithNullActualTime() = runTest {
        medicationDao.upsert(medication)
        doseLogDao.insert(
            DoseLogEntity(
                id = "log-1",
                medicationId = "med-1",
                scheduledTime = 1700000000000L,
                actualTime = null,
                status = "snoozed"
            )
        )

        doseLogDao.getDoseLogsForMedication("med-1").test {
            val result = awaitItem()
            assertEquals(1, result.size)
            assertEquals(null, result[0].actualTime)
            assertEquals("snoozed", result[0].status)
            cancelAndIgnoreRemainingEvents()
        }
    }
}
