import Foundation
import SwiftData

enum DoseService {

    static func logDose(
        for medication: Medication,
        scheduledTime: Date,
        status: String,
        in context: ModelContext
    ) {
        let log = DoseLog(
            scheduledTime: scheduledTime,
            status: status,
            actualTime: status == "taken" ? Date() : nil
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
