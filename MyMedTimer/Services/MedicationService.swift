import Foundation
import SwiftData

enum MedicationService {

    static func nextDoseTime(for medication: Medication, after now: Date = Date()) -> Date? {
        let times = medication.scheduleTimes
        guard !times.isEmpty else { return nil }

        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)

        var candidates: [Date] = []
        for schedule in times {
            var components = todayComponents
            components.hour = schedule.hour
            components.minute = schedule.minute
            components.second = 0
            if let date = calendar.date(from: components), date > now {
                candidates.append(date)
            }
        }

        if let earliest = candidates.min() {
            return earliest
        }

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return nil }
        let tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)

        var tomorrowCandidates: [Date] = []
        for schedule in times {
            var components = tomorrowComponents
            components.hour = schedule.hour
            components.minute = schedule.minute
            components.second = 0
            if let date = calendar.date(from: components) {
                tomorrowCandidates.append(date)
            }
        }

        return tomorrowCandidates.min()
    }

    /// Most recent past scheduled slot for this med strictly before `now` and
    /// within `window`. Returns nil for PRN meds, meds without scheduleTimes,
    /// or when no slot lies in the window. Searches today and yesterday.
    static func mostRecentScheduledDose(
        for medication: Medication,
        before now: Date = Date(),
        within window: TimeInterval = 12 * 3600
    ) -> Date? {
        guard !medication.isPRN else { return nil }
        let times = medication.scheduleTimes
        guard !times.isEmpty else { return nil }

        let calendar = Calendar.current
        let cutoff = now.addingTimeInterval(-window)

        var candidates: [Date] = []
        for dayOffset in [0, -1] {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
            for schedule in times {
                var components = dayComponents
                components.hour = schedule.hour
                components.minute = schedule.minute
                components.second = 0
                guard let date = calendar.date(from: components) else { continue }
                if date < now && date >= cutoff {
                    candidates.append(date)
                }
            }
        }

        return candidates.max()
    }

    /// Last time a dose was actually taken for this medication.
    static func lastTakenTime(for medication: Medication) -> Date? {
        medication.doseLogs
            .filter { $0.status == "taken" }
            .compactMap { $0.actualTime }
            .max()
    }

    /// Time interval since last taken dose. Nil if never taken.
    static func timeSinceLastDose(for medication: Medication, now: Date = Date()) -> TimeInterval? {
        guard let last = lastTakenTime(for: medication) else { return nil }
        return now.timeIntervalSince(last)
    }

    /// Whether PRN med can be taken again (min interval elapsed or no interval set).
    static func canTakePRN(_ medication: Medication, now: Date = Date()) -> Bool {
        guard medication.isPRN, medication.minIntervalMinutes > 0 else { return true }
        guard let elapsed = timeSinceLastDose(for: medication, now: now) else { return true }
        return elapsed >= Double(medication.minIntervalMinutes) * 60
    }

    /// Minutes remaining before PRN med can be taken again. 0 if ready.
    static func minutesUntilCanTake(_ medication: Medication, now: Date = Date()) -> Int {
        guard medication.isPRN, medication.minIntervalMinutes > 0,
              let elapsed = timeSinceLastDose(for: medication, now: now) else { return 0 }
        let remaining = Double(medication.minIntervalMinutes) * 60 - elapsed
        return remaining > 0 ? Int(ceil(remaining / 60)) : 0
    }

    static func sortedByNextDose(_ medications: [Medication], after now: Date = Date()) -> [Medication] {
        medications.sorted { a, b in
            let aNext = nextDoseTime(for: a, after: now) ?? .distantFuture
            let bNext = nextDoseTime(for: b, after: now) ?? .distantFuture
            return aNext < bNext
        }
    }
}
