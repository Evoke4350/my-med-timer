package com.nateb.mymedtimer.math

import java.time.Duration
import java.time.Instant

object AdherenceEngine {

    /**
     * Whittle index: W = (importance * missProbability) / fatigueCost
     * where fatigueCost = 1 + 0.3 * recentEscalationCount
     */
    fun whittleIndex(
        missProbability: Double,
        importance: Double,
        recentEscalationCount: Int
    ): Double {
        val fatigueCost = 1.0 + 0.3 * recentEscalationCount
        return (importance * missProbability) / fatigueCost
    }

    /**
     * Map Whittle index to alert style.
     * W < 0.3 -> "gentle", 0.3-0.6 -> "urgent", > 0.6 -> "escalating"
     */
    fun recommendedAlertStyle(whittleIndex: Double): String {
        return when {
            whittleIndex < 0.3 -> "gentle"
            whittleIndex <= 0.6 -> "urgent"
            else -> "escalating"
        }
    }

    /**
     * Generate insights from raw timestamp data.
     * This operates on primitive data so the math module stays free of Android/domain dependencies.
     */
    fun analyze(
        missTimestamps: List<Instant>,
        takenTimestamps: List<Instant>,
        scheduledHour: Int?,
        scheduledMinute: Int?,
        recentEscalationCount: Int = 0,
        now: Instant = Instant.now()
    ): MedicationInsight {
        val windowStart = now.minus(Duration.ofDays(90))

        val params = HawkesProcess.fit(
            missTimestamps = missTimestamps,
            windowStart = windowStart,
            windowEnd = now
        )

        val recentMisses = missTimestamps.filter { !it.isBefore(windowStart) }

        val missProb: Double
        val risk: RiskLevel
        if (recentMisses.isEmpty()) {
            missProb = 0.05
            risk = RiskLevel.LOW
        } else {
            missProb = HawkesProcess.missProbability(now, params, recentMisses)
            risk = HawkesProcess.riskLevel(missProb)
        }

        val consistency = CircularStatistics.consistencyScore(takenTimestamps)
        val suggested = CircularStatistics.suggestedTime(takenTimestamps)

        val currentScheduled = if (scheduledHour != null && scheduledMinute != null) {
            Pair(scheduledHour, scheduledMinute)
        } else {
            null
        }

        val drift: Int? = if (suggested != null && currentScheduled != null) {
            val suggestedMinutes = suggested.first * 60 + suggested.second
            val scheduledMinutes = currentScheduled.first * 60 + currentScheduled.second
            var diff = suggestedMinutes - scheduledMinutes
            if (diff > 720) diff -= 1440
            if (diff < -720) diff += 1440
            diff
        } else {
            null
        }

        val whittle = whittleIndex(
            missProbability = missProb,
            importance = 1.0,
            recentEscalationCount = recentEscalationCount
        )
        val alertStyle = recommendedAlertStyle(whittle)

        return MedicationInsight(
            riskLevel = risk,
            missProbability = missProb,
            consistencyScore = consistency,
            suggestedTime = suggested,
            currentScheduledTime = currentScheduled,
            timeDriftMinutes = drift,
            recommendedAlertStyle = alertStyle
        )
    }
}
