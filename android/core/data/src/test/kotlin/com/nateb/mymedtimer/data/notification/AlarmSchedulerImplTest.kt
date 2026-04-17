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
        val millis = AlarmSchedulerImpl.nextTriggerTimeMillis(23, 59)
        assertTrue(millis > System.currentTimeMillis(), "Trigger time should be in the future")
    }

    @Test
    fun `nextTriggerTimeMillis returns tomorrow if time already passed`() {
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
