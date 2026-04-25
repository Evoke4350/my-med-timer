import Foundation
import UserNotifications
import SwiftData

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        super.init()
    }

    // Handle notification actions (Taken / Snooze / Skip)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        guard let medIdString = userInfo["medicationId"] as? String,
              let medId = UUID(uuidString: medIdString) else {
            completionHandler()
            return
        }

        let actionIdentifier = response.actionIdentifier

        Task { @MainActor in
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<Medication>(
                predicate: #Predicate { $0.id == medId }
            )

            guard let medication = try? context.fetch(descriptor).first else {
                completionHandler()
                return
            }

            let service = NotificationService()
            let notificationId = response.notification.request.identifier

            // Cancel any pending nags for this notification
            service.cancelNags(baseId: notificationId)

            switch actionIdentifier {
            case "TAKEN":
                let scheduledTime = response.notification.date
                DoseService.logDose(for: medication, scheduledTime: scheduledTime, status: "taken", in: context)
                HapticService.play(.success)

            case "SKIP":
                let scheduledTime = response.notification.date
                DoseService.logDose(for: medication, scheduledTime: scheduledTime, status: "skipped", in: context)

            case "SNOOZE_10":
                let scheduledTime = response.notification.date
                DoseService.logDose(for: medication, scheduledTime: scheduledTime, status: "snoozed", in: context)
                // Schedule a new notification after snooze duration
                let snoozeMinutes = AppSettings.shared.defaultSnoozeMinutes
                let snoozeDate = Date().addingTimeInterval(Double(snoozeMinutes) * 60)
                let snoozeId = "snooze-\(medId.uuidString)-\(Int(Date().timeIntervalSince1970))"
                try? await service.scheduleOneShot(
                    id: snoozeId,
                    title: medication.name,
                    body: "\(medication.dosage) — snoozed reminder",
                    at: snoozeDate,
                    medicationId: medId.uuidString,
                    alertStyle: medication.alertStyle
                )

            case UNNotificationDefaultActionIdentifier:
                // User tapped notification itself — app opens, no dose action needed
                break

            default:
                break
            }

            try? context.save()
            SnapshotWriter.writeSnapshot(context: context)
            LiveActivityService.refresh(context: context)
            completionHandler()
        }
    }

    // Show notification even when app is in foreground
    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        var alertStyle = userInfo["alertStyle"] as? String ?? "gentle"

        // Use AdherenceEngine to determine dynamic alert style
        if let medIdString = userInfo["medicationId"] as? String,
           let medId = UUID(uuidString: medIdString) {
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<Medication>(
                predicate: #Predicate { $0.id == medId }
            )
            if let medication = try? context.fetch(descriptor).first {
                let insight = AdherenceEngine.analyze(medication: medication)
                alertStyle = insight.recommendedAlertStyle
            }
        }

        HapticService.playForAlertStyle(alertStyle)

        // Schedule nag reminders if nag mode enabled
        let nagInterval = AppSettings.shared.nagIntervalMinutes
        if nagInterval > 0, userInfo["isNag"] == nil,
           let medId = userInfo["medicationId"] as? String, !medId.isEmpty {
            let service = NotificationService()
            let notifId = notification.request.identifier
            Task {
                try? await service.scheduleNags(
                    baseId: notifId,
                    title: notification.request.content.title,
                    body: "Reminder: \(notification.request.content.body)",
                    startingAfter: 0,
                    intervalMinutes: nagInterval,
                    medicationId: medId,
                    alertStyle: alertStyle
                )
            }
        }

        completionHandler([.banner, .sound, .badge])
    }
}
