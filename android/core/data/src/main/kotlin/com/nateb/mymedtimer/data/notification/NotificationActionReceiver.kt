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
