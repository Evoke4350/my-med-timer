package com.nateb.mymedtimer.math

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
import java.time.Duration
import java.time.Instant

class AdherenceEngineTest {

    @Test
    fun `whittle index increases with miss probability`() {
        val low = AdherenceEngine.whittleIndex(missProbability = 0.1, importance = 1.0, recentEscalationCount = 0)
        val high = AdherenceEngine.whittleIndex(missProbability = 0.8, importance = 1.0, recentEscalationCount = 0)
        assertTrue(high > low)
    }

    @Test
    fun `whittle index decreases with escalations`() {
        val noFatigue = AdherenceEngine.whittleIndex(missProbability = 0.5, importance = 1.0, recentEscalationCount = 0)
        val withFatigue = AdherenceEngine.whittleIndex(missProbability = 0.5, importance = 1.0, recentEscalationCount = 5)
        assertTrue(noFatigue > withFatigue, "More escalations should reduce Whittle index")
    }

    @Test
    fun `whittle index scales with importance`() {
        val low = AdherenceEngine.whittleIndex(missProbability = 0.5, importance = 0.5, recentEscalationCount = 0)
        val high = AdherenceEngine.whittleIndex(missProbability = 0.5, importance = 2.0, recentEscalationCount = 0)
        assertTrue(high > low)
    }

    @Test
    fun `recommended alert style gentle`() {
        assertEquals("gentle", AdherenceEngine.recommendedAlertStyle(whittleIndex = 0.1))
        assertEquals("gentle", AdherenceEngine.recommendedAlertStyle(whittleIndex = 0.29))
    }

    @Test
    fun `recommended alert style urgent`() {
        assertEquals("urgent", AdherenceEngine.recommendedAlertStyle(whittleIndex = 0.3))
        assertEquals("urgent", AdherenceEngine.recommendedAlertStyle(whittleIndex = 0.5))
    }

    @Test
    fun `recommended alert style escalating`() {
        assertEquals("escalating", AdherenceEngine.recommendedAlertStyle(whittleIndex = 0.61))
        assertEquals("escalating", AdherenceEngine.recommendedAlertStyle(whittleIndex = 0.9))
    }

    @Test
    fun `analyze with zero misses returns low risk`() {
        val now = Instant.now()
        val insight = AdherenceEngine.analyze(
            missTimestamps = emptyList(),
            takenTimestamps = (0 until 30).map { i ->
                now.minus(Duration.ofDays(i.toLong()))
            },
            scheduledHour = 8,
            scheduledMinute = 0,
            recentEscalationCount = 0,
            now = now
        )
        assertEquals(RiskLevel.LOW, insight.riskLevel)
        assertEquals("gentle", insight.recommendedAlertStyle)
        assertTrue(insight.missProbability < 0.1)
    }

    @Test
    fun `analyze with recent skips elevates risk`() {
        val now = Instant.now()
        val missTimestamps = (0 until 5).map { i ->
            now.minus(Duration.ofDays(i.toLong()))
        }
        val takenTimestamps = (5 until 30).map { i ->
            now.minus(Duration.ofDays(i.toLong()))
        }
        val insight = AdherenceEngine.analyze(
            missTimestamps = missTimestamps,
            takenTimestamps = takenTimestamps,
            scheduledHour = 8,
            scheduledMinute = 0,
            recentEscalationCount = 0,
            now = now
        )
        assertTrue(insight.missProbability > 0.3, "Recent skips should elevate miss probability")
    }

    @Test
    fun `analyze with empty logs`() {
        val now = Instant.now()
        val insight = AdherenceEngine.analyze(
            missTimestamps = emptyList(),
            takenTimestamps = emptyList(),
            scheduledHour = 8,
            scheduledMinute = 0,
            recentEscalationCount = 0,
            now = now
        )
        assertEquals(0, insight.consistencyScore)
        assertNull(insight.suggestedTime)
    }
}
