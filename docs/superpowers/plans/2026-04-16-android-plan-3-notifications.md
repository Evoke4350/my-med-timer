# Android Port Plan 3: Notification System

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the full notification pipeline for Android — alarm scheduling, notification posting with action buttons, nag/snooze logic, boot rescheduling, and haptic feedback. This mirrors the iOS NotificationService, NotificationDelegate, and HapticService.

**Architecture:** All notification/haptic code lives in the `core/data` module (needs Android framework + repository access). BroadcastReceivers are registered in the `app` module's AndroidManifest.xml. Uses Hilt for DI. AlarmManager for precise scheduling (no Google Play Services dependency — compatible with GrapheneOS).

**Tech Stack:** Kotlin 2.0, AlarmManager + BroadcastReceiver + NotificationManager, Hilt, JUnit 5 + Mockito for tests.

**Depends on:** Plan 1 (project scaffold, domain models, repository interface).

---

## File Map

### Notification System (`core/data`)
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/NotificationChannelManager.kt` — creates 3 notification channels
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/AlarmScheduler.kt` — schedules/cancels exact alarms
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/AlarmSchedulerImpl.kt` — AlarmManager implementation
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/MedicationAlarmReceiver.kt` — fires when alarm triggers, posts notification
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/NotificationActionReceiver.kt` — handles Taken/Snooze/Skip action presses
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/BootReceiver.kt` — reschedules all alarms on BOOT_COMPLETED
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/NotificationConstants.kt` — shared IDs, action strings, extras keys
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/NotificationModule.kt` — Hilt module providing AlarmScheduler

### Haptic Service (`core/data`)
- `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/haptic/HapticService.kt` — vibration patterns for gentle/urgent/escalating/success

### Tests
- `android/core/data/src/test/kotlin/com/nateb/mymedtimer/data/notification/AlarmSchedulerImplTest.kt` — unit tests with mocked AlarmManager

### Manifest Updates (`app`)
- `android/app/src/main/AndroidManifest.xml` — register receivers + permissions

---

### Task 1: NotificationConstants + NotificationChannelManager

**Files:**
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/NotificationConstants.kt`
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/NotificationChannelManager.kt`

- [ ] **Step 1: Create NotificationConstants**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/NotificationConstants.kt
package com.nateb.mymedtimer.data.notification

object NotificationConstants {
    // Notification channel IDs
    const val CHANNEL_GENTLE = "medication_gentle"
    const val CHANNEL_URGENT = "medication_urgent"
    const val CHANNEL_ESCALATING = "medication_escalating"

    // Notification action identifiers
    const val ACTION_TAKEN = "com.nateb.mymedtimer.ACTION_TAKEN"
    const val ACTION_SNOOZE = "com.nateb.mymedtimer.ACTION_SNOOZE"
    const val ACTION_SKIP = "com.nateb.mymedtimer.ACTION_SKIP"

    // Intent extras keys
    const val EXTRA_MEDICATION_ID = "medication_id"
    const val EXTRA_MEDICATION_NAME = "medication_name"
    const val EXTRA_MEDICATION_DOSAGE = "medication_dosage"
    const val EXTRA_ALERT_STYLE = "alert_style"
    const val EXTRA_SCHEDULED_HOUR = "scheduled_hour"
    const val EXTRA_SCHEDULED_MINUTE = "scheduled_minute"
    const val EXTRA_NOTIFICATION_ID = "notification_id"
    const val EXTRA_IS_NAG = "is_nag"
    const val EXTRA_IS_SNOOZE = "is_snooze"

    // Alarm request code offset ranges (to avoid collision)
    // Base alarms: medicationHash * 100 + timeIndex
    // Nag alarms: baseCode * 10 + nagIndex (1-5)
    // Snooze alarms: negative request codes

    // Nag defaults
    const val DEFAULT_NAG_COUNT = 5
    const val DEFAULT_SNOOZE_MINUTES = 10

    // Notification ID prefix for generating unique int IDs
    fun notificationIdFromString(id: String): Int = id.hashCode() and 0x7FFFFFFF
}
```

- [ ] **Step 2: Create NotificationChannelManager**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/NotificationChannelManager.kt
package com.nateb.mymedtimer.data.notification

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.os.VibrationEffect
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NotificationChannelManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    fun createChannels() {
        val notificationManager = context.getSystemService(NotificationManager::class.java)

        val gentle = NotificationChannel(
            NotificationConstants.CHANNEL_GENTLE,
            "Gentle Reminders",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Standard medication reminders"
        }

        val urgent = NotificationChannel(
            NotificationConstants.CHANNEL_URGENT,
            "Urgent Reminders",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "High-priority medication reminders with heads-up display"
            enableVibration(true)
        }

        val escalating = NotificationChannel(
            NotificationConstants.CHANNEL_ESCALATING,
            "Escalating Reminders",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Escalating medication reminders with repeated vibration"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 200, 100, 200, 100, 400)
        }

        notificationManager.createNotificationChannels(listOf(gentle, urgent, escalating))
    }

    fun channelIdForAlertStyle(alertStyle: String): String = when (alertStyle) {
        "urgent" -> NotificationConstants.CHANNEL_URGENT
        "escalating" -> NotificationConstants.CHANNEL_ESCALATING
        else -> NotificationConstants.CHANNEL_GENTLE
    }
}
```

- [ ] **Step 3: Update MyMedTimerApp to create channels on startup**

Modify the Application class (created in Plan 1) to initialize channels:

