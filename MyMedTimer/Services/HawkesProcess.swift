import Foundation

// MARK: - Hawkes Process Parameters

struct HawkesParameters {
    let mu: Double      // baseline intensity (misses per day)
    let alpha: Double   // excitation magnitude
    let beta: Double    // decay rate (how fast excitement fades)
}

// MARK: - Risk Level

enum RiskLevel: String, Comparable {
    case low, medium, high

    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        let order: [RiskLevel] = [.low, .medium, .high]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

// MARK: - Hawkes Process

enum HawkesProcess {

    // MARK: - Fit Parameters via MLE

    /// Fit Hawkes parameters from miss timestamps using maximum likelihood estimation.
    /// Uses gradient ascent on the log-likelihood for exponential kernel (Ozaki, 1979).
    static func fit(
        missTimestamps: [Date],
        windowStart: Date,
        windowEnd: Date
    ) -> HawkesParameters {
        let windowDuration = windowEnd.timeIntervalSince(windowStart) / 86400.0 // days
        guard windowDuration > 0 else {
            return HawkesParameters(mu: 0.1, alpha: 0.3, beta: 1.0)
        }

        // Convert to sorted doubles (days since window start)
        let times = missTimestamps
            .map { $0.timeIntervalSince(windowStart) / 86400.0 }
            .filter { $0 >= 0 && $0 <= windowDuration }
            .sorted()

        let n = times.count
        let T = windowDuration

        // Too few events — return conservative defaults
        if n < 5 {
            return HawkesParameters(mu: 0.1, alpha: 0.3, beta: 1.0)
        }

        // Initialize parameters
        var mu = Double(n) / T
        var alpha = 0.5
        var beta = 1.0

        let learningRate = 0.01
        let iterations = 30

        for _ in 0..<iterations {
            // Precompute R(tᵢ) and D(tᵢ) for each event
            // R(tᵢ) = Σⱼ<ᵢ exp(-β(tᵢ - tⱼ))
            // D(tᵢ) = -Σⱼ<ᵢ (tᵢ - tⱼ)exp(-β(tᵢ - tⱼ))
            var R = [Double](repeating: 0.0, count: n)
            var D = [Double](repeating: 0.0, count: n)
            var lambdas = [Double](repeating: 0.0, count: n)

            for i in 0..<n {
                var ri = 0.0
                var di = 0.0
                for j in 0..<i {
                    let dt = times[i] - times[j]
                    let expVal = exp(-beta * dt)
                    ri += expVal
                    di -= dt * expVal
                }
                R[i] = ri
                D[i] = di
                lambdas[i] = mu + alpha * ri
            }

            // Compute gradients
            // ∂ℓ/∂μ = Σᵢ 1/λ(tᵢ) - T
            var dMu = -T
            // ∂ℓ/∂α = Σᵢ R(tᵢ)/λ(tᵢ) - (1/β)Σᵢ(1 - exp(-β(T - tᵢ)))
            var dAlpha = 0.0
            // ∂ℓ/∂β = Σᵢ α·D(tᵢ)/λ(tᵢ) - (α/β²)Σᵢ(1 - exp(-β(T-tᵢ)))
            //        + (α/β)Σᵢ(T-tᵢ)exp(-β(T-tᵢ))
            var dBeta = 0.0

            var sumCompensator = 0.0      // Σᵢ(1 - exp(-β(T - tᵢ)))
            var sumCompensatorDt = 0.0    // Σᵢ(T - tᵢ)exp(-β(T - tᵢ))

            for i in 0..<n {
                let lam = max(lambdas[i], 1e-10)
                let invLam = 1.0 / lam

                dMu += invLam
                dAlpha += R[i] * invLam
                dBeta += alpha * D[i] * invLam

                let remaining = T - times[i]
                let expRemaining = exp(-beta * remaining)
                sumCompensator += (1.0 - expRemaining)
                sumCompensatorDt += remaining * expRemaining
            }

            dAlpha -= sumCompensator / beta
            dBeta -= (alpha / (beta * beta)) * sumCompensator
            dBeta += (alpha / beta) * sumCompensatorDt

            // Gradient ascent step
            mu += learningRate * dMu
            alpha += learningRate * dAlpha
            beta += learningRate * dBeta

            // Clamp parameters
            mu = max(mu, 0.001)
            alpha = max(alpha, 0.001)
            beta = max(beta, 0.01)

            // Enforce stationarity: α < 0.95β
            if alpha >= 0.95 * beta {
                alpha = 0.95 * beta
            }
        }

        return HawkesParameters(mu: mu, alpha: alpha, beta: beta)
    }

    // MARK: - Intensity

    /// Compute current intensity λ(t) given parameters and recent miss history.
    static func intensity(
        at time: Date,
        parameters: HawkesParameters,
        recentMisses: [Date]
    ) -> Double {
        var lambda = parameters.mu

        for missTime in recentMisses {
            let dt = time.timeIntervalSince(missTime) / 86400.0 // days
            if dt > 0 {
                lambda += parameters.alpha * exp(-parameters.beta * dt)
            }
        }

        return lambda
    }

    // MARK: - Miss Probability

    /// Miss probability at a scheduled time, mapped via sigmoid.
    /// P = 1 / (1 + exp(-k(λ - λ₀))) where k=5.0, λ₀=μ (baseline).
    static func missProbability(
        at scheduledTime: Date,
        parameters: HawkesParameters,
        recentMisses: [Date]
    ) -> Double {
        let lambda = intensity(
            at: scheduledTime,
            parameters: parameters,
            recentMisses: recentMisses
        )

        let k = 5.0
        let lambda0 = parameters.mu
        let exponent = -k * (lambda - lambda0)
        let probability = 1.0 / (1.0 + exp(exponent))

        return min(max(probability, 0.01), 0.99)
    }

    // MARK: - Risk Level

    /// Risk level: low (<0.2), medium (0.2-0.5), high (>0.5).
    static func riskLevel(missProbability: Double) -> RiskLevel {
        if missProbability < 0.2 {
            return .low
        } else if missProbability <= 0.5 {
            return .medium
        } else {
            return .high
        }
    }
}
