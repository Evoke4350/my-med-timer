import Foundation
import SwiftData

@Model
final class ScheduleTime {
    var id: UUID = UUID()
    var hour: Int = 8
    var minute: Int = 0
    var medication: Medication?

    init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }
}
