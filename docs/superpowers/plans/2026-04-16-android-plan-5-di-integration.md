# Android Port Plan 5: DI Wiring + App Startup + Integration

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire all modules together with Hilt dependency injection, implement the Application class and MainActivity, register broadcast receivers in the manifest, add ProGuard rules, and write an integration test for the full create-schedule-log flow.

**Architecture:** Hilt modules live in `com.nateb.mymedtimer.di` inside the `app` module. Application class bootstraps notification channels. MainActivity hosts the Compose navigation graph. All receivers are statically registered in the manifest.

**Tech Stack:** Kotlin 2.0, Hilt 2.53.1, Jetpack Compose, Room, DataStore, JUnit 5, Turbine

---

## File Map

### Hilt DI Modules
- `android/app/src/main/kotlin/com/nateb/mymedtimer/di/DatabaseModule.kt` — provides AppDatabase + DAOs
- `android/app/src/main/kotlin/com/nateb/mymedtimer/di/RepositoryModule.kt` — binds MedicationRepositoryImpl to MedicationRepository
- `android/app/src/main/kotlin/com/nateb/mymedtimer/di/NotificationModule.kt` — provides AlarmScheduler + NotificationChannelManager
- `android/app/src/main/kotlin/com/nateb/mymedtimer/di/DataStoreModule.kt` — provides DataStore<Preferences>

### Application + Activity
- `android/app/src/main/kotlin/com/nateb/mymedtimer/MyMedTimerApp.kt` — update existing stub with @HiltAndroidApp + channel init
- `android/app/src/main/kotlin/com/nateb/mymedtimer/MainActivity.kt` — @AndroidEntryPoint, Compose host, permission request

### Manifest + ProGuard
- `android/app/src/main/AndroidManifest.xml` — update with receiver registrations
- `android/app/proguard-rules.pro` — Room + Hilt rules

### Integration Test
- `android/app/src/androidTest/kotlin/com/nateb/mymedtimer/MedicationFlowIntegrationTest.kt` — full flow test

---

### Task 1: Hilt DI Modules

**Files:**
- Create: `android/app/src/main/kotlin/com/nateb/mymedtimer/di/DatabaseModule.kt`
- Create: `android/app/src/main/kotlin/com/nateb/mymedtimer/di/RepositoryModule.kt`
- Create: `android/app/src/main/kotlin/com/nateb/mymedtimer/di/NotificationModule.kt`
- Create: `android/app/src/main/kotlin/com/nateb/mymedtimer/di/DataStoreModule.kt`

- [ ] **Step 1: Create DatabaseModule**

```kotlin
// android/app/src/main/kotlin/com/nateb/mymedtimer/di/DatabaseModule.kt
package com.nateb.mymedtimer.di

import android.content.Context
import androidx.room.Room
import com.nateb.mymedtimer.core.data.db.AppDatabase
import com.nateb.mymedtimer.core.data.db.MedicationDao
import com.nateb.mymedtimer.core.data.db.DoseLogDao
import com.nateb.mymedtimer.core.data.db.ScheduleTimeDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "mymedtimer.db"
        ).build()
    }

    @Provides
    fun provideMedicationDao(db: AppDatabase): MedicationDao = db.medicationDao()

    @Provides
    fun provideDoseLogDao(db: AppDatabase): DoseLogDao = db.doseLogDao()

    @Provides
    fun provideScheduleTimeDao(db: AppDatabase): ScheduleTimeDao = db.scheduleTimeDao()
}
```

- [ ] **Step 2: Create RepositoryModule**

```kotlin
// android/app/src/main/kotlin/com/nateb/mymedtimer/di/RepositoryModule.kt
package com.nateb.mymedtimer.di

import com.nateb.mymedtimer.core.data.repository.MedicationRepositoryImpl
import com.nateb.mymedtimer.domain.repository.MedicationRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindMedicationRepository(
        impl: MedicationRepositoryImpl
    ): MedicationRepository
}
```

- [ ] **Step 3: Create NotificationModule**

