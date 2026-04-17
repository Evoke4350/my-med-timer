package com.nateb.mymedtimer.math

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
import java.time.Instant
import java.time.Duration

class HawkesProcessTest {

    private val defaultParams = HawkesParameters(mu = 0.1, alpha = 0.3, beta = 1.0)

    @Test
    fun `intensity with no misses equals baseline mu`() {
        val now = Instant.now()
        val lambda = HawkesProcess.intensity(now, defaultParams, emptyList())
        assertEquals(defaultParams.mu, lambda, 0.001)
    }

    @Test
    fun `intensity increases after miss`() {
        val now = Instant.now()
        val justMissed = now.minus(Duration.ofHours(1))
        val lambda = HawkesProcess.intensity(now, defaultParams, listOf(justMissed))
        assertTrue(lambda > defaultParams.mu, "Intensity should increase after a recent miss")
    }

    @Test
    fun `intensity decays over time`() {
        val now = Instant.now()
        val recentMiss = now.minus(Duration.ofHours(1))
        val olderMiss = now.minus(Duration.ofDays(7))

        val lambdaRecent = HawkesProcess.intensity(now, defaultParams, listOf(recentMiss))
        val lambdaOlder = HawkesProcess.intensity(now, defaultParams, listOf(olderMiss))

        assertTrue(lambdaRecent > lambdaOlder, "Recent miss intensity should exceed older miss")
    }

    @Test
    fun `multiple misses stack intensity`() {
        val now = Instant.now()
        val miss1 = now.minus(Duration.ofHours(1))
        val miss2 = now.minus(Duration.ofHours(2))

        val lambdaSingle = HawkesProcess.intensity(now, defaultParams, listOf(miss1))
        val lambdaDouble = HawkesProcess.intensity(now, defaultParams, listOf(miss1, miss2))

        assertTrue(lambdaDouble > lambdaSingle, "Multiple misses should stack")
    }

    @Test
    fun `miss probability in valid range`() {
        val now = Instant.now()
        val prob = HawkesProcess.missProbability(now, defaultParams, emptyList())
        assertTrue(prob in 0.0..1.0)
    }

    @Test
    fun `miss probability higher after miss`() {
        val now = Instant.now()
        val recentMiss = now.minus(Duration.ofHours(1))
        val probNoMiss = HawkesProcess.missProbability(now, defaultParams, emptyList())
        val probAfterMiss = HawkesProcess.missProbability(now, defaultParams, listOf(recentMiss))
        assertTrue(probAfterMiss > probNoMiss)
    }

    @Test
    fun `risk level low`() {
        assertEquals(RiskLevel.LOW, HawkesProcess.riskLevel(0.1))
    }

    @Test
    fun `risk level medium`() {
        assertEquals(RiskLevel.MEDIUM, HawkesProcess.riskLevel(0.3))
    }

    @Test
    fun `risk level high`() {
        assertEquals(RiskLevel.HIGH, HawkesProcess.riskLevel(0.7))
    }

    @Test
    fun `risk level boundaries`() {
        assertEquals(RiskLevel.LOW, HawkesProcess.riskLevel(0.19))
        assertEquals(RiskLevel.MEDIUM, HawkesProcess.riskLevel(0.2))
        assertEquals(RiskLevel.MEDIUM, HawkesProcess.riskLevel(0.5))
        assertEquals(RiskLevel.HIGH, HawkesProcess.riskLevel(0.51))
    }

    @Test
    fun `fit with too few events returns defaults`() {
        val now = Instant.now()
        val timestamps = listOf(now, now.minus(Duration.ofDays(1)))
        val params = HawkesProcess.fit(
            timestamps,
            windowStart = now.minus(Duration.ofDays(30)),
            windowEnd = now
        )
        assertEquals(0.1, params.mu, 0.001)
        assertEquals(0.3, params.alpha, 0.001)
        assertEquals(1.0, params.beta, 0.001)
    }

    @Test
    fun `fit enforces stationarity constraint`() {
        val now = Instant.now()
        val timestamps = (0 until 20).map { i ->
            now.minus(Duration.ofHours(i.toLong()))
        }
        val params = HawkesProcess.fit(
            timestamps,
            windowStart = now.minus(Duration.ofDays(30)),
            windowEnd = now
        )
        assertTrue(params.alpha < params.beta, "Stationarity: alpha must be < beta")
    }

    @Test
    fun `fit returns positive parameters`() {
        val now = Instant.now()
        val timestamps = (0 until 10).map { i ->
            now.minus(Duration.ofDays(i.toLong() * 2))
        }
        val params = HawkesProcess.fit(
            timestamps,
            windowStart = now.minus(Duration.ofDays(30)),
            windowEnd = now
        )
        assertTrue(params.mu > 0)
        assertTrue(params.alpha > 0)
        assertTrue(params.beta > 0)
    }
}
