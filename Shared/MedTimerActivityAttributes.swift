import ActivityKit
import Foundation

struct MedTimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var medName: String
        var dosage: String
        var colorHex: String
        var fireDate: Date
    }

    var startDate: Date
}
