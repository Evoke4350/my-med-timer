package com.nateb.mymedtimer.domain.model

import java.time.Instant

data class Medication(
    val id: String,
    val name: String,
    val dosage: String,
    val colorHex: String = "#FF6B6B",
    val alertStyle: String = "gentle",
    val isPRN: Boolean = false,
    val minIntervalMinutes: Int = 0,
    val isActive: Boolean = true,
    val createdAt: Instant = Instant.now(),
    val scheduleTimes: List<ScheduleTime> = emptyList(),
    val doseLogs: List<DoseLog> = emptyList()
)
