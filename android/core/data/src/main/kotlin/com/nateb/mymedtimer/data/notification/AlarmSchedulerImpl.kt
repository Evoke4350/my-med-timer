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