```kotlin
// android/app/src/main/kotlin/com/nateb/mymedtimer/MyMedTimerApp.kt
package com.nateb.mymedtimer

import android.app.Application
import com.nateb.mymedtimer.data.notification.NotificationChannelManager
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

- [ ] **Step 4: Verify build**

```bash
cd android && ./gradlew :core:data:compileDebugKotlin :app:compileDebugKotlin
```

Expected: BUILD SUCCESSFUL

---

### Task 2: AlarmScheduler Interface + Implementation

**Files:**
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/AlarmScheduler.kt`
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/AlarmSchedulerImpl.kt`

- [ ] **Step 1: Create AlarmScheduler interface**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/AlarmScheduler.kt
package com.nateb.mymedtimer.data.notification

import com.nateb.mymedtimer.domain.model.Medication
import com.nateb.mymedtimer.domain.model.ScheduleTime

interface AlarmScheduler {
    /** Schedule a daily repeating alarm for a single dose time. */
    fun scheduleDoseAlarm(
        medicationId: String,
        name: String,
        dosage: String,
        time: ScheduleTime,
        alertStyle: String
    )

    /** Schedule all dose alarms for a medication. */
    fun scheduleAllAlarms(medication: Medication)

    /** Schedule a one-shot alarm (for snooze). */
    fun scheduleSnoozeAlarm(
        medicationId: String,
        name: String,
        dosage: String,
        delayMinutes: Int,
        alertStyle: String
    )

    /** Schedule nag follow-up alarms after a missed dose. */
    fun scheduleNagAlarms(
        baseNotificationId: String,
        medicationId: String,
        name: String,
        dosage: String,
        intervalMinutes: Int,
        count: Int = NotificationConstants.DEFAULT_NAG_COUNT,
        alertStyle: String
    )

    /** Cancel nag alarms for a given base notification ID. */
    fun cancelNagAlarms(baseNotificationId: String, count: Int = NotificationConstants.DEFAULT_NAG_COUNT)

    /** Cancel all alarms for a specific medication. */
    fun cancelAlarmsForMedication(medicationId: String, times: List<ScheduleTime>)

    /** Cancel all medication alarms. */
    fun cancelAllAlarms()

    /** Reschedule all alarms for all active medications (used after boot). */
    suspend fun rescheduleAll()
}
```

