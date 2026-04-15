import Foundation

enum TimeFormatting {

    static func countdown(_ interval: TimeInterval) -> String {
        if interval < 0 { return "overdue" }
        if interval == 0 { return "now" }
        if interval < 60 { return "<1m" }

        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    static func timeOfDay(hour: Int, minute: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let calendar = Calendar.current
        let date = calendar.date(from: components) ?? Date()
        return formatter.string(from: date)
    }
}