```kotlin
// android/app/src/main/kotlin/com/nateb/mymedtimer/di/NotificationModule.kt
package com.nateb.mymedtimer.di

import android.app.AlarmManager
import android.content.Context
import com.nateb.mymedtimer.core.data.notification.AlarmScheduler
import com.nateb.mymedtimer.core.data.notification.NotificationChannelManager
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NotificationModule {

    @Provides
    @Singleton
    fun provideAlarmManager(@ApplicationContext context: Context): AlarmManager {
        return context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    }

    @Provides
    @Singleton
    fun provideAlarmScheduler(
        @ApplicationContext context: Context,
        alarmManager: AlarmManager
    ): AlarmScheduler {
        return AlarmScheduler(context, alarmManager)
    }

    @Provides
    @Singleton
    fun provideNotificationChannelManager(
        @ApplicationContext context: Context
    ): NotificationChannelManager {
        return NotificationChannelManager(context)
    }
}
```

- [ ] **Step 4: Create DataStoreModule**

```kotlin
// android/app/src/main/kotlin/com/nateb/mymedtimer/di/DataStoreModule.kt
package com.nateb.mymedtimer.di

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore
import com.nateb.mymedtimer.core.data.preferences.PreferencesDataStore
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

@Module
@InstallIn(SingletonComponent::class)
object DataStoreModule {

    @Provides
    @Singleton
    fun provideDataStore(@ApplicationContext context: Context): DataStore<Preferences> {
        return context.dataStore
    }

    @Provides
    @Singleton
    fun providePreferencesDataStore(
        dataStore: DataStore<Preferences>
    ): PreferencesDataStore {
        return PreferencesDataStore(dataStore)
    }
}
```

- [ ] **Step 5: Verify DI modules compile**

```bash
cd android && ./gradlew :app:compileDebugKotlin
```

Expected: BUILD SUCCESSFUL — all Hilt modules resolve their dependencies.

- [ ] **Step 6: Commit**

```bash
git add android/app/src/main/kotlin/com/nateb/mymedtimer/di/
git commit -m "feat(android): add Hilt DI modules for database, repository, notifications, datastore"
```

---

### Task 2: Application Class + MainActivity

**Files:**
- Update: `android/app/src/main/kotlin/com/nateb/mymedtimer/MyMedTimerApp.kt`
- Create: `android/app/src/main/kotlin/com/nateb/mymedtimer/MainActivity.kt`

- [ ] **Step 1: Update MyMedTimerApp with @HiltAndroidApp and channel initialization**

Replace the existing stub entirely:

```kotlin
// android/app/src/main/kotlin/com/nateb/mymedtimer/MyMedTimerApp.kt
package com.nateb.mymedtimer

import android.app.Application
import com.nateb.mymedtimer.core.data.notification.NotificationChannelManager
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject

@HiltAndroidApp
class MyMedTimerApp : Application() {

    @Inject
    lateinit var notificationChannelManager: NotificationChannelManager

    override fun onCreate() {
        super.onCreate()
        notificationChannelManager.createChannels()
    }
}
```

- [ ] **Step 2: Create MainActivity**

```kotlin
// android/app/src/main/kotlin/com/nateb/mymedtimer/MainActivity.kt
package com.nateb.mymedtimer

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.core.content.ContextCompat
import com.nateb.mymedtimer.ui.theme.MyMedTimerTheme
import com.nateb.mymedtimer.navigation.MyMedTimerNavHost
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    private val notificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { _ -> }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        requestNotificationPermissionIfNeeded()

        setContent {
            MyMedTimerTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    MyMedTimerNavHost()
                }
            }
        }
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val permission = Manifest.permission.POST_NOTIFICATIONS
            if (ContextCompat.checkSelfPermission(this, permission)
                != PackageManager.PERMISSION_GRANTED
            ) {
                notificationPermissionLauncher.launch(permission)
            }
        }
    }
}
```

- [ ] **Step 3: Verify compilation**

