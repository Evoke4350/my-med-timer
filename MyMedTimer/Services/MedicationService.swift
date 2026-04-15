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

    static func sortedByNextDose(_ medications: [Medication], after now: Date = Date()) -> [Medication] {
        medications.sorted { a, b in
            let aNext = nextDoseTime(for: a, after: now) ?? .distantFuture
            let bNext = nextDoseTime(for: b, after: now) ?? .distantFuture
            return aNext < bNext
        }
    }
}
