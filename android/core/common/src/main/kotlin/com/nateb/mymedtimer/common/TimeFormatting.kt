package com.nateb.mymedtimer.common

import java.time.Instant
import java.time.LocalTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter

object TimeFormatting {

    fun countdown(intervalSeconds: Long): String {
        if (intervalSeconds < 0) return "overdue"
        if (intervalSeconds == 0L) return "now"
        if (intervalSeconds < 60) return "<1m"

        val totalMinutes = intervalSeconds / 60
        val hours = totalMinutes / 60
        val minutes = totalMinutes % 60

        return if (hours > 0) {
            "${hours}h ${minutes}m"
        } else {
            "${minutes}m"
        }
    }

    fun timeOfDay(hour: Int, minute: Int): String {
        val time = LocalTime.of(hour, minute)
        val formatter = DateTimeFormatter.ofPattern("h:mm a")
        return time.format(formatter)
    }

    fun shortTime(instant: Instant): String {
        val time = instant.atZone(ZoneId.systemDefault()).toLocalTime()
        val formatter = DateTimeFormatter.ofPattern("h:mm a")
        return time.format(formatter)
    }
}