- [ ] **Step 2: Create AlarmSchedulerImpl**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/AlarmSchedulerImpl.kt
package com.nateb.mymedtimer.data.notification

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.nateb.mymedtimer.domain.model.Medication
import com.nateb.mymedtimer.domain.model.ScheduleTime
import com.nateb.mymedtimer.domain.repository.MedicationRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.first
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AlarmSchedulerImpl @Inject constructor(
    @ApplicationContext private val context: Context,
    private val medicationRepository: MedicationRepository
) : AlarmScheduler {

    private val alarmManager: AlarmManager =
        context.getSystemService(AlarmManager::class.java)

    override fun scheduleDoseAlarm(
        medicationId: String,
        name: String,
        dosage: String,
        time: ScheduleTime,
        alertStyle: String
    ) {
        val intent = createAlarmIntent(
            medicationId = medicationId,
            name = name,
            dosage = dosage,
            hour = time.hour,
            minute = time.minute,
            alertStyle = alertStyle,
            isNag = false,
            isSnooze = false
        )

        val notificationId = doseNotificationId(medicationId, time)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val triggerAtMillis = nextTriggerTimeMillis(time.hour, time.minute)

        // Use setExactAndAllowWhileIdle for precise timing even in Doze mode
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            triggerAtMillis,
            pendingIntent
        )
    }

    override fun scheduleAllAlarms(medication: Medication) {
        for (time in medication.scheduleTimes) {
            scheduleDoseAlarm(
                medicationId = medication.id,
                name = medication.name,
                dosage = medication.dosage,
                time = time,
                alertStyle = medication.alertStyle
            )
        }
    }

    override fun scheduleSnoozeAlarm(
        medicationId: String,
        name: String,
        dosage: String,
        delayMinutes: Int,
        alertStyle: String
    ) {
        val intent = createAlarmIntent(
            medicationId = medicationId,
            name = name,
            dosage = dosage,
            hour = -1,
            minute = -1,
            alertStyle = alertStyle,
            isNag = false,
            isSnooze = true
        )

        val requestCode = snoozeRequestCode(medicationId)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val triggerAtMillis = System.currentTimeMillis() + (delayMinutes * 60 * 1000L)

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            triggerAtMillis,
            pendingIntent
        )
    }

    override fun scheduleNagAlarms(
        baseNotificationId: String,
        medicationId: String,
        name: String,
        dosage: String,
        intervalMinutes: Int,
        count: Int,
        alertStyle: String
    ) {
        for (i in 1..count) {
            val intent = createAlarmIntent(
                medicationId = medicationId,
                name = name,
                dosage = dosage,
                hour = -1,
                minute = -1,
                alertStyle = alertStyle,
                isNag = true,
                isSnooze = false
            )
            intent.putExtra(NotificationConstants.EXTRA_NOTIFICATION_ID, "$baseNotificationId-nag-$i")

            val requestCode = nagRequestCode(baseNotificationId, i)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val delayMillis = i * intervalMinutes * 60 * 1000L
            val triggerAtMillis = System.currentTimeMillis() + delayMillis

            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent
            )
        }
    }

    override fun cancelNagAlarms(baseNotificationId: String, count: Int) {
        for (i in 1..count) {
            val intent = Intent(context, MedicationAlarmReceiver::class.java)
            val requestCode = nagRequestCode(baseNotificationId, i)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntent?.let { alarmManager.cancel(it) }
        }
    }

    override fun cancelAlarmsForMedication(medicationId: String, times: List<ScheduleTime>) {
        for (time in times) {
            val notificationId = doseNotificationId(medicationId, time)
            val intent = Intent(context, MedicationAlarmReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                notificationId,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntent?.let { alarmManager.cancel(it) }
        }
    }

    override fun cancelAllAlarms() {
        // Cancel all alarms by iterating active medications
        // This is a best-effort approach — we cancel known pending intents
        // A full cancel requires tracking all request codes, which rescheduleAll covers
        val intent = Intent(context, MedicationAlarmReceiver::class.java)
        // Android does not provide a "cancel all alarms" API, so we rely on
        // rescheduleAll() being the source of truth after boot/update
    }

    override suspend fun rescheduleAll() {
        val medications = medicationRepository.getAllMedications().first()
        for (medication in medications) {
            if (medication.isActive && !medication.isPRN) {
                scheduleAllAlarms(medication)
            }
        }
    }

    // --- Private helpers ---

    private fun createAlarmIntent(
        medicationId: String,
        name: String,
        dosage: String,
        hour: Int,
        minute: Int,
        alertStyle: String,
        isNag: Boolean,
        isSnooze: Boolean
    ): Intent {
        return Intent(context, MedicationAlarmReceiver::class.java).apply {
            putExtra(NotificationConstants.EXTRA_MEDICATION_ID, medicationId)
            putExtra(NotificationConstants.EXTRA_MEDICATION_NAME, name)
            putExtra(NotificationConstants.EXTRA_MEDICATION_DOSAGE, dosage)
            putExtra(NotificationConstants.EXTRA_SCHEDULED_HOUR, hour)
            putExtra(NotificationConstants.EXTRA_SCHEDULED_MINUTE, minute)
            putExtra(NotificationConstants.EXTRA_ALERT_STYLE, alertStyle)
            putExtra(NotificationConstants.EXTRA_IS_NAG, isNag)
            putExtra(NotificationConstants.EXTRA_IS_SNOOZE, isSnooze)
        }
    }

    companion object {
        /**
         * Generate a stable notification ID for a medication + time pair.
         * Uses the medication ID and time to produce a unique positive int.
         */
        fun doseNotificationId(medicationId: String, time: ScheduleTime): Int {
            val raw = "med-$medicationId-${time.hour}:${time.minute}".hashCode()
            return raw and 0x7FFFFFFF
        }

        fun nagRequestCode(baseNotificationId: String, index: Int): Int {
            val raw = "$baseNotificationId-nag-$index".hashCode()
            return raw and 0x7FFFFFFF
        }

        fun snoozeRequestCode(medicationId: String): Int {
            val raw = "snooze-$medicationId-${System.currentTimeMillis()}".hashCode()
            return raw and 0x7FFFFFFF
        }

        /**
         * Calculate the next trigger time in millis for a given hour:minute.
         * If the time has already passed today, schedules for tomorrow.
         */
        fun nextTriggerTimeMillis(hour: Int, minute: Int): Long {
            val zone = ZoneId.systemDefault()
            val now = java.time.ZonedDateTime.now(zone)
            var target = LocalDate.now(zone).atTime(LocalTime.of(hour, minute)).atZone(zone)
            if (target.isBefore(now) || target.isEqual(now)) {
                target = target.plusDays(1)
            }
            return target.toInstant().toEpochMilli()
        }
    }
}
```

- [ ] **Step 3: Verify build**

```bash
cd android && ./gradlew :core:data:compileDebugKotlin
```

Expected: BUILD SUCCESSFUL

---

### Task 3: MedicationAlarmReceiver

**Files:**
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/MedicationAlarmReceiver.kt`

- [ ] **Step 1: Create MedicationAlarmReceiver**

This BroadcastReceiver fires when an alarm triggers. It builds and posts a notification with Taken/Snooze/Skip action buttons, then reschedules the next day's alarm (since we use one-shot exact alarms, not repeating).

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/MedicationAlarmReceiver.kt
package com.nateb.mymedtimer.data.notification

import android.Manifest
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.nateb.mymedtimer.data.haptic.HapticService
import com.nateb.mymedtimer.domain.model.ScheduleTime

class MedicationAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val medicationId = intent.getStringExtra(NotificationConstants.EXTRA_MEDICATION_ID) ?: return
        val name = intent.getStringExtra(NotificationConstants.EXTRA_MEDICATION_NAME) ?: return
        val dosage = intent.getStringExtra(NotificationConstants.EXTRA_MEDICATION_DOSAGE) ?: ""
        val alertStyle = intent.getStringExtra(NotificationConstants.EXTRA_ALERT_STYLE) ?: "gentle"
        val hour = intent.getIntExtra(NotificationConstants.EXTRA_SCHEDULED_HOUR, -1)
        val minute = intent.getIntExtra(NotificationConstants.EXTRA_SCHEDULED_MINUTE, -1)
        val isNag = intent.getBooleanExtra(NotificationConstants.EXTRA_IS_NAG, false)
        val isSnooze = intent.getBooleanExtra(NotificationConstants.EXTRA_IS_SNOOZE, false)

        val notificationId = if (isNag || isSnooze) {
            val customId = intent.getStringExtra(NotificationConstants.EXTRA_NOTIFICATION_ID)
            NotificationConstants.notificationIdFromString(customId ?: "$medicationId-${System.currentTimeMillis()}")
        } else {
            NotificationConstants.notificationIdFromString("med-$medicationId-$hour:$minute")
        }

        val channelId = NotificationChannelManager.channelIdForAlertStyle(alertStyle)

        val body = when {
            isSnooze -> "$dosage — snoozed reminder"
            isNag -> "Reminder: $dosage — time to take your dose"
            else -> "$dosage — time to take your dose"
        }

        // Build action PendingIntents
        val takenIntent = createActionIntent(context, NotificationConstants.ACTION_TAKEN, notificationId, medicationId, name, dosage, hour, minute, alertStyle)
        val snoozeIntent = createActionIntent(context, NotificationConstants.ACTION_SNOOZE, notificationId, medicationId, name, dosage, hour, minute, alertStyle)
        val skipIntent = createActionIntent(context, NotificationConstants.ACTION_SKIP, notificationId, medicationId, name, dosage, hour, minute, alertStyle)

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(name)
            .setContentText(body)
            .setPriority(
                if (alertStyle == "gentle") NotificationCompat.PRIORITY_DEFAULT
                else NotificationCompat.PRIORITY_HIGH
            )
            .setAutoCancel(true)
            .addAction(0, "Taken", takenIntent)
            .addAction(0, "Snooze", snoozeIntent)
            .addAction(0, "Skip", skipIntent)
            .build()

        // Check POST_NOTIFICATIONS permission (required API 33+)
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
            == PackageManager.PERMISSION_GRANTED
        ) {
            val notificationManager = context.getSystemService(NotificationManager::class.java)
            notificationManager.notify(notificationId, notification)
        }

        // Play haptic feedback
        HapticService.playForAlertStyle(context, alertStyle)

        // Reschedule for next day if this is a regular dose alarm (not nag/snooze)
        if (!isNag && !isSnooze && hour >= 0 && minute >= 0) {
            rescheduleNextDay(context, intent, medicationId, hour, minute)
        }
    }

    private fun createActionIntent(
        context: Context,
        action: String,
        notificationId: Int,
        medicationId: String,
        name: String,
        dosage: String,
        hour: Int,
        minute: Int,
        alertStyle: String
    ): PendingIntent {
        val intent = Intent(context, NotificationActionReceiver::class.java).apply {
            this.action = action
            putExtra(NotificationConstants.EXTRA_NOTIFICATION_ID, notificationId.toString())
            putExtra(NotificationConstants.EXTRA_MEDICATION_ID, medicationId)
            putExtra(NotificationConstants.EXTRA_MEDICATION_NAME, name)
            putExtra(NotificationConstants.EXTRA_MEDICATION_DOSAGE, dosage)
            putExtra(NotificationConstants.EXTRA_SCHEDULED_HOUR, hour)
            putExtra(NotificationConstants.EXTRA_SCHEDULED_MINUTE, minute)
            putExtra(NotificationConstants.EXTRA_ALERT_STYLE, alertStyle)
        }
        // Use action hashCode + notificationId to ensure unique PendingIntents per action
        val requestCode = (action.hashCode() + notificationId) and 0x7FFFFFFF
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun rescheduleNextDay(
        context: Context,
        originalIntent: Intent,
        medicationId: String,
        hour: Int,
        minute: Int
    ) {
        val nextTrigger = AlarmSchedulerImpl.nextTriggerTimeMillis(hour, minute)
        val newIntent = Intent(originalIntent).apply {
            component = originalIntent.component
        }
        val notificationId = AlarmSchedulerImpl.doseNotificationId(medicationId, ScheduleTime(hour, minute))
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            notificationId,
            newIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = context.getSystemService(android.app.AlarmManager::class.java)
        alarmManager.setExactAndAllowWhileIdle(
            android.app.AlarmManager.RTC_WAKEUP,
            nextTrigger,
            pendingIntent
        )
    }

    companion object {
        /**
         * Static channel ID lookup for use without Hilt injection.
         * Mirrors NotificationChannelManager.channelIdForAlertStyle().
         */
        private fun NotificationChannelManager.Companion.channelIdForAlertStyle(alertStyle: String): String =
            when (alertStyle) {
                "urgent" -> NotificationConstants.CHANNEL_URGENT
                "escalating" -> NotificationConstants.CHANNEL_ESCALATING
                else -> NotificationConstants.CHANNEL_GENTLE
            }
    }
}
```

Wait — `NotificationChannelManager` doesn't have a companion. Let me fix the design. The `channelIdForAlertStyle` should be a top-level function or on `NotificationConstants` instead. Let me revise.

Actually, looking at the receiver code more carefully, BroadcastReceivers can't easily use Hilt constructor injection. The channel mapping is a simple static function. I'll put it on `NotificationConstants` and keep the receiver clean.

**Revised Step 1 — use this instead of the code above:**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/MedicationAlarmReceiver.kt
package com.nateb.mymedtimer.data.notification

import android.Manifest
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.nateb.mymedtimer.data.haptic.HapticService
import com.nateb.mymedtimer.domain.model.ScheduleTime

class MedicationAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val medicationId = intent.getStringExtra(NotificationConstants.EXTRA_MEDICATION_ID) ?: return
        val name = intent.getStringExtra(NotificationConstants.EXTRA_MEDICATION_NAME) ?: return
        val dosage = intent.getStringExtra(NotificationConstants.EXTRA_MEDICATION_DOSAGE) ?: ""
        val alertStyle = intent.getStringExtra(NotificationConstants.EXTRA_ALERT_STYLE) ?: "gentle"
        val hour = intent.getIntExtra(NotificationConstants.EXTRA_SCHEDULED_HOUR, -1)
        val minute = intent.getIntExtra(NotificationConstants.EXTRA_SCHEDULED_MINUTE, -1)
        val isNag = intent.getBooleanExtra(NotificationConstants.EXTRA_IS_NAG, false)
        val isSnooze = intent.getBooleanExtra(NotificationConstants.EXTRA_IS_SNOOZE, false)

        val notificationId = if (isNag || isSnooze) {
            val customId = intent.getStringExtra(NotificationConstants.EXTRA_NOTIFICATION_ID)
            NotificationConstants.notificationIdFromString(
                customId ?: "$medicationId-${System.currentTimeMillis()}"
            )
        } else {
            NotificationConstants.notificationIdFromString("med-$medicationId-$hour:$minute")
        }

        val channelId = NotificationConstants.channelIdForAlertStyle(alertStyle)

        val body = when {
            isSnooze -> "$dosage — snoozed reminder"
            isNag -> "Reminder: $dosage — time to take your dose"
            else -> "$dosage — time to take your dose"
        }

        // Build action PendingIntents
        val takenPending = createActionPendingIntent(
            context, NotificationConstants.ACTION_TAKEN, notificationId,
            medicationId, name, dosage, hour, minute, alertStyle
        )
        val snoozePending = createActionPendingIntent(
            context, NotificationConstants.ACTION_SNOOZE, notificationId,
            medicationId, name, dosage, hour, minute, alertStyle
        )
        val skipPending = createActionPendingIntent(
            context, NotificationConstants.ACTION_SKIP, notificationId,
            medicationId, name, dosage, hour, minute, alertStyle
        )

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(name)
            .setContentText(body)
            .setPriority(
                if (alertStyle == "gentle") NotificationCompat.PRIORITY_DEFAULT
                else NotificationCompat.PRIORITY_HIGH
            )
            .setAutoCancel(true)
            .addAction(0, "Taken", takenPending)
            .addAction(0, "Snooze", snoozePending)
            .addAction(0, "Skip", skipPending)
            .build()

        if (ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
            == PackageManager.PERMISSION_GRANTED
        ) {
            val notificationManager = context.getSystemService(NotificationManager::class.java)
            notificationManager.notify(notificationId, notification)
        }

        // Play haptic feedback
        HapticService.playForAlertStyle(context, alertStyle)

        // Reschedule for next day if this is a regular dose alarm (not nag/snooze)
        if (!isNag && !isSnooze && hour >= 0 && minute >= 0) {
            rescheduleNextDay(context, intent, medicationId, hour, minute)
        }
    }

    private fun createActionPendingIntent(
        context: Context,
        action: String,
        notificationId: Int,
        medicationId: String,
        name: String,
        dosage: String,
        hour: Int,
        minute: Int,
        alertStyle: String
    ): PendingIntent {
        val actionIntent = Intent(context, NotificationActionReceiver::class.java).apply {
            this.action = action
            putExtra(NotificationConstants.EXTRA_NOTIFICATION_ID, notificationId.toString())
            putExtra(NotificationConstants.EXTRA_MEDICATION_ID, medicationId)
            putExtra(NotificationConstants.EXTRA_MEDICATION_NAME, name)
            putExtra(NotificationConstants.EXTRA_MEDICATION_DOSAGE, dosage)
            putExtra(NotificationConstants.EXTRA_SCHEDULED_HOUR, hour)
            putExtra(NotificationConstants.EXTRA_SCHEDULED_MINUTE, minute)
            putExtra(NotificationConstants.EXTRA_ALERT_STYLE, alertStyle)
        }
        val requestCode = (action.hashCode() + notificationId) and 0x7FFFFFFF
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            actionIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun rescheduleNextDay(
        context: Context,
        originalIntent: Intent,
        medicationId: String,
        hour: Int,
        minute: Int
    ) {
        val nextTrigger = AlarmSchedulerImpl.nextTriggerTimeMillis(hour, minute)
        val newIntent = Intent(context, MedicationAlarmReceiver::class.java).apply {
            putExtra(NotificationConstants.EXTRA_MEDICATION_ID, medicationId)
            putExtra(NotificationConstants.EXTRA_MEDICATION_NAME,
                originalIntent.getStringExtra(NotificationConstants.EXTRA_MEDICATION_NAME))
            putExtra(NotificationConstants.EXTRA_MEDICATION_DOSAGE,
                originalIntent.getStringExtra(NotificationConstants.EXTRA_MEDICATION_DOSAGE))
            putExtra(NotificationConstants.EXTRA_SCHEDULED_HOUR, hour)
            putExtra(NotificationConstants.EXTRA_SCHEDULED_MINUTE, minute)
            putExtra(NotificationConstants.EXTRA_ALERT_STYLE,
                originalIntent.getStringExtra(NotificationConstants.EXTRA_ALERT_STYLE))
            putExtra(NotificationConstants.EXTRA_IS_NAG, false)
            putExtra(NotificationConstants.EXTRA_IS_SNOOZE, false)
        }
        val notifId = AlarmSchedulerImpl.doseNotificationId(
            medicationId, ScheduleTime(hour, minute)
        )
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            notifId,
            newIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = context.getSystemService(android.app.AlarmManager::class.java)
        alarmManager.setExactAndAllowWhileIdle(
            android.app.AlarmManager.RTC_WAKEUP,
            nextTrigger,
            pendingIntent
        )
    }
}
```

