package com.nateb.mymedtimer.math

import java.time.Instant
import java.time.ZoneId
import kotlin.math.*

object CircularStatistics {

    /**
     * Convert hour:minute to angle in radians [0, 2*PI).
     */
    fun timeToAngle(hour: Int, minute: Int): Double {
        val totalMinutes = (hour * 60 + minute).toDouble()
        return (totalMinutes / 1440.0) * 2.0 * PI
    }

    /**
     * Convert angle back to (hour, minute).
     */
    fun angleToTime(angle: Double): Pair<Int, Int> {
        var normalized = angle % (2.0 * PI)
        if (normalized < 0) normalized += 2.0 * PI
        val totalMinutes = (normalized / (2.0 * PI)) * 1440.0
        val rounded = totalMinutes.roundToInt() % 1440
        return Pair(rounded / 60, rounded % 60)
    }

    /**
     * Circular mean of angles (mean direction).
     * Uses atan2(mean_sin, mean_cos), normalized to [0, 2*PI).
     */
    fun circularMean(angles: List<Double>): Double {
        if (angles.isEmpty()) return 0.0
        val sumSin = angles.sumOf { sin(it) }
        val sumCos = angles.sumOf { cos(it) }
        var mean = atan2(sumSin, sumCos)
        if (mean < 0) mean += 2.0 * PI
        return mean
    }

    /**
     * Mean resultant length R-bar = sqrt(C^2 + S^2) / n.
     */
    fun meanResultantLength(angles: List<Double>): Double {
        if (angles.isEmpty()) return 0.0
        val n = angles.size.toDouble()
        val sumCos = angles.sumOf { cos(it) }
        val sumSin = angles.sumOf { sin(it) }
        return sqrt(sumCos * sumCos + sumSin * sumSin) / n
    }

    /**
     * Circular variance = 1 - R-bar (range [0,1], 0 = perfectly consistent).
     */
    fun circularVariance(angles: List<Double>): Double {
        return 1.0 - meanResultantLength(angles)
    }

    /**
     * Von Mises concentration parameter kappa (MLE approximation, Mardia & Jupp).
     */
    fun vonMisesKappa(angles: List<Double>): Double {
        val rBar = meanResultantLength(angles)
        if (rBar <= 0) return 0.0

        return when {
            rBar < 0.53 -> 2.0 * rBar + rBar.pow(3) + (5.0 * rBar.pow(5)) / 6.0
            rBar < 0.85 -> -0.4 + 1.39 * rBar + 0.43 / (1.0 - rBar)
            else -> 1.0 / (rBar.pow(3) - 4.0 * rBar.pow(2) + 3.0 * rBar)
        }
    }

    /**
     * Suggest optimal schedule time from actual taken times.
     * Returns circular mean as (hour, minute), or null if empty.
     */
    fun suggestedTime(takenInstants: List<Instant>): Pair<Int, Int>? {
        if (takenInstants.isEmpty()) return null
        val zone = ZoneId.systemDefault()
        if (takenInstants.size == 1) {
            val lt = takenInstants[0].atZone(zone).toLocalTime()
            return Pair(lt.hour, lt.minute)
        }
        val angles = takenInstants.map { instant ->
            val lt = instant.atZone(zone).toLocalTime()
            timeToAngle(lt.hour, lt.minute)
        }
        val mean = circularMean(angles)
        return angleToTime(mean)
    }

    /**
     * Consistency score 0-100 (100 = perfectly consistent timing).
     */
    fun consistencyScore(takenInstants: List<Instant>): Int {
        if (takenInstants.isEmpty()) return 0
        val zone = ZoneId.systemDefault()
        val angles = takenInstants.map { instant ->
            val lt = instant.atZone(zone).toLocalTime()
            timeToAngle(lt.hour, lt.minute)
        }
        val score = (1.0 - circularVariance(angles)) * 100.0
        return min(100.0, max(0.0, score)).roundToInt()
    }
}
