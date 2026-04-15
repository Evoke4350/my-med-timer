import Foundation
import SwiftData

@Model
final class DoseLog {
    var id: UUID = UUID()
    var scheduledTime: Date = Date()
    var actualTime: Date? = nil
    var status: String = "taken"
    var medication: Medication?

    init(scheduledTime: Date, status: String = "taken", actualTime: Date? = nil) {
        self.scheduledTime = scheduledTime
        self.status = status
        self.actualTime = actualTime
    }
}
