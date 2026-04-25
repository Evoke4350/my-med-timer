import Foundation
import SwiftData
import WidgetKit

@MainActor
enum SnapshotWriter {
    static func writeSnapshot(context: ModelContext) {
        let descriptor = FetchDescriptor<Medication>(
            predicate: #Predicate { $0.isActive }
        )
        guard let meds = try? context.fetch(descriptor) else { return }

        let now = Date()
        let entries: [MedSnapshotEntry] = meds.compactMap { med in
            guard !med.isPRN, let next = MedicationService.nextDoseTime(for: med, after: now) else { return nil }
            return MedSnapshotEntry(
                id: med.id.uuidString,
                name: med.name,
                dosage: med.dosage,
                colorHex: med.colorHex,
                nextDose: next
            )
        }

        let snap = MedSnapshot(generatedAt: now, entries: entries)
        try? snap.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
