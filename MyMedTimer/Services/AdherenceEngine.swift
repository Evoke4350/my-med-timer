import Foundation
import SwiftData

// MARK: - Medication Insight

struct MedicationInsight {
    let medicationId: UUID
    let riskLevel: RiskLevel
    let missProbability: Double
    let consistencyScore: Int
    let suggestedTime: (hour: Int, minute: Int)?
    let currentScheduledTime: (hour: Int, minute: Int)?
    let timeDriftMinutes: Int?
    let recommendedAlertStyle: String
}

// MARK: - Adherence Engine
//
// Risk dot rules (read in this order — first match wins):
//   1. No misses in the past 14 days  → .low (stale signal — historical
//      misses still inform the Hawkes baseline μ but do NOT drive intensity).
//   2. Last 7 logged doses all "taken" → .low (consecutive-clean override —
//      a winning streak earns trust regardless of older misses).
//   3. Otherwise: Hawkes intensity over the last-14-day window → sigmoid →
//      missProbability → riskLevel().
// The dot is meant to be actionable; without these gates a single skip
// 90 days ago left it stuck on yellow indefinitely.

enum AdherenceEngine {

    // MARK: - Whittle Index

    /// Whittle index: W = (importance * missProbability) / fatigueCost
    /// where fatigueCost = 1 + 0.3 * recentEscalationCount
    static func whittleIndex(
        missProbability: Double,
        importance: Double,
        recentEscalationCount: Int
    ) -> Double {
        let fatigueCost = 1.0 + 0.3 * Double(recentEscalationCount)
        return (importance * missProbability) / fatigueCost
    }

    /// Map Whittle index to alert style.
    /// W < 0.3 -> "gentle", 0.3-0.6 -> "urgent", > 0.6 -> "escalating"
    static func recommendedAlertStyle(whittleIndex: Double) -> String {
        if whittleIndex < 0.3 {
            return "gentle"
        } else if whittleIndex <= 0.6 {
            return "urgent"
        } else {
            return "escalating"
        }
    }

    // MARK: - Analysis

    /// Generate insights for a medication from its dose logs.
    static func analyze(
        medication: Medication,
        recentEscalationCount: Int = 0,
        now: Date = Date()
    ) -> MedicationInsight {
        let logs = medication.doseLogs
        let calendar = Calendar.current
        let windowStart = calendar.date(byAdding: .day, value: -90, to: now) ?? now
        let fresh14d = calendar.date(byAdding: .day, value: -14, to: now) ?? now

        // Partition logs into misses and takes
        let missTimestamps = logs
            .filter { $0.status == "skipped" || $0.status == "snoozed" }
            .map { $0.scheduledTime }

        let takenDates = logs
            .filter { $0.status == "taken" }
            .compactMap { $0.actualTime ?? $0.scheduledTime as Date? }

        // Hawkes: fit μ from the full 90d history (preserves baseline calibration),
        // but only feed last-14d misses into intensity so the dot is responsive.
        let params = HawkesProcess.fit(
            missTimestamps: missTimestamps,
            windowStart: windowStart,
            windowEnd: now
        )

        let recentMissesIn14d = missTimestamps.filter { $0 >= fresh14d }

        // Consecutive-clean override: last 7 logs (any status) all "taken" → trust.
        let recentLogsByTime = logs.sorted { $0.scheduledTime > $1.scheduledTime }
        let lastSevenAllTaken = recentLogsByTime.prefix(7).count == 7
            && recentLogsByTime.prefix(7).allSatisfy { $0.status == "taken" }

        let missProb: Double
        let risk: RiskLevel
        if recentMissesIn14d.isEmpty || lastSevenAllTaken {
            missProb = 0.05
            risk = .low
        } else {
            missProb = HawkesProcess.missProbability(
                at: now,
                parameters: params,
                recentMisses: recentMissesIn14d
            )
            risk = HawkesProcess.riskLevel(missProbability: missProb)
        }

        // Circular statistics: consistency and suggested time
        let consistency = CircularStatistics.consistencyScore(from: takenDates)
        let suggested = CircularStatistics.suggestedTime(from: takenDates)

        // Current scheduled time (first schedule)
        let firstSchedule = medication.scheduleTimes
            .sorted(by: { ($0.hour, $0.minute) < ($1.hour, $1.minute) })
            .first
        let currentScheduled: (hour: Int, minute: Int)? = firstSchedule.map {
            (hour: $0.hour, minute: $0.minute)
        }

        // Time drift in minutes between suggested and scheduled
        let drift: Int? = {
            guard let s = suggested, let c = currentScheduled else { return nil }
            let suggestedMinutes = s.hour * 60 + s.minute
            let scheduledMinutes = c.hour * 60 + c.minute
            var diff = suggestedMinutes - scheduledMinutes
            // Wrap around midnight: pick shortest path
            if diff > 720 { diff -= 1440 }
            if diff < -720 { diff += 1440 }
            return diff
        }()

        // Whittle index and alert style
        let whittle = whittleIndex(
            missProbability: missProb,
            importance: 1.0,
            recentEscalationCount: recentEscalationCount
        )
        let alertStyle = recommendedAlertStyle(whittleIndex: whittle)

        return MedicationInsight(
            medicationId: medication.id,
            riskLevel: risk,
            missProbability: missProb,
            consistencyScore: consistency,
            suggestedTime: suggested,
            currentScheduledTime: currentScheduled,
            timeDriftMinutes: drift,
            recommendedAlertStyle: alertStyle
        )
    }

    /// Analyze all active medications, sorted by risk (highest first).
    static func analyzeAll(
        medications: [Medication],
        now: Date = Date()
    ) -> [MedicationInsight] {
        medications
            .filter { $0.isActive }
            .map { analyze(medication: $0, now: now) }
            .sorted { $0.missProbability > $1.missProbability }
    }
}
