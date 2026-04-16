import Foundation

enum CircularStatistics {

    // MARK: - Angle ↔ Time Conversion

    /// Convert hour:minute to angle in radians [0, 2π)
    static func timeToAngle(hour: Int, minute: Int) -> Double {
        let totalMinutes = Double(hour * 60 + minute)
        return (totalMinutes / 1440.0) * 2.0 * .pi
    }

    /// Convert angle back to (hour, minute)
    static func angleToTime(_ angle: Double) -> (hour: Int, minute: Int) {
        var normalized = angle.truncatingRemainder(dividingBy: 2.0 * .pi)
        if normalized < 0 { normalized += 2.0 * .pi }
        let totalMinutes = (normalized / (2.0 * .pi)) * 1440.0
        let rounded = Int(totalMinutes.rounded()) % 1440
        return (hour: rounded / 60, minute: rounded % 60)
    }

    // MARK: - Core Circular Statistics

    /// Circular mean of angles (mean direction)
    /// Uses atan2(mean_sin, mean_cos), normalized to [0, 2π)
    static func circularMean(_ angles: [Double]) -> Double {
        guard !angles.isEmpty else { return 0 }
        let sumSin = angles.reduce(0.0) { $0 + sin($1) }
        let sumCos = angles.reduce(0.0) { $0 + cos($1) }
        var mean = atan2(sumSin, sumCos)
        if mean < 0 { mean += 2.0 * .pi }
        return mean
    }

    /// Mean resultant length R̄ = √(C² + S²) / n
    static func meanResultantLength(_ angles: [Double]) -> Double {
        guard !angles.isEmpty else { return 0 }
        let n = Double(angles.count)
        let sumCos = angles.reduce(0.0) { $0 + cos($1) }
        let sumSin = angles.reduce(0.0) { $0 + sin($1) }
        return sqrt(sumCos * sumCos + sumSin * sumSin) / n
    }

    /// Circular variance = 1 - R̄  (range [0,1], 0 = perfectly consistent)
    static func circularVariance(_ angles: [Double]) -> Double {
        return 1.0 - meanResultantLength(angles)
    }

    /// Von Mises concentration parameter κ (MLE approximation, Mardia & Jupp)
    static func vonMisesKappa(_ angles: [Double]) -> Double {
        let rBar = meanResultantLength(angles)
        guard rBar > 0 else { return 0 }

        if rBar < 0.53 {
            return 2.0 * rBar + rBar * rBar * rBar + (5.0 * pow(rBar, 5)) / 6.0
        } else if rBar < 0.85 {
            return -0.4 + 1.39 * rBar + 0.43 / (1.0 - rBar)
        } else {
            return 1.0 / (rBar * rBar * rBar - 4.0 * rBar * rBar + 3.0 * rBar)
        }
    }

    // MARK: - Convenience for Date Arrays

    /// Suggest optimal schedule time from actual taken times.
    /// Returns circular mean as (hour, minute).
    static func suggestedTime(from takenDates: [Date]) -> (hour: Int, minute: Int)? {
        guard !takenDates.isEmpty else { return nil }
        if takenDates.count == 1 {
            let components = Calendar.current.dateComponents([.hour, .minute], from: takenDates[0])
            return (hour: components.hour ?? 0, minute: components.minute ?? 0)
        }
        let angles = takenDates.map { date -> Double in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            return timeToAngle(hour: components.hour ?? 0, minute: components.minute ?? 0)
        }
        let mean = circularMean(angles)
        return angleToTime(mean)
    }

    /// Consistency score 0-100 (100 = perfectly consistent timing)
    static func consistencyScore(from takenDates: [Date]) -> Int {
        guard !takenDates.isEmpty else { return 0 }
        let angles = takenDates.map { date -> Double in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            return timeToAngle(hour: components.hour ?? 0, minute: components.minute ?? 0)
        }
        let score = (1.0 - circularVariance(angles)) * 100.0
        return Int(min(100, max(0, score.rounded())))
    }
}
