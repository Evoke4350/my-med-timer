package com.nateb.mymedtimer.math

import java.time.Instant
import kotlin.math.exp
import kotlin.math.max
import kotlin.math.min

object HawkesProcess {

    private const val SECONDS_PER_DAY = 86400.0

    /**
     * Fit Hawkes parameters from miss timestamps using maximum likelihood estimation.
     * Gradient ascent on the log-likelihood for exponential kernel (Ozaki, 1979).
     */
    fun fit(
        missTimestamps: List<Instant>,
        windowStart: Instant,
        windowEnd: Instant
    ): HawkesParameters {
        val windowDuration = (windowEnd.epochSecond - windowStart.epochSecond) / SECONDS_PER_DAY
        if (windowDuration <= 0) {
            return HawkesParameters(mu = 0.1, alpha = 0.3, beta = 1.0)
        }

        val times = missTimestamps
            .map { (it.epochSecond - windowStart.epochSecond) / SECONDS_PER_DAY }
            .filter { it in 0.0..windowDuration }
            .sorted()

        val n = times.size
        val T = windowDuration

        if (n < 5) {
            return HawkesParameters(mu = 0.1, alpha = 0.3, beta = 1.0)
        }

        var mu = n.toDouble() / T
        var alpha = 0.5
        var beta = 1.0

        val learningRate = 0.01
        val iterations = 30

        repeat(iterations) {
            val R = DoubleArray(n)
            val D = DoubleArray(n)
            val lambdas = DoubleArray(n)

            for (i in 0 until n) {
                var ri = 0.0
                var di = 0.0
                for (j in 0 until i) {
                    val dt = times[i] - times[j]
                    val expVal = exp(-beta * dt)
                    ri += expVal
                    di -= dt * expVal
                }
                R[i] = ri
                D[i] = di
                lambdas[i] = mu + alpha * ri
            }

            var dMu = -T
            var dAlpha = 0.0
            var dBeta = 0.0
            var sumCompensator = 0.0
            var sumCompensatorDt = 0.0

            for (i in 0 until n) {
                val lam = max(lambdas[i], 1e-10)
                val invLam = 1.0 / lam

                dMu += invLam
                dAlpha += R[i] * invLam
                dBeta += alpha * D[i] * invLam

                val remaining = T - times[i]
                val expRemaining = exp(-beta * remaining)
                sumCompensator += (1.0 - expRemaining)
                sumCompensatorDt += remaining * expRemaining
            }

            dAlpha -= sumCompensator / beta
            dBeta -= (alpha / (beta * beta)) * sumCompensator
            dBeta += (alpha / beta) * sumCompensatorDt

            mu += learningRate * dMu
            alpha += learningRate * dAlpha
            beta += learningRate * dBeta

            mu = max(mu, 0.001)
            alpha = max(alpha, 0.001)
            beta = max(beta, 0.01)

            if (alpha >= 0.95 * beta) {
                alpha = 0.95 * beta
            }
        }

        return HawkesParameters(mu = mu, alpha = alpha, beta = beta)
    }

    /**
     * Compute current intensity lambda(t) given parameters and recent miss history.
     */
    fun intensity(
        at: Instant,
        parameters: HawkesParameters,
        recentMisses: List<Instant>
    ): Double {
        var lambda = parameters.mu

        for (missTime in recentMisses) {
            val dt = (at.epochSecond - missTime.epochSecond) / SECONDS_PER_DAY
            if (dt > 0) {
                lambda += parameters.alpha * exp(-parameters.beta * dt)
            }
        }

        return lambda
    }

    /**
     * Miss probability at a scheduled time, mapped via sigmoid.
     * P = 1 / (1 + exp(-k(lambda - lambda0))) where k=5.0, lambda0=mu.
     */
    fun missProbability(
        at: Instant,
        parameters: HawkesParameters,
        recentMisses: List<Instant>
    ): Double {
        val lambda = intensity(at, parameters, recentMisses)

        val k = 5.0
        val lambda0 = parameters.mu
        val exponent = -k * (lambda - lambda0)
        val probability = 1.0 / (1.0 + exp(exponent))

        return min(max(probability, 0.01), 0.99)
    }

    /**
     * Risk level: low (<0.2), medium (0.2-0.5), high (>0.5).
     */
    fun riskLevel(missProbability: Double): RiskLevel {
        return when {
            missProbability < 0.2 -> RiskLevel.LOW
            missProbability <= 0.5 -> RiskLevel.MEDIUM
            else -> RiskLevel.HIGH
        }
    }
}
