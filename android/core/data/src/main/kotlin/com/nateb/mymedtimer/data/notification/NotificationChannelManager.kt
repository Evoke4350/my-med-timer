package com.nateb.mymedtimer.data.notification

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
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

    fun channelIdForAlertStyle(alertStyle: String): String =
        NotificationConstants.channelIdForAlertStyle(alertStyle)
}