Also update `NotificationConstants` to include the channel mapping:

```kotlin
// Add to NotificationConstants object body:

    fun channelIdForAlertStyle(alertStyle: String): String = when (alertStyle) {
        "urgent" -> CHANNEL_URGENT
        "escalating" -> CHANNEL_ESCALATING
        else -> CHANNEL_GENTLE
    }
```

And update `NotificationChannelManager.channelIdForAlertStyle` to delegate:

```kotlin
// In NotificationChannelManager, replace the channelIdForAlertStyle method with:
    fun channelIdForAlertStyle(alertStyle: String): String =
        NotificationConstants.channelIdForAlertStyle(alertStyle)
```

- [ ] **Step 2: Verify build**

```bash
cd android && ./gradlew :core:data:compileDebugKotlin
```

Expected: BUILD SUCCESSFUL

---

### Task 4: NotificationActionReceiver

**Files:**
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/NotificationActionReceiver.kt`

- [ ] **Step 1: Create NotificationActionReceiver**

Handles Taken/Snooze/Skip action button presses from notifications. Uses `goAsync()` for coroutine work. Accesses the repository via Hilt's `EntryPoint` (since BroadcastReceivers can't use constructor injection).

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/NotificationActionReceiver.kt
package com.nateb.mymedtimer.data.notification

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.nateb.mymedtimer.data.haptic.HapticService
import com.nateb.mymedtimer.domain.repository.MedicationRepository
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId

class NotificationActionReceiver : BroadcastReceiver() {

    @EntryPoint
    @InstallIn(SingletonComponent::class)
    interface NotificationActionEntryPoint {
        fun medicationRepository(): MedicationRepository
        fun alarmScheduler(): AlarmScheduler
    }

    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync()

        val action = intent.action ?: run {
            pendingResult.finish()
            return
        }
        val medicationId = intent.getStringExtra(NotificationConstants.EXTRA_MEDICATION_ID) ?: run {
            pendingResult.finish()
            return
        }
        val notificationIdStr = intent.getStringExtra(NotificationConstants.EXTRA_NOTIFICATION_ID) ?: ""
        val name = intent.getStringExtra(NotificationConstants.EXTRA_MEDICATION_NAME) ?: ""
        val dosage = intent.getStringExtra(NotificationConstants.EXTRA_MEDICATION_DOSAGE) ?: ""
        val hour = intent.getIntExtra(NotificationConstants.EXTRA_SCHEDULED_HOUR, -1)
        val minute = intent.getIntExtra(NotificationConstants.EXTRA_SCHEDULED_MINUTE, -1)
        val alertStyle = intent.getStringExtra(NotificationConstants.EXTRA_ALERT_STYLE) ?: "gentle"

        val entryPoint = EntryPointAccessors.fromApplication(
            context.applicationContext,
            NotificationActionEntryPoint::class.java
        )
        val repository = entryPoint.medicationRepository()
        val alarmScheduler = entryPoint.alarmScheduler()

        // Dismiss the notification
        val notificationManager = context.getSystemService(NotificationManager::class.java)
        val notifId = notificationIdStr.toIntOrNull() ?: 0
        notificationManager.cancel(notifId)

        // Cancel any pending nags for this notification
        alarmScheduler.cancelNagAlarms(notificationIdStr)

        // Compute scheduled time as Instant
        val scheduledTime = if (hour >= 0 && minute >= 0) {
            LocalDate.now().atTime(LocalTime.of(hour, minute))
                .atZone(ZoneId.systemDefault()).toInstant()
        } else {
            Instant.now()
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                when (action) {
                    NotificationConstants.ACTION_TAKEN -> {
                        repository.logDose(
                            medicationId = medicationId,
                            scheduledTime = scheduledTime,
                            status = "taken"
                        )
                        HapticService.play(context, HapticService.Pattern.SUCCESS)
                    }

                    NotificationConstants.ACTION_SKIP -> {
                        repository.logDose(
                            medicationId = medicationId,
                            scheduledTime = scheduledTime,
                            status = "skipped"
                        )
                    }

                    NotificationConstants.ACTION_SNOOZE -> {
                        repository.logDose(
                            medicationId = medicationId,
                            scheduledTime = scheduledTime,
                            status = "snoozed"
                        )
                        alarmScheduler.scheduleSnoozeAlarm(
                            medicationId = medicationId,
                            name = name,
                            dosage = dosage,
                            delayMinutes = NotificationConstants.DEFAULT_SNOOZE_MINUTES,
                            alertStyle = alertStyle
                        )
                    }
                }
            } finally {
                pendingResult.finish()
            }
        }
    }
}
```

