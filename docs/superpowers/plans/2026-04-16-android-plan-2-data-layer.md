# Android Port Plan 2: Core Data Layer

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Room database (entities, DAOs, type converters, database), entity-to-domain mappers, repository implementation, DataStore preferences, and tests for the core/data module.

**Architecture:** Room entities mirror the domain models with relational foreign keys. DAOs return `Flow` for reactive queries. Mappers convert between entity and domain layers, keeping the domain module free of Room annotations. DataStore wraps `Preferences` for app settings. Hilt provides DI wiring.

**Tech Stack:** Room 2.6.1, DataStore Preferences 1.1.1, Hilt 2.53.1, Kotlin Coroutines 1.9.0, JUnit 5 (unit tests), JUnit 4 + Room testing (instrumented tests), Turbine 1.2.0.

---

## File Map

### Room Entities
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/MedicationEntity.kt`
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/ScheduleTimeEntity.kt`
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/DoseLogEntity.kt`

### Type Converters
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/Converters.kt`

### DAOs
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/MedicationDao.kt`
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/ScheduleTimeDao.kt`
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/DoseLogDao.kt`

### Database
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/AppDatabase.kt`

### Mappers
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/mapper/MedicationMapper.kt`

### Repository Implementation
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/repository/MedicationRepositoryImpl.kt`

### Preferences
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/preferences/PreferencesDataStore.kt`

### DI
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/di/DataModule.kt`

### Tests
- `android/core/data/src/test/kotlin/com/nateb/mymedtimer/data/mapper/MedicationMapperTest.kt`
- `android/core/data/src/androidTest/kotlin/com/nateb/mymedtimer/data/local/MedicationDaoTest.kt`
- `android/core/data/src/androidTest/kotlin/com/nateb/mymedtimer/data/local/DoseLogDaoTest.kt`

---

### Task 1: Room Entities and Type Converters

**Files:**
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/MedicationEntity.kt`
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/ScheduleTimeEntity.kt`
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/DoseLogEntity.kt`
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/Converters.kt`

- [ ] **Step 1: Create MedicationEntity**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/MedicationEntity.kt
package com.nateb.mymedtimer.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "medications")
data class MedicationEntity(
    @PrimaryKey
    val id: String,
    val name: String,
    val dosage: String,
    val colorHex: String,
    val alertStyle: String,
    val isPRN: Boolean,
    val minIntervalMinutes: Int,
    val isActive: Boolean,
    val createdAt: Long
)
```

- [ ] **Step 2: Create ScheduleTimeEntity**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/ScheduleTimeEntity.kt
package com.nateb.mymedtimer.data.local

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "schedule_times",
    foreignKeys = [
        ForeignKey(
            entity = MedicationEntity::class,
            parentColumns = ["id"],
            childColumns = ["medicationId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("medicationId")]
)
data class ScheduleTimeEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val medicationId: String,
    val hour: Int,
    val minute: Int
)
```

