package com.nateb.mymedtimer.math

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import kotlin.math.PI
import kotlin.math.abs

class CircularStatisticsTest {

    private val accuracy = 0.01

    @Test
    fun `timeToAngle midnight is zero`() {
        assertEquals(0.0, CircularStatistics.timeToAngle(0, 0), accuracy)
    }

    @Test
    fun `timeToAngle 6AM is pi over 2`() {
        assertEquals(PI / 2, CircularStatistics.timeToAngle(6, 0), accuracy)
    }

    @Test
    fun `timeToAngle noon is pi`() {
        assertEquals(PI, CircularStatistics.timeToAngle(12, 0), accuracy)
    }

    @Test
    fun `timeToAngle 6PM is 3pi over 2`() {
        assertEquals(3 * PI / 2, CircularStatistics.timeToAngle(18, 0), accuracy)
    }

    @Test
    fun `angleToTime round trip`() {
        val testCases = listOf(
            0 to 0, 6 to 0, 12 to 0, 18 to 0,
            8 to 30, 23 to 45, 14 to 15
        )
        for ((h, m) in testCases) {
            val angle = CircularStatistics.timeToAngle(h, m)
            val (rh, rm) = CircularStatistics.angleToTime(angle)
            assertEquals(h, rh, "Hour mismatch for $h:$m")
            assertEquals(m, rm, "Minute mismatch for $h:$m")
        }
    }

    @Test
    fun `angleToTime negative angle normalizes`() {
        val (h, m) = CircularStatistics.angleToTime(-PI / 2)
        assertEquals(18, h)
        assertEquals(0, m)
    }

    @Test
    fun `circular mean midnight wrap`() {
        val angle11pm = CircularStatistics.timeToAngle(23, 0)
        val angle1am = CircularStatistics.timeToAngle(1, 0)
        val mean = CircularStatistics.circularMean(listOf(angle11pm, angle1am))
        val (h, m) = CircularStatistics.angleToTime(mean)
        assertEquals(0, h, "Circular mean of 11pm and 1am should be midnight")
        assertTrue(abs(m) <= 1)
    }

    @Test
    fun `circular mean same angles`() {
        val angle = CircularStatistics.timeToAngle(8, 0)
        val mean = CircularStatistics.circularMean(listOf(angle, angle, angle))
        assertEquals(angle, mean, accuracy)
    }

    @Test
    fun `circular mean empty returns zero`() {
        assertEquals(0.0, CircularStatistics.circularMean(emptyList()))
    }

    @Test
    fun `mean resultant length identical angles is 1`() {
        val angle = CircularStatistics.timeToAngle(9, 0)
        val rBar = CircularStatistics.meanResultantLength(listOf(angle, angle, angle))
        assertEquals(1.0, rBar, accuracy)
    }

    @Test
    fun `mean resultant length opposite angles is 0`() {
        val rBar = CircularStatistics.meanResultantLength(listOf(0.0, PI))
        assertEquals(0.0, rBar, accuracy)
    }

    @Test
    fun `mean resultant length empty is 0`() {
        assertEquals(0.0, CircularStatistics.meanResultantLength(emptyList()))
    }

    @Test
    fun `circular variance same angles is 0`() {
        val angle = CircularStatistics.timeToAngle(10, 0)
        val variance = CircularStatistics.circularVariance(listOf(angle, angle, angle))
        assertEquals(0.0, variance, accuracy)
    }

    @Test
    fun `circular variance uniform spread is 1`() {
        val angles = listOf(0.0, PI / 2, PI, 3 * PI / 2)
        val variance = CircularStatistics.circularVariance(angles)
        assertEquals(1.0, variance, accuracy)
    }

    @Test
    fun `vonMises kappa high concentration`() {
        val angle = CircularStatistics.timeToAngle(8, 0)
        val angles = List(5) { angle }
        val kappa = CircularStatistics.vonMisesKappa(angles)
        assertTrue(kappa > 10.0, "Identical angles should produce high kappa")
    }

    @Test
    fun `vonMises kappa low concentration`() {
        val angles = listOf(0.0, PI / 2, PI, 3 * PI / 2)
        val kappa = CircularStatistics.vonMisesKappa(angles)
        assertEquals(0.0, kappa, 0.1)
    }

    @Test
    fun `vonMises kappa empty is 0`() {
        assertEquals(0.0, CircularStatistics.vonMisesKappa(emptyList()))
    }

    @Test
    fun `suggested time around 8am`() {
        val zone = ZoneId.systemDefault()
        val today = LocalDate.now()
        val dates = listOf(
            LocalTime.of(7, 50), LocalTime.of(8, 10),
            LocalTime.of(7, 55), LocalTime.of(8, 5)
        ).map { time ->
            today.atTime(time).atZone(zone).toInstant()
        }
        val result = CircularStatistics.suggestedTime(dates)
        assertNotNull(result)
        assertEquals(8, result!!.first)
        assertTrue(abs(result.second) <= 2)
    }

    @Test
    fun `suggested time empty returns null`() {
        assertNull(CircularStatistics.suggestedTime(emptyList()))
    }

    @Test
    fun `suggested time single date`() {
        val zone = ZoneId.systemDefault()
        val date = LocalDate.now().atTime(14, 30).atZone(zone).toInstant()
        val result = CircularStatistics.suggestedTime(listOf(date))
        assertNotNull(result)
        assertEquals(14, result!!.first)
        assertEquals(30, result.second)
    }

    @Test
    fun `consistency score tight cluster is high`() {
        val zone = ZoneId.systemDefault()
        val today = LocalDate.now()
        val dates = (0 until 10).map { i ->
            today.minusDays(i.toLong())
                .atTime(9, i % 3)
                .atZone(zone)
                .toInstant()
        }
        val score = CircularStatistics.consistencyScore(dates)
        assertTrue(score > 90, "Tight cluster should have high consistency, got $score")
    }

    @Test
    fun `consistency score scattered is low`() {
        val zone = ZoneId.systemDefault()
        val today = LocalDate.now()
        val dates = listOf(0, 6, 12, 18).map { hour ->
            today.atTime(hour, 0).atZone(zone).toInstant()
        }
        val score = CircularStatistics.consistencyScore(dates)
        assertTrue(score < 10, "Scattered times should have low consistency, got $score")
    }

    @Test
    fun `consistency score empty is 0`() {
        assertEquals(0, CircularStatistics.consistencyScore(emptyList()))
    }
}
