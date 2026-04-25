import ActivityKit
import Foundation
import SwiftData

@MainActor
enum LiveActivityService {
    private static let startThreshold: TimeInterval = 60 * 60

    static var isEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    static func currentActivity() -> Activity<MedTimerActivityAttributes>? {
        Activity<MedTimerActivityAttributes>.activities.first
    }

    static func refresh(context: ModelContext) {
        guard isEnabled else { return }

        let descriptor = FetchDescriptor<Medication>(
            predicate: #Predicate { $0.isActive }
        )
        guard let meds = try? context.fetch(descriptor) else {
            Task { await endAll() }
            return
        }

        let now = Date()
        let upcoming: (med: Medication, fire: Date)? = meds
            .compactMap { med -> (Medication, Date)? in
                guard !med.isPRN, let next = MedicationService.nextDoseTime(for: med, after: now) else { return nil }
                return (med, next)
            }
            .min(by: { $0.1 < $1.1 })

        guard let next = upcoming, next.fire.timeIntervalSince(now) <= startThreshold else {
            Task { await endAll() }
            return
        }

        let state = MedTimerActivityAttributes.ContentState(
            medName: next.med.name,
            dosage: next.med.dosage,
            colorHex: next.med.colorHex,
            fireDate: next.fire
        )

        if let active = currentActivity() {
            Task { await active.update(ActivityContent(state: state, staleDate: next.fire.addingTimeInterval(60))) }
        } else {
            let attrs = MedTimerActivityAttributes(startDate: now)
            do {
                _ = try Activity.request(
                    attributes: attrs,
                    content: ActivityContent(state: state, staleDate: next.fire.addingTimeInterval(60)),
                    pushType: nil
                )
            } catch {
                // ignore — user may have disabled live activities
            }
        }
    }

    static func endAll() async {
        for activity in Activity<MedTimerActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
