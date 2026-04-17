package com.nateb.mymedtimer.data.local

import androidx.room.Room
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import app.cash.turbine.test
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class MedicationDaoTest {

    private lateinit var db: AppDatabase
    private lateinit var medicationDao: MedicationDao
    private lateinit var scheduleTimeDao: ScheduleTimeDao

    @Before
    fun setup() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        db = Room.inMemoryDatabaseBuilder(context, AppDatabase::class.java)
            .allowMainThreadQueries()
            .build()
        medicationDao = db.medicationDao()
        scheduleTimeDao = db.scheduleTimeDao()
    }

    @After
    fun teardown() {
        db.close()
    }

    private fun makeMedication(id: String = "med-1", name: String = "Aspirin") =
        MedicationEntity(
            id = id,
            name = name,
            dosage = "100mg",
            colorHex = "#FF6B6B",
            alertStyle = "gentle",
            isPRN = false,
            minIntervalMinutes = 0,
            isActive = true,
            createdAt = 1700000000000L
        )

    @Test
    fun insertAndRetrieveMedication() = runTest {
        val entity = makeMedication()
        medicationDao.upsert(entity)

        medicationDao.getMedicationById("med-1").test {
            val result = awaitItem()
            assertEquals("Aspirin", result?.name)
            cancelAndIgnoreRemainingEvents()
        }
    }

    @Test
    fun getAllMedicationsReturnsSortedByName() = runTest {
        medicationDao.upsert(makeMedication(id = "1", name = "Zoloft"))
        medicationDao.upsert(makeMedication(id = "2", name = "Aspirin"))
        medicationDao.upsert(makeMedication(id = "3", name = "Metformin"))

        medicationDao.getAllMedications().test {
            val result = awaitItem()
            assertEquals(listOf("Aspirin", "Metformin", "Zoloft"), result.map { it.name })
            cancelAndIgnoreRemainingEvents()
        }
    }

    @Test
    fun upsertOverwritesExisting() = runTest {
        medicationDao.upsert(makeMedication(name = "Aspirin"))
        medicationDao.upsert(makeMedication(name = "Updated Aspirin"))

        medicationDao.getMedicationById("med-1").test {
            val result = awaitItem()
            assertEquals("Updated Aspirin", result?.name)
            cancelAndIgnoreRemainingEvents()
        }
    }

    @Test
    fun deleteRemovesMedication() = runTest {
        medicationDao.upsert(makeMedication())
        medicationDao.deleteById("med-1")

        medicationDao.getMedicationById("med-1").test {
            val result = awaitItem()
            assertNull(result)
            cancelAndIgnoreRemainingEvents()
        }
    }

    @Test
    fun deleteMedicationCascadesToScheduleTimes() = runTest {
        medicationDao.upsert(makeMedication())
        scheduleTimeDao.insertAll(
            listOf(
                ScheduleTimeEntity(medicationId = "med-1", hour = 8, minute = 0),
                ScheduleTimeEntity(medicationId = "med-1", hour = 20, minute = 0)
            )
        )

        medicationDao.deleteById("med-1")

        scheduleTimeDao.getScheduleTimesForMedication("med-1").test {
            val result = awaitItem()
            assertEquals(0, result.size)
            cancelAndIgnoreRemainingEvents()
        }
    }
}
