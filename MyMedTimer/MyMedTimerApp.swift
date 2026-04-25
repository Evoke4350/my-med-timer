import SwiftUI
import SwiftData
import UserNotifications

@main
struct MyMedTimerApp: App {
    let modelContainer: ModelContainer
    @State private var notificationDelegate: NotificationDelegate

    init() {
        let container = try! ModelContainer(
            for: Medication.self, ScheduleTime.self, DoseLog.self
        )
        self.modelContainer = container
        self._notificationDelegate = State(initialValue: NotificationDelegate(modelContainer: container))

        registerNotificationActions()
    }

    var body: some Scene {
        WindowGroup {
            MedListView()
                .onAppear {
                    UNUserNotificationCenter.current().delegate = notificationDelegate
                    setupQuickActions()
                    SnapshotWriter.writeSnapshot(context: modelContainer.mainContext)
                    LiveActivityService.refresh(context: modelContainer.mainContext)
                }
        }
        .modelContainer(modelContainer)
    }

    @MainActor
    private func setupQuickActions() {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Medication>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\Medication.name)]
        )

        guard let meds = try? context.fetch(descriptor) else { return }

        var actions: [UIApplicationShortcutItem] = [
            UIApplicationShortcutItem(
                type: "addMed",
                localizedTitle: "+ Add Med",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "plus")
            )
        ]

        // Add quick-log for first 2 meds
        for med in meds.prefix(2) {
            actions.append(UIApplicationShortcutItem(
                type: "logMed-\(med.id.uuidString)",
                localizedTitle: "Log \(med.name)",
                localizedSubtitle: med.dosage,
                icon: UIApplicationShortcutIcon(systemImageName: "checkmark.circle")
            ))
        }

        UIApplication.shared.shortcutItems = actions
    }

    private func registerNotificationActions() {
        let takenAction = UNNotificationAction(
            identifier: "TAKEN",
            title: "Taken",
            options: []
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_10",
            title: "Snooze",
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
