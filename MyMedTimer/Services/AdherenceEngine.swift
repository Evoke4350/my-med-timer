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
        let windowStart = Calendar.current.date(byAdding: .day, value: -90, to: now) ?? now

        // Partition logs into misses and takes
        let missTimestamps = logs
            .filter { $0.status == "skipped" || $0.status == "snoozed" }
            .map { $0.scheduledTime }

        let takenDates = logs
            .filter { $0.status == "taken" }
            .compactMap { $0.actualTime ?? $0.scheduledTime as Date? }

        // Hawkes: fit and compute miss probability
        let params = HawkesProcess.fit(
            missTimestamps: missTimestamps,
            windowStart: windowStart,
            windowEnd: now
        )

        let recentMisses = missTimestamps.filter { $0 >= windowStart }

        // Zero misses in window → low probability directly (sigmoid baseline = 0.5 is misleading)
        let missProb: Double
        let risk: RiskLevel
        if recentMisses.isEmpty {
            missProb = 0.05
            risk = .low
        } else {
            missProb = HawkesProcess.missProbability(
                at: now,
                parameters: params,
                recentMisses: recentMisses
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
