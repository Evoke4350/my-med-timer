import SwiftUI
import SwiftData

struct RetroactiveLogSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let medication: Medication

    @State private var pickedTime: Date
    @State private var status: String

    init(medication: Medication, now: Date = Date()) {
        self.medication = medication
        let suggested = MedicationService.mostRecentScheduledDose(for: medication, before: now) ?? now
        _pickedTime = State(initialValue: suggested)
        _status = State(initialValue: "taken")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Form {
                    Section("medication") {
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: medication.colorHex))
                                .frame(width: 6, height: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(medication.name)
                                    .font(.system(.body, design: .monospaced, weight: .semibold))
                                Text(medication.dosage)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Section("when") {
                        DatePicker(
                            "scheduled time",
                            selection: $pickedTime,
                            in: ...Date(),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .font(.system(.body, design: .monospaced))
                        .datePickerStyle(.compact)
                    }

                    Section("status") {
                        Picker("status", selection: $status) {
                            Text("taken").tag("taken")
                            Text("skipped").tag("skipped")
                            Text("snoozed").tag("snoozed")
                        }
                        .pickerStyle(.segmented)
                        .font(.system(.body, design: .monospaced))
                    }

                    Section {
                        Button {
                            log()
                        } label: {
                            Text("log dose")
                                .font(.system(.body, design: .monospaced, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("log at custom time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func log() {
        DoseService.logDose(
            for: medication,
            scheduledTime: pickedTime,
            status: status,
            actualTime: pickedTime,
            in: context
        )
        SnapshotWriter.writeSnapshot(context: context)
        LiveActivityService.refresh(context: context)
        HapticService.play(.success)
        dismiss()
    }
}