```bash
cd android && ./gradlew :app:compileDebugKotlin
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Commit**

```bash
git add android/app/src/main/kotlin/com/nateb/mymedtimer/MyMedTimerApp.kt
git add android/app/src/main/kotlin/com/nateb/mymedtimer/MainActivity.kt
git commit -m "feat(android): implement Application class with Hilt and MainActivity with Compose"
```

---

### Task 3: AndroidManifest.xml Updates

**Files:**
- Update: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Update manifest with broadcast receiver registrations**

Replace the existing manifest entirely:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <application
        android:name=".MyMedTimerApp"
        android:allowBackup="true"
        android:label="MyMedTimer"
        android:supportsRtl="true"
        android:theme="@style/Theme.Material3.DynamicColors.DayNight">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.Material3.DynamicColors.DayNight">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- Fires when a medication alarm triggers -->
        <receiver
            android:name="com.nateb.mymedtimer.core.data.notification.MedicationAlarmReceiver"
            android:exported="false" />

        <!-- Handles notification button actions (Take, Skip, Snooze) -->
        <receiver
            android:name="com.nateb.mymedtimer.core.data.notification.NotificationActionReceiver"
            android:exported="false" />

        <!-- Reschedules alarms after device reboot -->
        <receiver
            android:name="com.nateb.mymedtimer.core.data.notification.BootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

- [ ] **Step 2: Verify manifest merges cleanly**

```bash
cd android && ./gradlew :app:processDebugManifest
```

Expected: BUILD SUCCESSFUL — no manifest merge conflicts.

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "feat(android): register broadcast receivers in manifest"
```

---

### Task 4: ProGuard Rules

**Files:**
- Create: `android/app/proguard-rules.pro`

- [ ] **Step 1: Create ProGuard rules for Room and Hilt**

```pro
# android/app/proguard-rules.pro

# Room
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-dontwarn androidx.room.paging.**

# Hilt
-keep class dagger.hilt.** { *; }
-keep class javax.inject.** { *; }
-keep class * extends dagger.hilt.android.internal.managers.ViewComponentManager$FragmentContextWrapper { *; }

# Keep @Inject constructors
-keepclasseswithmembers class * {
    @javax.inject.Inject <init>(...);
}

# Keep @AndroidEntryPoint activities
-keep @dagger.hilt.android.AndroidEntryPoint class * { *; }

# Kotlin serialization / metadata
-keepattributes *Annotation*
-keep class kotlin.Metadata { *; }

# Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}
```

- [ ] **Step 2: Verify release build config resolves proguard file**

```bash
cd android && ./gradlew :app:compileReleaseKotlin
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 3: Commit**

```bash
git add android/app/proguard-rules.pro
git commit -m "feat(android): add ProGuard rules for Room and Hilt"
```

---

### Task 5: Integration Test

**Files:**
- Create: `android/app/src/androidTest/kotlin/com/nateb/mymedtimer/MedicationFlowIntegrationTest.kt`

- [ ] **Step 1: Add androidTest dependencies to app build file**

Append to the `dependencies` block in `android/app/build.gradle.kts`:

```kotlin
    // Add these lines to the existing dependencies block
    androidTestImplementation(libs.compose.ui.test)
    debugImplementation(libs.compose.ui.test.manifest)
    androidTestImplementation(libs.hilt.android)
    kspAndroidTest(libs.hilt.compiler)
    androidTestImplementation(libs.coroutines.test)
    androidTestImplementation(libs.turbine)
    androidTestImplementation(libs.room.testing)
```

- [ ] **Step 2: Create integration test**

```kotlin
// android/app/src/androidTest/kotlin/com/nateb/mymedtimer/MedicationFlowIntegrationTest.kt
package com.nateb.mymedtimer

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.cash.turbine.test
import com.nateb.mymedtimer.core.data.db.AppDatabase
import com.nateb.mymedtimer.core.data.repository.MedicationRepositoryImpl
import com.nateb.mymedtimer.domain.model.Medication
import com.nateb.mymedtimer.domain.model.ScheduleTime
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.time.Instant

@RunWith(AndroidJUnit4::class)
class MedicationFlowIntegrationTest {

    private lateinit var db: AppDatabase
    private lateinit var repository: MedicationRepositoryImpl