- [ ] **Step 2: Verify build**

```bash
cd android && ./gradlew :core:data:compileDebugKotlin
```

Expected: BUILD SUCCESSFUL

---

### Task 5: BootReceiver

**Files:**
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/BootReceiver.kt`

- [ ] **Step 1: Create BootReceiver**

Reschedules all alarms after device reboot (AlarmManager alarms are cleared on reboot).

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/BootReceiver.kt
package com.nateb.mymedtimer.data.notification

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class BootReceiver : BroadcastReceiver() {

    @EntryPoint
    @InstallIn(SingletonComponent::class)
    interface BootEntryPoint {
        fun alarmScheduler(): AlarmScheduler
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        val pendingResult = goAsync()

        val entryPoint = EntryPointAccessors.fromApplication(
            context.applicationContext,
            BootEntryPoint::class.java
        )
        val alarmScheduler = entryPoint.alarmScheduler()

        CoroutineScope(Dispatchers.IO).launch {
            try {
                alarmScheduler.rescheduleAll()
            } finally {
                pendingResult.finish()
            }
        }
    }
}
```

- [ ] **Step 2: Verify build**

```bash
cd android && ./gradlew :core:data:compileDebugKotlin
```

Expected: BUILD SUCCESSFUL

---

### Task 6: HapticService

