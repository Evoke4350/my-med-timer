package com.nateb.mymedtimer

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.cash.turbine.test
import com.nateb.mymedtimer.data.local.AppDatabase
import com.nateb.mymedtimer.data.repository.MedicationRepositoryImpl
import com.nateb.mymedtimer.domain.model.Medication
import com.nateb.mymedtimer.domain.model.ScheduleTime
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.time.Instant

@RunWith(AndroidJUnit4::class)
class MedicationFlowIntegrationTest {

    private lateinit var database: AppDatabase
    private lateinit var repository: MedicationRepositoryImpl

    @Before
    fun setup() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            AppDatabase::class.java
        ).allowMainThreadQueries().build()

        repository = MedicationRepositoryImpl(
            medicationDao = database.medicationDao(),
            scheduleTimeDao = database.scheduleTimeDao(),
            doseLogDao = database.doseLogDao()
        )
    }

    @After
    fun teardown() {
        database.close()
    }

    @Test
    fun createMedicationAndVerify() = runTest {
        val med = Medication(
            id = "test-1",
            name = "Aspirin",
            dosage = "500mg",
            colorHex = "#FF6B6B",
            scheduleTimes = listOf(ScheduleTime(8, 0), ScheduleTime(20, 0))
        )

        repository.saveMedication(med)

        repository.getAllMedications().test {
            val meds = awaitItem()
            assertEquals(1, meds.size)
            assertEquals("Aspirin", meds[0].name)
            assertEquals("500mg", meds[0].dosage)
            cancelAndIgnoreRemainingEvents()
        }
    }

    @Test
    fun createAndDeleteMedication() = runTest {
        val med = Medication(
            id = "test-2",
            name = "Ibuprofen",
            dosage = "200mg",
            colorHex = "#4ECDC4"
        )

        repository.saveMedication(med)

        repository.getAllMedications().test {
            assertEquals(1, awaitItem().size)
            cancelAndIgnoreRemainingEvents()
        }

        repository.deleteMedication("test-2")

        repository.getAllMedications().test {
            assertTrue(awaitItem().isEmpty())
            cancelAndIgnoreRemainingEvents()
        }
    }

    @Test
    fun logMultipleDoseStatuses() = runTest {
        val med = Medication(
            id = "test-3",
            name = "Vitamin D",
            dosage = "1000IU",
            colorHex = "#45B7D1"
        )

        repository.saveMedication(med)

        val now = Instant.now()
        repository.logDose("test-3", now, "taken")
        repository.logDose("test-3", now.plusSeconds(3600), "skipped")
        repository.logDose("test-3", now.plusSeconds(7200), "snoozed")

        repository.getDoseLogs("test-3").test {
            val logs = awaitItem()
            assertEquals(3, logs.size)
            assertTrue(logs.any { it.status == "taken" })
            assertTrue(logs.any { it.status == "skipped" })
            assertTrue(logs.any { it.status == "snoozed" })
            cancelAndIgnoreRemainingEvents()
        }
    }
}
