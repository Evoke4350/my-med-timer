# MyMedTimer Android Port

Full-parity Android port of MyMedTimer using Jetpack Compose, Room, and Hilt. Multi-module clean architecture. Targets API 33+ (GrapheneOS on Pixel devices). No Google Play Services dependencies.

## Constraints

- Min SDK: API 33 (Android 13)
- No GMS dependency (GrapheneOS compatible)
- All notifications local (no FCM)
- Distribution: F-Droid, GitHub releases, or direct APK
- Dark theme only, monospace typography (matching iOS)

## Module Structure

```
android/
├── app/                          # Entry point, Hilt wiring, navigation, receivers
├── core/
│   ├── domain/                   # Pure Kotlin: models, use cases, repository interfaces
│   ├── data/                     # Room DB, DAOs, repository impl, DataStore prefs
│   └── common/                   # Time formatting, color hex mapping
├── feature/
│   ├── medlist/                  # Medication list screen + ViewModel
│   ├── addedit/                  # Add/edit medication screen + ViewModel
│   ├── history/                  # History + heatmap screen + ViewModel
│   └── settings/                 # Settings screen + ViewModel
├── math/                         # Pure Kotlin: Hawkes, CircularStats, AdherenceEngine
└── build.gradle.kts
```

### Dependency Rules

- `feature/*` depends on `core/domain` and `core/common`
- `core/data` depends on `core/domain` (implements its interfaces)
- `math` depends on nothing (pure Kotlin, kotlin.math only)
- `app` depends on everything (wires DI graph)
- `core/domain` never imports Android framework classes

## Data Layer

### Room Entities

**MedicationEntity**
- `id: String` (UUID)
- `name: String`
- `dosage: String`
- `colorHex: String`
- `alertStyle: String` ("gentle", "urgent", "escalating")
- `isPRN: Boolean`
- `minIntervalMinutes: Int`
- `isActive: Boolean`
- `createdAt: Long` (epoch millis)

**ScheduleTimeEntity**
- `id: String` (UUID)
- `medicationId: String` (FK to MedicationEntity)
- `hour: Int`
- `minute: Int`

**DoseLogEntity**
- `id: String` (UUID)
- `medicationId: String` (FK to MedicationEntity)
- `scheduledTime: Long` (epoch millis)
- `actualTime: Long?` (nullable, epoch millis)
- `status: String` ("taken", "skipped", "snoozed")

### Domain Models

Plain Kotlin data classes with no Room annotations. Mappers in `core/data` convert between entity and domain representations.

```kotlin
data class Medication(
    val id: String,
    val name: String,
    val dosage: String,
    val colorHex: String,
    val alertStyle: String,
    val isPRN: Boolean,
    val minIntervalMinutes: Int,
    val isActive: Boolean,
    val createdAt: Instant,
    val scheduleTimes: List<ScheduleTime>,
    val doseLogs: List<DoseLog>
)

data class ScheduleTime(val hour: Int, val minute: Int)

data class DoseLog(
    val id: String,
    val scheduledTime: Instant,
    val actualTime: Instant?,
    val status: String
)
```

### Repository Interface (core/domain)

```kotlin
interface MedicationRepository {
    fun getAllMedications(): Flow<List<Medication>>
    fun getMedication(id: String): Flow<Medication?>
    suspend fun saveMedication(medication: Medication)
    suspend fun deleteMedication(id: String)
    suspend fun logDose(medicationId: String, scheduledTime: Instant, status: String)
    fun getDoseLogs(medicationId: String): Flow<List<DoseLog>>
}
```

Implementation in `core/data` uses Room DAOs. `Flow` provides reactive updates to Compose UI.

### Preferences

DataStore (not SharedPreferences) for user settings:
- `defaultSnoozeMinutes: Int` (default 10)
- `nagIntervalMinutes: Int` (default 5)
- `defaultAlertStyle: String` (default "gentle")

## Notification System

### Scheduled Reminders

`AlarmManager.setExactAndAllowWhileIdle()` fires a `BroadcastReceiver` at each scheduled time. The receiver builds and posts the notification via `NotificationManager`. Repeating daily alarms are scheduled for each medication's dose times.

### Notification Actions

