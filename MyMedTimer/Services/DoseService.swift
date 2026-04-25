import Foundation
import SwiftData

enum DoseService {

    static func logDose(
        for medication: Medication,
        scheduledTime: Date,
        status: String,
        actualTime: Date? = nil,
        in context: ModelContext
    ) {
        let resolvedActualTime: Date?
        if let explicit = actualTime {
            resolvedActualTime = explicit
        } else {
            resolvedActualTime = status == "taken" ? Date() : nil
        }
        let log = DoseLog(
            scheduledTime: scheduledTime,
            status: status,
            actualTime: resolvedActualTime
        )
        medication.doseLogs.append(log)
    }

    static func todaysLogs(for medication: Medication) -> [DoseLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return medication.doseLogs.filter { log in
            log.scheduledTime >= startOfDay
        }
    }
}