    @Before
    fun setup() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        db = Room.inMemoryDatabaseBuilder(context, AppDatabase::class.java)
            .allowMainThreadQueries()
            .build()
        repository = MedicationRepositoryImpl(
            medicationDao = db.medicationDao(),
            doseLogDao = db.doseLogDao(),
            scheduleTimeDao = db.scheduleTimeDao()
        )
    }

    @After
    fun teardown() {
        db.close()
    }

    @Test
    fun createMedication_thenLogDose_fullFlow() = runTest {
        // 1. Create a medication
        val med = Medication(
            id = "test-med-1",
            name = "Aspirin",
            dosage = "100mg",
            scheduleTimes = listOf(ScheduleTime(hour = 8, minute = 0))
        )
        repository.saveMedication(med)

        // 2. Verify it was saved
        repository.getAllMedications().test {
            val meds = awaitItem()
            assertEquals(1, meds.size)
            assertEquals("Aspirin", meds[0].name)
            assertEquals("100mg", meds[0].dosage)
            assertEquals(1, meds[0].scheduleTimes.size)
            assertEquals(8, meds[0].scheduleTimes[0].hour)
            cancelAndConsumeRemainingEvents()
        }

        // 3. Log a dose
        val scheduledTime = Instant.now()
        repository.logDose(
            medicationId = "test-med-1",
            scheduledTime = scheduledTime,
            status = "taken"
        )

        // 4. Verify dose log was recorded
        repository.getDoseLogs("test-med-1").test {
            val logs = awaitItem()
            assertEquals(1, logs.size)
            assertEquals("taken", logs[0].status)
            assertNotNull(logs[0].actualTime)
            cancelAndConsumeRemainingEvents()
        }
    }

    @Test
    fun createAndDeleteMedication_flow() = runTest {
        val med = Medication(
            id = "test-med-2",
            name = "Ibuprofen",
            dosage = "200mg"
        )
        repository.saveMedication(med)

        // Verify created
        repository.getMedication("test-med-2").test {
            val result = awaitItem()
            assertNotNull(result)
            assertEquals("Ibuprofen", result!!.name)
            cancelAndConsumeRemainingEvents()
        }

        // Delete
        repository.deleteMedication("test-med-2")

        // Verify deleted
        repository.getMedication("test-med-2").test {
            val result = awaitItem()
            assertTrue(result == null)
            cancelAndConsumeRemainingEvents()
        }
    }

    @Test
    fun logMultipleDoseStatuses_flow() = runTest {
        val med = Medication(
            id = "test-med-3",
            name = "Vitamin D",
            dosage = "1000IU",
            scheduleTimes = listOf(
                ScheduleTime(hour = 9, minute = 0),
                ScheduleTime(hour = 21, minute = 0)
            )
        )
        repository.saveMedication(med)

        // Log different statuses
        val time1 = Instant.now()
        val time2 = time1.plusSeconds(3600)

        repository.logDose(medicationId = "test-med-3", scheduledTime = time1, status = "taken")
        repository.logDose(medicationId = "test-med-3", scheduledTime = time2, status = "skipped")

        // Verify both logs
        repository.getDoseLogs("test-med-3").test {
            val logs = awaitItem()
            assertEquals(2, logs.size)
            assertTrue(logs.any { it.status == "taken" })
            assertTrue(logs.any { it.status == "skipped" })
            cancelAndConsumeRemainingEvents()
        }
    }
}
```

- [ ] **Step 3: Add test runner dependency to version catalog**

Add to the `[libraries]` section in `android/gradle/libs.versions.toml`:

```toml
test-runner = { group = "androidx.test", name = "runner", version = "1.6.2" }
test-core = { group = "androidx.test", name = "core-ktx", version = "1.6.1" }
test-ext-junit = { group = "androidx.test.ext", name = "junit", version = "1.2.1" }
```

Add to `android/app/build.gradle.kts` dependencies:

```kotlin
    androidTestImplementation(libs.test.runner)
    androidTestImplementation(libs.test.core)
    androidTestImplementation(libs.test.ext.junit)