Three action buttons per notification:
- **Taken** — logs dose as "taken", cancels nags, plays success haptic
- **Snooze** — logs dose as "snoozed", cancels nags, schedules one-shot alarm after snooze duration
- **Skip** — logs dose as "skipped", cancels nags

Each action fires a `PendingIntent` to `NotificationActionReceiver`. The receiver reads medication ID from the intent extras, logs the dose via repository, and cancels related nag alarms.

### Nag Mode

After primary notification fires, schedule up to 5 additional alarms at `nagIntervalMinutes` intervals. Each nag alarm posts a follow-up notification. All nags cancelled when any action (Taken/Snooze/Skip) is taken.

Nag alarm IDs follow pattern: `{baseId}-nag-{1..5}` for deterministic cancellation.

### Snooze

On snooze action: cancel nags, schedule one-shot alarm N minutes from now. Snooze alarm ID: `snooze-{medId}-{timestamp}`.

### Notification Channels

Three channels created in `Application.onCreate()`:

| Channel ID | Name | Priority | Vibration |
|------------|------|----------|-----------|
| `gentle` | Gentle Reminders | DEFAULT | Standard |
| `urgent` | Urgent Reminders | HIGH (heads-up) | Standard |
| `escalating` | Escalating Reminders | HIGH (heads-up) | Triple pulse: 100ms, 200ms, 400ms with 150ms gaps |

### Exact Alarm Permission

`USE_EXACT_ALARM` declared in manifest. This permission is appropriate for medical reminder apps and is auto-granted on API 33+. If revoked by user, fall back to `setAndAllowWhileIdle()` (inexact but still fires within ~10 minutes).

### Boot Persistence

`BootReceiver` registered for `RECEIVE_BOOT_COMPLETED`. On boot, queries all active medications from Room and reschedules all alarms. Android does not persist alarms across reboots.

## Math Module

Pure Kotlin, zero Android dependencies. Direct port of iOS math services.

### HawkesProcess.kt

- `HawkesParameters` data class: `mu`, `alpha`, `beta`
- `fit(missTimestamps: List<Instant>, windowStart: Instant, windowEnd: Instant)` — MLE via gradient ascent (Ozaki 1979), 30 iterations. Returns conservative defaults when fewer than 5 events.
- `intensity(at: Instant, parameters: HawkesParameters, recentMisses: List<Instant>)` — compute current intensity.
- `missProbability(at: Instant, parameters: HawkesParameters, recentMisses: List<Instant>)` — sigmoid mapping: `P = 1 / (1 + exp(-k*(lambda - lambda0)))` where k=5.0, lambda0=mu. Clamped to [0.01, 0.99].
- `riskLevel(missProbability: Double)` — low (<0.2), medium (0.2-0.5), high (>0.5).

### CircularStatistics.kt

- `timeToAngle(hour, minute)` — maps 24h time to [0, 2pi) radians.
- `angleToTime(theta)` — inverse mapping.
- `circularMean(angles: List<Double>)` — atan2-based mean direction.
- `meanResultantLength(angles: List<Double>)` — R-bar concentration measure.
- `vonMisesKappa(rBar: Double)` — Mardia-Jupp MLE approximation for concentration parameter.
- `suggestedTime(from: List<Instant>)` — circular mean mapped back to (hour, minute).
- `consistencyScore(from: List<Instant>)` — 0-100 integer from mean resultant length.

### AdherenceEngine.kt

- `MedicationInsight` data class: `medicationId`, `riskLevel`, `missProbability`, `consistencyScore`, `suggestedTime`, `currentScheduledTime`, `timeDriftMinutes`, `recommendedAlertStyle`.
- `whittleIndex(missProbability, importance, recentEscalationCount)` — `W = (importance * missProb) / (1 + 0.3 * escalationCount)`.
- `recommendedAlertStyle(whittleIndex)` — W<0.3 gentle, 0.3-0.6 urgent, >0.6 escalating.
- `analyze(medication, recentEscalationCount, now)` — orchestrates Hawkes fit + circular stats + Whittle. 90-day window. Zero-miss shortcut returns missProbability=0.05, risk=LOW.
- `analyzeAll(medications, now)` — analyze each active med, sort by descending miss probability.

### RiskLevel.kt

```kotlin
enum class RiskLevel { LOW, MEDIUM, HIGH }
```

## UI Layer (Compose)

