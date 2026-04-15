import SwiftUI
import SwiftData
import UserNotifications

@main
struct MyMedTimerApp: App {
    init() {
        registerNotificationActions()
    }

    var body: some Scene {
        WindowGroup {
            MedListView()
        }
        .modelContainer(for: [Medication.self, ScheduleTime.self, DoseLog.self])
    }

    private func registerNotificationActions() {
        let takenAction = UNNotificationAction(
            identifier: "TAKEN",
            title: "Taken",
            options: [.destructive]
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_10",
            title: "Snooze 10min",
            options: []
        )
        let skipAction = UNNotificationAction(
            identifier: "SKIP",
            title: "Skip",
            options: [.destructive]
        )

        let category = UNNotificationCategory(
            identifier: "MEDICATION_REMINDER",
            actions: [takenAction, snoozeAction, skipAction],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