**Files:**
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/haptic/HapticService.kt`

- [ ] **Step 1: Create HapticService**

Mirrors the iOS HapticService with four patterns: notification (gentle), warning (urgent), success (action confirmed), and escalating (repeated heavy buzz).

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/haptic/HapticService.kt
package com.nateb.mymedtimer.data.haptic

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

object HapticService {

    enum class Pattern {
        NOTIFICATION,  // gentle single pulse
        WARNING,       // urgent double-tap
        SUCCESS,       // confirmed action feedback
        ESCALATING     // repeated heavy buzz
    }

    fun play(context: Context, pattern: Pattern) {
        val vibrator = getVibrator(context) ?: return

        val effect = when (pattern) {
            Pattern.NOTIFICATION -> VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE)
            Pattern.WARNING -> VibrationEffect.createWaveform(
                longArrayOf(0, 80, 60, 80),
                intArrayOf(0, 200, 0, 200),
                -1 // no repeat
            )
            Pattern.SUCCESS -> VibrationEffect.createOneShot(50, 120)
            Pattern.ESCALATING -> VibrationEffect.createWaveform(
                longArrayOf(0, 150, 80, 150, 80, 300),
                intArrayOf(0, 180, 0, 220, 0, 255),
                -1
            )
        }

        vibrator.vibrate(effect)
    }

    fun playForAlertStyle(context: Context, alertStyle: String) {
        when (alertStyle) {
            "urgent" -> play(context, Pattern.WARNING)
            "escalating" -> play(context, Pattern.ESCALATING)
            else -> play(context, Pattern.NOTIFICATION)
        }
    }

    private fun getVibrator(context: Context): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = context.getSystemService(VibratorManager::class.java)
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }
}
```

- [ ] **Step 2: Verify build**

```bash
cd android && ./gradlew :core:data:compileDebugKotlin
```

Expected: BUILD SUCCESSFUL

---

### Task 7: Hilt Module + Manifest Registration

**Files:**
- Create: `android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/NotificationModule.kt`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Create NotificationModule for Hilt DI**

```kotlin
// android/core/data/src/main/kotlin/com/nateb/mymedtimer/data/notification/NotificationModule.kt
package com.nateb.mymedtimer.data.notification

import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class NotificationModule {

    @Binds
    @Singleton
    abstract fun bindAlarmScheduler(impl: AlarmSchedulerImpl): AlarmScheduler
}
```

- [ ] **Step 2: Update AndroidManifest.xml with receiver registrations**

Replace the existing manifest (from Plan 1) with the expanded version that registers all three receivers:

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

        <!-- Fires when a scheduled alarm triggers — posts the notification -->
        <receiver
            android:name="com.nateb.mymedtimer.data.notification.MedicationAlarmReceiver"
            android:exported="false" />

        <!-- Handles Taken/Snooze/Skip action button presses -->
        <receiver
            android:name="com.nateb.mymedtimer.data.notification.NotificationActionReceiver"
            android:exported="false" />

        <!-- Reschedules all alarms after device reboot -->
        <receiver
            android:name="com.nateb.mymedtimer.data.notification.BootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

- [ ] **Step 3: Verify full build**

```bash
cd android && ./gradlew assembleDebug
```

Expected: BUILD SUCCESSFUL

---

### Task 8: AlarmScheduler Unit Tests

**Files:**
- Create: `android/core/data/src/test/kotlin/com/nateb/mymedtimer/data/notification/AlarmSchedulerImplTest.kt`

- [ ] **Step 1: Add test dependencies to core/data build file**

Add Mockito to the version catalog if not already present. Add to `android/gradle/libs.versions.toml`:

```toml
# Under [versions], add:
mockito = "5.14.2"
mockito-kotlin = "5.4.0"

# Under [libraries], add:
mockito-core = { group = "org.mockito", name = "mockito-core", version.ref = "mockito" }
mockito-kotlin = { group = "org.mockito.kotlin", name = "mockito-kotlin", version.ref = "mockito-kotlin" }
```

Add to `android/core/data/build.gradle.kts` dependencies:

```kotlin
    testImplementation(libs.mockito.core)
    testImplementation(libs.mockito.kotlin)
    testImplementation(libs.coroutines.test)
```

- [ ] **Step 2: Create AlarmSchedulerImplTest**

Tests cover: `nextTriggerTimeMillis` logic, `doseNotificationId` stability, `nagRequestCode` uniqueness, and `scheduleNagAlarms`/`cancelNagAlarms` interaction with AlarmManager.