- [ ] **Step 3: Create DoseLogEntity**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/DoseLogEntity.kt
package com.nateb.mymedtimer.data.local

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "dose_logs",
    foreignKeys = [
        ForeignKey(
            entity = MedicationEntity::class,
            parentColumns = ["id"],
            childColumns = ["medicationId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("medicationId")]
)
data class DoseLogEntity(
    @PrimaryKey
    val id: String,
    val medicationId: String,
    val scheduledTime: Long,
    val actualTime: Long?,
    val status: String
)
```

- [ ] **Step 4: Create Converters for Instant/Long**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/Converters.kt
package com.nateb.mymedtimer.data.local

import androidx.room.TypeConverter
import java.time.Instant

class Converters {
    @TypeConverter
    fun fromInstant(instant: Instant?): Long? = instant?.toEpochMilli()

    @TypeConverter
    fun toInstant(epochMilli: Long?): Instant? = epochMilli?.let { Instant.ofEpochMilli(it) }
}
```

- [ ] **Step 5: Verify compilation**

```bash
cd android && ./gradlew :core:data:compileDebugKotlin
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 6: Commit**

```bash
git add android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/
git commit -m "feat(android): add Room entities and type converters"
```

---

### Task 2: Room DAOs

**Files:**
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/MedicationDao.kt`
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/ScheduleTimeDao.kt`
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/DoseLogDao.kt`

- [ ] **Step 1: Create MedicationDao**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/MedicationDao.kt
package com.nateb.mymedtimer.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import kotlinx.coroutines.flow.Flow

@Dao
interface MedicationDao {

    @Query("SELECT * FROM medications ORDER BY name ASC")
    fun getAllMedications(): Flow<List<MedicationEntity>>

    @Query("SELECT * FROM medications WHERE id = :id")
    fun getMedicationById(id: String): Flow<MedicationEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(medication: MedicationEntity)

    @Query("DELETE FROM medications WHERE id = :id")
    suspend fun deleteById(id: String)
}
```

- [ ] **Step 2: Create ScheduleTimeDao**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/ScheduleTimeDao.kt
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
```

- [ ] **Step 3: Create DoseLogDao**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/DoseLogDao.kt
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
```

- [ ] **Step 4: Verify compilation**

```bash
cd android && ./gradlew :core:data:compileDebugKotlin
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/
git commit -m "feat(android): add Room DAOs for medications, schedule times, dose logs"
```

---

### Task 3: AppDatabase

**Files:**
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/AppDatabase.kt`

- [ ] **Step 1: Create AppDatabase**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/AppDatabase.kt
package com.nateb.mymedtimer.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters

@Database(
    entities = [
        MedicationEntity::class,
        ScheduleTimeEntity::class,
        DoseLogEntity::class
    ],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun medicationDao(): MedicationDao
    abstract fun scheduleTimeDao(): ScheduleTimeDao
    abstract fun doseLogDao(): DoseLogDao
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd android && ./gradlew :core:data:compileDebugKotlin
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 3: Commit**

```bash
git add android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/local/AppDatabase.kt
git commit -m "feat(android): add Room AppDatabase with type converters"
```

---

### Task 4: Entity-to-Domain Mappers

**Files:**
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/mapper/MedicationMapper.kt`

- [ ] **Step 1: Create mapper functions**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/mapper/MedicationMapper.kt
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
```

- [ ] **Step 2: Verify compilation**

```bash
cd android && ./gradlew :core:data:compileDebugKotlin
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 3: Commit**

```bash
git add android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/mapper/
git commit -m "feat(android): add entity-to-domain mappers"
```

---

### Task 5: Mapper Unit Tests

**Files:**
- Create: `android/core/data/src/test/kotlin/com/nateb/mymedtimer/data/mapper/MedicationMapperTest.kt`

- [ ] **Step 1: Create mapper tests**

```kotlin
// android/core/data/src/test/kotlin/com/nateb/mymedtimer/data/mapper/MedicationMapperTest.kt
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
```

- [ ] **Step 2: Run mapper tests**

```bash
cd android && ./gradlew :core:data:test
```

Expected: all 5 tests pass, BUILD SUCCESSFUL

- [ ] **Step 3: Commit**

```bash
git add android/core/data/src/test/
git commit -m "test(android): add unit tests for entity-to-domain mappers"
```

---

### Task 6: MedicationRepositoryImpl

**Files:**
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/repository/MedicationRepositoryImpl.kt`

- [ ] **Step 1: Create MedicationRepositoryImpl**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/repository/MedicationRepositoryImpl.kt
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
```

- [ ] **Step 2: Verify compilation**

```bash
cd android && ./gradlew :core:data:compileDebugKotlin
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 3: Commit**

```bash
git add android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/repository/
git commit -m "feat(android): add MedicationRepositoryImpl using Room DAOs"
```

---

### Task 7: PreferencesDataStore

**Files:**
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/preferences/PreferencesDataStore.kt`

- [ ] **Step 1: Create PreferencesDataStore**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/preferences/PreferencesDataStore.kt
package com.nateb.mymedtimer.data.preferences

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

data class AppSettings(
    val defaultSnoozeMinutes: Int = 10,
    val nagIntervalMinutes: Int = 5,
    val defaultAlertStyle: String = "gentle"
)

class PreferencesDataStore @Inject constructor(
    private val dataStore: DataStore<Preferences>
) {
    private companion object {
        val DEFAULT_SNOOZE_MINUTES = intPreferencesKey("default_snooze_minutes")
        val NAG_INTERVAL_MINUTES = intPreferencesKey("nag_interval_minutes")
        val DEFAULT_ALERT_STYLE = stringPreferencesKey("default_alert_style")
    }

    val settings: Flow<AppSettings> = dataStore.data.map { prefs ->
        AppSettings(
            defaultSnoozeMinutes = prefs[DEFAULT_SNOOZE_MINUTES] ?: 10,
            nagIntervalMinutes = prefs[NAG_INTERVAL_MINUTES] ?: 5,
            defaultAlertStyle = prefs[DEFAULT_ALERT_STYLE] ?: "gentle"
        )
    }

    suspend fun updateDefaultSnoozeMinutes(minutes: Int) {
        dataStore.edit { prefs ->
            prefs[DEFAULT_SNOOZE_MINUTES] = minutes
        }
    }

    suspend fun updateNagIntervalMinutes(minutes: Int) {
        dataStore.edit { prefs ->
            prefs[NAG_INTERVAL_MINUTES] = minutes
        }
    }

    suspend fun updateDefaultAlertStyle(style: String) {
        dataStore.edit { prefs ->
            prefs[DEFAULT_ALERT_STYLE] = style
        }
    }
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd android && ./gradlew :core:data:compileDebugKotlin
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 3: Commit**

```bash
git add android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/preferences/
git commit -m "feat(android): add PreferencesDataStore for app settings"
```

---

### Task 8: Hilt DI Module

**Files:**
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/di/DataModule.kt`

- [ ] **Step 1: Create DataModule**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/di/DataModule.kt
package com.nateb.mymedtimer.data.di

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore
import androidx.room.Room
import com.nateb.mymedtimer.data.local.AppDatabase
import com.nateb.mymedtimer.data.local.DoseLogDao
import com.nateb.mymedtimer.data.local.MedicationDao
import com.nateb.mymedtimer.data.local.ScheduleTimeDao
import com.nateb.mymedtimer.data.repository.MedicationRepositoryImpl
import com.nateb.mymedtimer.domain.repository.MedicationRepository
import dagger.Binds
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

@Module
@InstallIn(SingletonComponent::class)
object DataModule {

    @Provides
    @Singleton
    fun provideAppDatabase(@ApplicationContext context: Context): AppDatabase =
        Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "mymedtimer.db"
        ).build()

    @Provides
    fun provideMedicationDao(db: AppDatabase): MedicationDao = db.medicationDao()

    @Provides
    fun provideScheduleTimeDao(db: AppDatabase): ScheduleTimeDao = db.scheduleTimeDao()

    @Provides
    fun provideDoseLogDao(db: AppDatabase): DoseLogDao = db.doseLogDao()

    @Provides
    @Singleton
    fun provideDataStore(@ApplicationContext context: Context): DataStore<Preferences> =
        context.dataStore
}

@Module
@InstallIn(SingletonComponent::class)
abstract class DataBindingsModule {

    @Binds
    abstract fun bindMedicationRepository(
        impl: MedicationRepositoryImpl
    ): MedicationRepository
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd android && ./gradlew :core:data:compileDebugKotlin
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 3: Commit**

```bash
git add android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/di/
git commit -m "feat(android): add Hilt DI module for Room, DataStore, and repository binding"
```

---

### Task 9: Room DAO Instrumented Tests

**Files:**
- Update: `android/core/data/build.gradle.kts` (add test dependencies)
- Create: `android/core/data/src/androidTest/kotlin/com/nateb/mymedtimer/data/local/MedicationDaoTest.kt`
- Create: `android/core/data/src/androidTest/kotlin/com/nateb/mymedtimer/data/local/DoseLogDaoTest.kt`

- [ ] **Step 1: Update build.gradle.kts with test dependencies**

Add these lines to the `dependencies` block in `android/core/data/build.gradle.kts`:

```kotlin
// Add to existing dependencies block in android/core/data/build.gradle.kts
    androidTestImplementation("androidx.test:runner:1.6.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation(libs.coroutines.test)
    androidTestImplementation(libs.turbine)
```

The final `dependencies` block should be:

```kotlin
dependencies {
    implementation(project(":core:domain"))
    implementation(libs.room.runtime)
    implementation(libs.room.ktx)
    ksp(libs.room.compiler)
    implementation(libs.datastore.preferences)
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.coroutines.android)
    testImplementation(libs.junit5.api)
    testRuntimeOnly(libs.junit5.engine)
    androidTestImplementation(libs.room.testing)
    androidTestImplementation("androidx.test:runner:1.6.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation(libs.coroutines.test)
    androidTestImplementation(libs.turbine)
}
```

- [ ] **Step 2: Create MedicationDaoTest**

```kotlin
// android/core/data/src/androidTest/kotlin/com/nateb/mymedtimer/data/local/MedicationDaoTest.kt
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
```

- [ ] **Step 3: Create DoseLogDaoTest**

```kotlin
// android/core/data/src/androidTest/kotlin/com/nateb/mymedtimer/data/local/DoseLogDaoTest.kt
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
```

- [ ] **Step 4: Verify compilation of instrumented tests**

```bash
cd android && ./gradlew :core:data:compileDebugAndroidTestKotlin
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add android/core/data/build.gradle.kts android/core/data/src/androidTest/
git commit -m "test(android): add Room DAO instrumented tests for medications and dose logs"
```

---

### Task 10: Run Full Test Suite and Final Verification

- [ ] **Step 1: Run unit tests**

```bash
cd android && ./gradlew :core:data:test
```

Expected: 5 mapper tests pass, BUILD SUCCESSFUL

- [ ] **Step 2: Run full project compilation**

```bash
cd android && ./gradlew assembleDebug
```

Expected: BUILD SUCCESSFUL (full app assembles with data layer wired)

- [ ] **Step 3: Commit all remaining changes**

```bash
git add -A android/core/data/
git commit -m "feat(android): complete core data layer — Room, repository, DataStore, DI"
```

---

## Self-Review

**Spec coverage:**
- Room entities (MedicationEntity, ScheduleTimeEntity, DoseLogEntity): Task 1 ✓
- Type converters (Instant/Long): Task 1 ✓
- Room DAOs (MedicationDao, ScheduleTimeDao, DoseLogDao) returning Flow: Task 2 ✓
- AppDatabase with @Database annotation: Task 3 ✓
- Entity-to-domain mappers: Task 4 ✓
- MedicationRepositoryImpl: Task 6 ✓
- PreferencesDataStore with AppSettings: Task 7 ✓
- Hilt DI module: Task 8 ✓
- Mapper unit tests: Task 5 ✓
- Room DAO instrumented tests: Task 9 ✓

**Placeholder scan:** No TBD, TODO, or vague steps found. All code blocks are complete.

**Type consistency:**
- `Instant` ↔ `Long` (epochMilli) used consistently in entities, mappers, and type converters
- `MedicationEntity.createdAt` is `Long`, mapped to `Medication.createdAt` as `Instant` — consistent
- `DoseLogEntity.actualTime` is `Long?`, mapped to `DoseLog.actualTime` as `Instant?` — consistent
- `ScheduleTimeEntity` uses `Long` auto-generated PK, `ScheduleTime` domain has no id (hour/minute only) — intentional: domain doesn't need the DB surrogate key
- `MedicationRepository` interface from Plan 1 is fully implemented by `MedicationRepositoryImpl`
- `AppSettings` defaults (snooze=10, nag=5, alertStyle="gentle") match iOS UserDefaults spec
- Foreign keys with CASCADE delete on both ScheduleTimeEntity and DoseLogEntity — matches iOS SwiftData cascade behavior
- All packages match the specified naming convention (data.local, data.mapper, data.repository, data.preferences, data.di)

All types, method signatures, and property names are consistent across tasks and with Plan 1 domain models.
