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
        minute: Int,
        medicationId: String = "",
        alertStyle: String = "gentle"
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"
        content.userInfo = [
            "medicationId": medicationId,
            "alertStyle": alertStyle
        ]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try await center.add(request)
    }

    func scheduleOneShot(
        id: String,
        title: String,
        body: String,
        at date: Date,
        medicationId: String = "",
        alertStyle: String = "gentle"
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"
        content.userInfo = [
            "medicationId": medicationId,
            "alertStyle": alertStyle
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, date.timeIntervalSinceNow),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try await center.add(request)
    }

    func scheduleAll(
        medicationId: String,
        name: String,
        dosage: String,
        times: [(hour: Int, minute: Int)],
        alertStyle: String = "gentle"
    ) async throws {
        for time in times {
            let id = "med-\(medicationId)-\(String(format: "%02d:%02d", time.hour, time.minute))"
            try await scheduleNotification(
                id: id,
                title: name,
                body: "\(dosage) — time to take your dose",
                hour: time.hour,
                minute: time.minute,
                medicationId: medicationId,
                alertStyle: alertStyle
            )
        }
    }

    /// Schedule nag reminders: fires every `intervalMinutes` for up to `count` times
    func scheduleNags(
        baseId: String,
        title: String,
        body: String,
        startingAfter delay: TimeInterval,
        intervalMinutes: Int,
        count: Int = 5,
        medicationId: String = "",
        alertStyle: String = "gentle"
    ) async throws {
        for i in 1...count {
            let nagDelay = delay + Double(i * intervalMinutes * 60)
            let nagId = "\(baseId)-nag-\(i)"
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.categoryIdentifier = "MEDICATION_REMINDER"
            content.userInfo = [
                "medicationId": medicationId,
                "alertStyle": alertStyle,
                "isNag": true
            ]

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(1, nagDelay),
                repeats: false
            )
            let request = UNNotificationRequest(identifier: nagId, content: content, trigger: trigger)
            try await center.add(request)
        }
    }

    /// Cancel nag reminders for a given base ID
    func cancelNags(baseId: String, count: Int = 5) {
        let ids = (1...count).map { "\(baseId)-nag-\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func cancelNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