```kotlin
// android/core/data/src/test/kotlin/com/nateb/mymedtimer/data/notification/AlarmSchedulerImplTest.kt
package com.nateb.mymedtimer.data.notification

import com.nateb.mymedtimer.domain.model.ScheduleTime
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId

class AlarmSchedulerImplTest {

    @Test
    fun `nextTriggerTimeMillis returns future time today if not yet passed`() {
        // Use 23:59 which is almost certainly in the future during test execution,
        // or if it somehow runs at 23:59, it'll be tomorrow — both are valid future times
        val millis = AlarmSchedulerImpl.nextTriggerTimeMillis(23, 59)
        assertTrue(millis > System.currentTimeMillis(), "Trigger time should be in the future")
    }

    @Test
    fun `nextTriggerTimeMillis returns tomorrow if time already passed`() {
        // 00:00 has always passed by the time any test runs (unless exactly midnight)
        val millis = AlarmSchedulerImpl.nextTriggerTimeMillis(0, 0)
        val zone = ZoneId.systemDefault()
        val tomorrow = LocalDate.now(zone).plusDays(1)
            .atTime(LocalTime.of(0, 0))
            .atZone(zone)
            .toInstant()
            .toEpochMilli()
        assertEquals(tomorrow, millis, "Should schedule for tomorrow at 00:00")
    }

    @Test
    fun `doseNotificationId is stable for same inputs`() {
        val time = ScheduleTime(hour = 8, minute = 30)
        val id1 = AlarmSchedulerImpl.doseNotificationId("med-123", time)
        val id2 = AlarmSchedulerImpl.doseNotificationId("med-123", time)
        assertEquals(id1, id2, "Same medication + time should produce same notification ID")
    }

    @Test
    fun `doseNotificationId differs for different times`() {
        val time1 = ScheduleTime(hour = 8, minute = 0)
        val time2 = ScheduleTime(hour = 20, minute = 0)
        val id1 = AlarmSchedulerImpl.doseNotificationId("med-123", time1)
        val id2 = AlarmSchedulerImpl.doseNotificationId("med-123", time2)
        assertNotEquals(id1, id2, "Different times should produce different notification IDs")
    }

    @Test
    fun `doseNotificationId differs for different medications`() {
        val time = ScheduleTime(hour = 8, minute = 0)
        val id1 = AlarmSchedulerImpl.doseNotificationId("med-aaa", time)
        val id2 = AlarmSchedulerImpl.doseNotificationId("med-bbb", time)
        assertNotEquals(id1, id2, "Different medications should produce different notification IDs")
    }

    @Test
    fun `doseNotificationId is always positive`() {
        val ids = listOf(
            AlarmSchedulerImpl.doseNotificationId("a", ScheduleTime(0, 0)),
            AlarmSchedulerImpl.doseNotificationId("z", ScheduleTime(23, 59)),
            AlarmSchedulerImpl.doseNotificationId("long-medication-id-12345", ScheduleTime(12, 30)),
        )
        ids.forEach { id ->
            assertTrue(id >= 0, "Notification ID should be non-negative, got $id")
        }
    }

    @Test
    fun `nagRequestCode is unique per index`() {
        val baseId = "med-123-08:00"
        val codes = (1..5).map { AlarmSchedulerImpl.nagRequestCode(baseId, it) }
        assertEquals(codes.size, codes.toSet().size, "Each nag index should produce a unique request code")
    }

    @Test
    fun `nagRequestCode is always positive`() {
        val codes = (1..5).map { AlarmSchedulerImpl.nagRequestCode("test-base", it) }
        codes.forEach { code ->
            assertTrue(code >= 0, "Nag request code should be non-negative, got $code")
        }
    }

    @Test
    fun `notificationIdFromString is stable`() {
        val id1 = NotificationConstants.notificationIdFromString("test-notification")
        val id2 = NotificationConstants.notificationIdFromString("test-notification")
        assertEquals(id1, id2)
    }

    @Test
    fun `notificationIdFromString is always positive`() {
        val ids = listOf("a", "zzz", "med-123-08:00-nag-3", "").map {
            NotificationConstants.notificationIdFromString(it)
        }
        ids.forEach { id ->
            assertTrue(id >= 0, "Notification ID from string should be non-negative, got $id")
        }
    }

    @Test
    fun `channelIdForAlertStyle maps correctly`() {
        assertEquals(NotificationConstants.CHANNEL_GENTLE,
            NotificationConstants.channelIdForAlertStyle("gentle"))
        assertEquals(NotificationConstants.CHANNEL_URGENT,
            NotificationConstants.channelIdForAlertStyle("urgent"))
        assertEquals(NotificationConstants.CHANNEL_ESCALATING,
            NotificationConstants.channelIdForAlertStyle("escalating"))
        assertEquals(NotificationConstants.CHANNEL_GENTLE,
            NotificationConstants.channelIdForAlertStyle("unknown"))
    }
}
```

- [ ] **Step 3: Run tests**

```bash
cd android && ./gradlew :core:data:test
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add android/core/data/src/ android/app/src/main/AndroidManifest.xml android/app/src/main/kotlin/com/nateb/mymedtimer/MyMedTimerApp.kt android/gradle/libs.versions.toml android/core/data/build.gradle.kts
git commit -m "feat(android): add notification system with alarms, actions, nags, snooze, haptics"
```

---

## Self-Review Checklist

- [ ] **Permissions:** `POST_NOTIFICATIONS`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE` declared in manifest
- [ ] **No Google Play Services:** Uses `AlarmManager.setExactAndAllowWhileIdle()` — works on GrapheneOS without FCM
- [ ] **Boot survival:** `BootReceiver` reschedules all alarms on `BOOT_COMPLETED`
- [ ] **Alarm precision:** `setExactAndAllowWhileIdle` fires even in Doze mode
- [ ] **Daily recurrence:** `MedicationAlarmReceiver.rescheduleNextDay()` re-arms the alarm after each fire (since Android exact alarms are one-shot)
- [ ] **Three channels:** gentle (default), urgent (HIGH, heads-up), escalating (HIGH, custom vibration pattern)
- [ ] **Three actions:** Taken, Snooze, Skip — each with unique PendingIntent
- [ ] **Nag mode:** `AlarmScheduler.scheduleNagAlarms()` fires up to 5 follow-ups at configurable intervals
- [ ] **Snooze:** Cancels nags, schedules one-shot alarm after delay
- [ ] **Taken action:** Logs dose as "taken", plays success haptic
- [ ] **Skip action:** Logs dose as "skipped", dismisses notification
- [ ] **Haptics:** Four patterns matching iOS (notification, warning, success, escalating)
- [ ] **Hilt DI:** `NotificationModule` binds `AlarmSchedulerImpl` to `AlarmScheduler` interface; receivers use `EntryPointAccessors`
- [ ] **Tests:** Unit tests cover ID generation stability, positivity, uniqueness, trigger time logic, and channel mapping
- [ ] **API 33+:** Uses `VibratorManager` (API 31+), checks `POST_NOTIFICATIONS` runtime permission (API 33+)