### Navigation

`NavHost` with `BottomNavigation` providing 3 tabs:
- Meds (home) — `MedListScreen`
- History — `HistoryScreen`
- Settings — `SettingsScreen`

Add/Edit is a full-screen modal route (`composable` with slide-up transition).

### Theme

- Dark only. Material 3 `darkColorScheme()` with custom accent colors.
- `FontFamily.Monospace` as default body typography.
- No dynamic color (Material You theming disabled for consistency with iOS).

### MedListScreen

- `LazyColumn` of medication cards
- Each card: color dot, name, dosage, countdown text, risk indicator dot (green/yellow/red)
- `SwipeToDismiss` for delete (with `AlertDialog` confirmation, cancels notifications + nags)
- Long-press `DropdownMenu` with Edit/Delete
- `FloatingActionButton` for add
- `SnackbarHost` for dose confirmation toasts (auto-dismiss 2s)
- Single `LaunchedEffect` with 1-second tick passed to all cards

### AddEditScreen

- `LazyColumn` form layout
- `TextField` for name and dosage
- Color picker: `LazyVerticalGrid` of 44dp colored circles with selection ring
- Alert style: `SingleChoiceSegmentedButtonRow` (gentle/urgent/escalating)
- PRN toggle: `Switch` with conditional min interval `DropdownMenu`
- Schedule times: list of `TimePickerDialog` triggers with add/remove buttons
- Schedule suggestion row when drift >15min (from AdherenceEngine)
- Consistency score text

### HistoryScreen

- 8-week heatmap grid at top: 7 columns x 8 rows of colored dots (Canvas circles)
- Legend: taken (green), missed (red), snoozed (yellow), mixed (orange), none (gray)
- Below: dose logs grouped by day in `LazyColumn`

### SettingsScreen

- Snooze duration picker (5/10/15/30 min)
- Nag interval picker (3/5/10/15 min or off)
- Default alert style picker
- Notification permission status with button to open system settings
- App version from `BuildConfig`

### Haptics

`Vibrator` service with `VibrationEffect` patterns:
- Gentle: single short pulse (50ms)
- Warning: double pulse
- Escalating: triple heavy pulse with increasing amplitude
- Success: medium pulse

`HapticService` object maps alert style string to vibration pattern.

### Accessibility

- `contentDescription` on all icons, dots, and interactive elements
- `semantics { mergeDescendants() }` on medication cards
- Color dot descriptions ("Coral red", "Teal", etc.)
- Risk level announced ("low risk", "high risk")
- Touch targets minimum 48dp (Material guideline, slightly larger than iOS 44pt)

## Dependency Injection (Hilt)

### Modules

**DatabaseModule** (`@Singleton`)
- Provides `AppDatabase` (Room)
- Provides `MedicationDao`, `ScheduleTimeDao`, `DoseLogDao`

**RepositoryModule** (`@Singleton`)
- Binds `MedicationRepositoryImpl` to `MedicationRepository`

**NotificationModule** (`@Singleton`)
- Provides `NotificationScheduler`
- Provides `AlarmManager`

**DataStoreModule** (`@Singleton`)
- Provides preferences `DataStore<Preferences>`

### App Startup

1. `Application.onCreate()`: create notification channels
2. Hilt injects all dependencies
3. `BootReceiver` on `BOOT_COMPLETED`: reschedule all alarms
4. `NotificationActionReceiver`: handle Taken/Snooze/Skip

### Permissions

Requested at runtime:
- `POST_NOTIFICATIONS` (API 33+ required)
- `USE_EXACT_ALARM` (medical use case, auto-granted)

## Testing Strategy

- **math module**: plain JUnit tests. Port all 34 iOS math tests directly.
- **core/data**: Room in-memory database tests with `@RunWith(AndroidJUnit4::class)`
- **core/domain**: plain JUnit for use case logic
- **feature/***: ViewModel tests with fake repository, Turbine for Flow assertions
- **UI**: Compose UI tests with `createComposeRule()` for critical flows (add med, log dose)

## Build and Distribution

- Gradle with Kotlin DSL (`build.gradle.kts`)
- Version catalog (`libs.versions.toml`) for dependency management
- Debug and release build types
- Signed release APK for direct distribution
- No Play Store or GMS dependencies
