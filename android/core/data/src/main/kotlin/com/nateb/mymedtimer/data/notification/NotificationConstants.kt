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

    // Nag defaults
    const val DEFAULT_NAG_COUNT = 5
    const val DEFAULT_SNOOZE_MINUTES = 10

    fun notificationIdFromString(id: String): Int = id.hashCode() and 0x7FFFFFFF

    fun channelIdForAlertStyle(alertStyle: String): String = when (alertStyle) {
        "urgent" -> CHANNEL_URGENT
        "escalating" -> CHANNEL_ESCALATING
        else -> CHANNEL_GENTLE
    }
}