```

Add to the `android` block in `android/app/build.gradle.kts`:

```kotlin
    defaultConfig {
        // ... existing config ...
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
```

- [ ] **Step 4: Verify androidTest compiles**

```bash
cd android && ./gradlew :app:compileDebugAndroidTestKotlin
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Run integration tests on connected device or emulator**

```bash
cd android && ./gradlew :app:connectedDebugAndroidTest
```

Expected: all 3 tests pass.

- [ ] **Step 6: Commit**

```bash
git add android/app/build.gradle.kts
git add android/gradle/libs.versions.toml
git add android/app/src/androidTest/
git commit -m "feat(android): add integration tests for medication create-schedule-log flow"
```

---

### Task 6: Final Verification

- [ ] **Step 1: Full project build**

```bash
cd android && ./gradlew assembleDebug
```

Expected: BUILD SUCCESSFUL — full APK produced.

- [ ] **Step 2: Run all unit tests**

```bash
cd android && ./gradlew test
```

Expected: all math, data, and unit tests pass.

- [ ] **Step 3: Verify Hilt graph at compile time**

Hilt generates component code at compile time. If Step 1 succeeded, the graph is valid. Confirm no warnings:

```bash
cd android && ./gradlew :app:kspDebugKotlin 2>&1 | grep -i "error\|warning" || echo "No errors or warnings"
```

Expected: no Hilt-related errors.

- [ ] **Step 4: Final commit with all remaining changes**

```bash
git add -A android/
git commit -m "feat(android): complete DI wiring and integration assembly"
```

---

## Self-Review

**Spec coverage:**
- DatabaseModule (@Singleton, provides AppDatabase + 3 DAOs): Task 1 Step 1 ✓
- RepositoryModule (@Singleton, binds impl to interface): Task 1 Step 2 ✓
- NotificationModule (@Singleton, provides AlarmScheduler + NotificationChannelManager): Task 1 Step 3 ✓
- DataStoreModule (@Singleton, provides DataStore<Preferences> + PreferencesDataStore): Task 1 Step 4 ✓
- MyMedTimerApp with @HiltAndroidApp + channel creation: Task 2 Step 1 ✓
- MainActivity with @AndroidEntryPoint + Compose + permission request: Task 2 Step 2 ✓
- Manifest receiver registrations (MedicationAlarmReceiver, NotificationActionReceiver, BootReceiver): Task 3 Step 1 ✓
- ProGuard rules for Room and Hilt: Task 4 Step 1 ✓
- Integration test (create med -> log dose -> verify): Task 5 Step 2 ✓

**Placeholder scan:** No TBD, TODO, or vague steps found. All code is complete.

**Type consistency across all 5 plans:**
- `AppDatabase` — created in Plan 2, provided by `DatabaseModule` here via `Room.databaseBuilder`
- `MedicationDao`, `DoseLogDao`, `ScheduleTimeDao` — created in Plan 2, extracted from `AppDatabase` here
- `MedicationRepositoryImpl` — created in Plan 2, bound to `MedicationRepository` interface (Plan 1) via `@Binds`
- `AlarmScheduler(context, alarmManager)` — created in Plan 3, constructor matches `NotificationModule.provideAlarmScheduler`
- `NotificationChannelManager(context)` — created in Plan 3, injected into `MyMedTimerApp`
- `PreferencesDataStore(dataStore)` — created in Plan 2, provided by `DataStoreModule`
- `MedicationAlarmReceiver`, `NotificationActionReceiver`, `BootReceiver` — created in Plan 3, registered in manifest here
- `MyMedTimerTheme` — created in Plan 4, used in `MainActivity.setContent`
- `MyMedTimerNavHost` — created in Plan 4, hosted in `MainActivity`
- `Medication`, `ScheduleTime`, `DoseLog` — domain models from Plan 1, used in integration test
- `MedicationRepository` — interface from Plan 1, bound in `RepositoryModule`

**Package consistency:**
- `com.nateb.mymedtimer.di` — all Hilt modules
- `com.nateb.mymedtimer` — Application class + MainActivity
- `com.nateb.mymedtimer.core.data.db` — database classes (Plan 2)
- `com.nateb.mymedtimer.core.data.repository` — repository impl (Plan 2)
- `com.nateb.mymedtimer.core.data.notification` — notification classes (Plan 3)
- `com.nateb.mymedtimer.core.data.preferences` — DataStore wrapper (Plan 2)
- `com.nateb.mymedtimer.domain.model` — domain models (Plan 1)
- `com.nateb.mymedtimer.domain.repository` — repository interface (Plan 1)
- `com.nateb.mymedtimer.ui.theme` — theme (Plan 4)
- `com.nateb.mymedtimer.navigation` — nav host (Plan 4)

All types, method signatures, constructor parameters, and package names are consistent across plans.
