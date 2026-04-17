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
