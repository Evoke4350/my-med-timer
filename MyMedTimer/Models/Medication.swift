import Foundation
import SwiftData

@Model
final class Medication {
    var id: UUID = UUID()
    var name: String = ""
    var dosage: String = ""
    var colorHex: String = "#FF6B6B"
    var alertStyle: String = "gentle"
    var isPRN: Bool = false
    var minIntervalMinutes: Int = 0
    var isActive: Bool = true
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \ScheduleTime.medication)
    var scheduleTimes: [ScheduleTime] = []

    @Relationship(deleteRule: .cascade, inverse: \DoseLog.medication)
    var doseLogs: [DoseLog] = []

    init(name: String, dosage: String, colorHex: String = "#FF6B6B", alertStyle: String = "gentle") {
        self.name = name
        self.dosage = dosage
        self.colorHex = colorHex
        self.alertStyle = alertStyle
    }
}
