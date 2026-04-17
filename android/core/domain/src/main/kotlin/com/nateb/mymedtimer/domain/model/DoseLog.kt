package com.nateb.mymedtimer.domain.model

import java.time.Instant

data class DoseLog(
    val id: String,
    val scheduledTime: Instant,
    val actualTime: Instant?,
    val status: String  // "taken", "skipped", "snoozed"
)
