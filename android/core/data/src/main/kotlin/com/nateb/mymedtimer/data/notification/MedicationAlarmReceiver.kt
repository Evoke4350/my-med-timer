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
