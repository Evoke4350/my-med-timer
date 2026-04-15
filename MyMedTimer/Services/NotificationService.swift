import Foundation
import UserNotifications

protocol NotificationCenterProtocol: Sendable {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func removeAllPendingNotificationRequests()
}

extension UNUserNotificationCenter: NotificationCenterProtocol {}

final class NotificationService: Sendable {
    let center: NotificationCenterProtocol

    init(center: NotificationCenterProtocol = UNUserNotificationCenter.current()) {
        self.center = center
    }

    func requestPermission() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleNotification(
        id: String,
        title: String,
        body: String,
        hour: Int,
        minute: Int
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try await center.add(request)
    }

    func scheduleAll(
        medicationId: String,
        name: String,
        dosage: String,
        times: [(hour: Int, minute: Int)]
    ) async throws {
        for time in times {
            let id = "med-\(medicationId)-\(String(format: "%02d:%02d", time.hour, time.minute))"
            try await scheduleNotification(
                id: id,
                title: name,
                body: "\(dosage) — time to take your dose",
                hour: time.hour,
                minute: time.minute
            )
        }
    }

    func cancelNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
